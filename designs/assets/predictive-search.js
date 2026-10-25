"use strict";
// Local-first predictive autocomplete: a ranking engine (usable in Node for tests)
// and an accessible combobox controller with inline ghost text.
((root, factory) => {
  const api = factory();
  if (typeof module === "object" && module && module.exports) module.exports = api;
  else root.MoorkyzPredictiveSearch = api;
})(globalThis, () => {
  const FOLD = { "ß": "ss", "æ": "ae", "œ": "oe", "ø": "o", "ł": "l", "đ": "d", "ð": "d", "þ": "th", "ı": "i" };
  const MARKS = /[\u0300-\u036f]/g;
  const WORD = /[\p{L}\p{N}]/u;
  const TIERS = { exact: 1000, alias: 940, prefix: 900, word: 820, phrase: 800, acronym: 760, fuzzy: 700, contains: 560, abbreviation: 520, remote: 300 };

  function fold(raw) {
    const chars = [];
    const starts = [];
    const ends = [];
    let index = 0;
    let space = true;
    for (const char of String(raw ?? "")) {
      const lower = char.toLowerCase();
      const folded = FOLD[lower] ?? lower.normalize("NFKD").replace(MARKS, "");
      for (const out of folded) {
        if (WORD.test(out)) {
          chars.push(out);
          space = false;
        } else if (!space) {
          chars.push(" ");
          space = true;
        } else continue;
        starts.push(index);
        ends.push(index + char.length);
      }
      index += char.length;
    }
    if (chars.at(-1) === " ") {
      chars.pop();
      starts.pop();
      ends.pop();
    }
    return { text: chars.join(""), starts, ends };
  }

  const normalize = (value) => fold(value).text;

  const NEAR = new Map();
  function link(a, b) {
    if (!a || !b) return;
    for (const [from, to] of [[a, b], [b, a]]) {
      if (!NEAR.has(from)) NEAR.set(from, new Set());
      NEAR.get(from).add(to);
    }
  }
  const ROWS = ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"];
  ROWS.forEach((row, r) => [...row].forEach((char, i) => {
    link(char, row[i + 1]);
    if (ROWS[r + 1]) {
      link(char, ROWS[r + 1][i]);
      link(char, ROWS[r + 1][i - 1]);
    }
  }));
  link("y", "z");

  const substitution = (a, b) => (a === b ? 0 : NEAR.get(a)?.has(b) ? 0.5 : 1);
  const allowance = (length) => (length < 3 ? 0 : length < 5 ? 0.8 : length < 8 ? 1.6 : 2.4);

  // Weighted optimal-string-alignment distance between the query and the closest
  // prefix of the target: adjacent keys, transpositions, doubled and missing letters are cheap.
  function prefixDistance(query, target, limit) {
    const m = query.length;
    const n = Math.min(target.length, m + Math.ceil(limit / 0.8) + 1);
    let before = null;
    let previous = Array.from({ length: n + 1 }, (_, j) => j * 0.8);
    for (let i = 1; i <= m; i++) {
      const current = new Array(n + 1);
      current[0] = i;
      let best = current[0];
      const q = query[i - 1];
      for (let j = 1; j <= n; j++) {
        const t = target[j - 1];
        const extra = i > 1 && q === query[i - 2] ? 0.4 : 1;
        let cost = Math.min(previous[j] + extra, current[j - 1] + 0.8, previous[j - 1] + substitution(q, t));
        if (before && j > 1 && q === target[j - 2] && query[i - 2] === t) cost = Math.min(cost, before[j - 2] + 0.6);
        current[j] = cost;
        if (cost < best) best = cost;
      }
      if (best > limit) return Infinity;
      before = previous;
      previous = current;
    }
    return Math.min(...previous);
  }

  function prepare(input) {
    const item = typeof input === "string" ? { value: input } : input ?? {};
    const value = String(item.value ?? "").trim();
    const folded = fold(value);
    if (!folded.text) return null;
    const words = [];
    const pattern = /\S+/g;
    for (let match; (match = pattern.exec(folded.text));) words.push({ text: match[0], start: match.index });
    const compactIndex = [];
    for (let i = 0; i < folded.text.length; i++) if (folded.text[i] !== " ") compactIndex.push(i);
    return {
      value,
      key: folded.text,
      kind: item.kind ? String(item.kind) : "",
      weight: Number(item.weight) || 0,
      contexts: new Set(item.contexts ?? []),
      aliases: new Set((item.aliases ?? []).map(normalize).filter(Boolean)),
      folded,
      words,
      initials: words.map((word) => word.text[0]).join(""),
      compact: folded.text.replaceAll(" ", ""),
      compactIndex,
      wordStarts: new Set(words.map((word) => word.start)),
    };
  }

  function abbreviation(query, entry) {
    const q = query.replaceAll(" ", "");
    const text = entry.compact;
    if (q.length < 2 || q.length >= text.length) return null;
    const startWord = entry.words.find((word) => word.text[0] === q[0]);
    if (!startWord) return null;
    const positions = [entry.compactIndex.indexOf(startWord.start)];
    for (let i = 1; i < q.length; i++) {
      const from = positions[i - 1] + 1;
      const found = i === q.length - 1 ? text.lastIndexOf(q[i]) : text.indexOf(q[i], from);
      if (found < from) return null;
      positions.push(found);
    }
    const normalized = positions.map((position) => entry.compactIndex[position]);
    const wordHits = normalized.filter((position) => entry.wordStarts.has(position)).length / q.length;
    const last = normalized.at(-1);
    const endHit = last === entry.key.length - 1 || entry.key[last + 1] === " " ? 1 : 0;
    const quality = 0.3 * (startWord.start === 0 ? 1 : 0.5) + 0.25 * wordHits + 0.25 * endHit + 0.2 * Math.min(1, (2 * q.length) / text.length);
    return { score: TIERS.abbreviation + quality * 150, marks: normalized.map((position) => [position, position + 1]) };
  }

  function phrase(tokens, entry, fuzzy) {
    let next = 0;
    let penalty = 0;
    const marks = [];
    for (const token of tokens) {
      let found = -1;
      for (let w = next; w < entry.words.length && found < 0; w++) {
        const word = entry.words[w].text;
        if (word.startsWith(token)) found = w;
        else if (fuzzy && token.length >= 3) {
          const distance = prefixDistance(token, word, allowance(token.length));
          if (Number.isFinite(distance)) {
            found = w;
            penalty += distance * 60;
          }
        }
        if (found < 0) penalty += 10;
      }
      if (found < 0) return null;
      const start = entry.words[found].start;
      marks.push([start, start + Math.min(token.length, entry.words[found].text.length)]);
      next = found + 1;
    }
    return { score: TIERS.phrase - penalty, marks };
  }

  function match(query, tokens, entry, full) {
    const key = entry.key;
    if (key === query) return null;
    if (entry.aliases.has(query)) return { score: TIERS.alias, match: "alias", marks: [] };
    if (key.startsWith(query)) return { score: TIERS.prefix + (50 * query.length) / key.length, match: "prefix", marks: [[0, query.length]] };
    for (const alias of entry.aliases) {
      if (alias.startsWith(query) && query.length >= 2) return { score: TIERS.alias - 60, match: "alias", marks: [] };
    }
    if (tokens.length === 1) {
      const index = entry.words.findIndex((word, i) => i > 0 && word.text.startsWith(query));
      if (index > 0) {
        const start = entry.words[index].start;
        return { score: TIERS.word - 5 * index, match: "word", marks: [[start, start + query.length]] };
      }
    } else {
      const result = phrase(tokens, entry, false);
      if (result) return { ...result, match: "phrase" };
    }
    const compactQuery = tokens.join("");
    if (compactQuery.length >= 2 && entry.words.length >= 2 && entry.initials.startsWith(compactQuery)) {
      return { score: TIERS.acronym, match: "acronym", marks: entry.words.slice(0, compactQuery.length).map((word) => [word.start, word.start + 1]) };
    }
    if (!full) return null;
    let best = null;
    const limit = allowance(query.length);
    if (limit > 0) {
      for (const word of entry.words) {
        const distance = prefixDistance(query, key.slice(word.start), limit);
        const score = TIERS.fuzzy - distance * 80 - (word.start ? 15 : 0);
        if (Number.isFinite(distance) && (!best || score > best.score)) best = { score, match: "fuzzy", marks: [] };
      }
    }
    if (tokens.length > 1) {
      const result = phrase(tokens, entry, true);
      if (result && (!best || result.score > best.score)) best = { ...result, match: "phrase" };
    }
    if (best) return best;
    const index = query.length >= 3 ? key.indexOf(query) : -1;
    if (index > 0) return { score: TIERS.contains, match: "contains", marks: [[index, index + query.length]] };
    const result = abbreviation(query, entry);
    return result && { ...result, match: "abbreviation" };
  }

  function rawMarks(entry, marks) {
    const ranges = marks
      .filter(([start, end]) => end > start)
      .map(([start, end]) => [entry.folded.starts[start], entry.folded.ends[end - 1]])
      .sort((a, b) => a[0] - b[0]);
    const merged = [];
    for (const range of ranges) {
      const last = merged.at(-1);
      if (last && range[0] <= last[1]) last[1] = Math.max(last[1], range[1]);
      else merged.push([...range]);
    }
    return merged;
  }

  function completion(raw, value) {
    if (raw && value.length > raw.length && value.slice(0, raw.length).toLowerCase() === raw.toLowerCase()) {
      return { mode: "inline", text: value.slice(raw.length) };
    }
    return { mode: "replace", text: value };
  }

  function createPredictor(options = {}) {
    const settings = { limit: 6, recentLimit: 20, cacheSize: 200, kindBoost: {}, ...options };
    const entries = new Map();
    const recents = [];
    const cache = new Map();
    const stats = { hits: 0, misses: 0 };
    let version = 0;

    function invalidate() {
      version++;
      cache.clear();
    }
    function add(input) {
      const entry = prepare(input);
      if (!entry) return null;
      const existing = entries.get(entry.key);
      if (!existing) {
        entries.set(entry.key, entry);
        return entry;
      }
      existing.weight = Math.max(existing.weight, entry.weight);
      for (const context of entry.contexts) existing.contexts.add(context);
      for (const alias of entry.aliases) existing.aliases.add(alias);
      if (!existing.kind || existing.kind === "Recent") existing.kind = entry.kind;
      return existing;
    }
    function setEntries(list) {
      entries.clear();
      for (const item of list ?? []) add(item);
      for (const recent of recents) if (!entries.has(recent.key)) add({ value: recent.value, kind: "Recent" });
      invalidate();
    }
    function boost(entry, context) {
      let total = entry.weight + (settings.kindBoost[entry.kind] ?? 0);
      let shared = 0;
      for (const item of context) if (entry.contexts.has(item)) shared++;
      total += Math.min(90, shared * 60);
      const rank = recents.findIndex((recent) => recent.key === entry.key);
      if (rank >= 0) total += Math.max(20, 140 - rank * 12) + Math.min(60, recents[rank].count * 15);
      return total;
    }
    function rank(raw, list, { context = [], limit = settings.limit, full = true } = {}) {
      const query = normalize(raw);
      if (!query) return [];
      const tokens = query.split(" ");
      const scored = [];
      for (const entry of list) {
        const result = match(query, tokens, entry, full);
        if (result) scored.push({ entry, score: result.score + boost(entry, context), match: result.match, marks: result.marks });
      }
      scored.sort((a, b) => b.score - a.score || a.entry.value.length - b.entry.value.length || a.entry.value.localeCompare(b.entry.value));
      return scored.slice(0, limit);
    }
    function present(raw, ranked) {
      return ranked.map(({ entry, score, match: kind, marks }) => ({
        value: entry.value,
        kind: entry.kind,
        score: Math.round(score * 10) / 10,
        match: kind,
        marks: rawMarks(entry, marks),
        completion: completion(raw, entry.value),
      }));
    }
    function predict(raw, options = {}) {
      const context = [...(options.context ?? [])].filter(Boolean);
      const full = options.tiers !== "fast";
      const limit = options.limit ?? settings.limit;
      const key = `${version}\u0000${full}\u0000${limit}\u0000${context.join("\u0001")}\u0000${normalize(raw)}`;
      let ranked = cache.get(key);
      if (ranked) {
        stats.hits++;
        cache.delete(key);
      } else {
        stats.misses++;
        ranked = rank(raw, entries.values(), { context, limit, full });
        if (cache.size >= settings.cacheSize) cache.delete(cache.keys().next().value);
      }
      cache.set(key, ranked);
      return present(raw, ranked);
    }
    function suggestExtra(raw, list, options = {}) {
      const prepared = (list ?? []).map(prepare).filter(Boolean);
      const ranked = rank(raw, prepared, { context: options.context ?? [], limit: options.limit ?? settings.limit, full: true });
      const matched = new Set(ranked.map((item) => item.entry.key));
      for (const entry of prepared) {
        if (!matched.has(entry.key) && entry.key !== normalize(raw)) ranked.push({ entry, score: TIERS.remote, match: "remote", marks: [] });
      }
      return present(raw, ranked.slice(0, options.limit ?? settings.limit));
    }
    function record(raw) {
      const key = normalize(raw);
      if (!key) return;
      const entry = entries.get(key) ?? add({ value: String(raw).trim(), kind: "Recent" });
      const index = recents.findIndex((recent) => recent.key === key);
      const count = index >= 0 ? recents.splice(index, 1)[0].count + 1 : 1;
      recents.unshift({ key, value: entry.value, count });
      recents.length = Math.min(recents.length, settings.recentLimit);
      invalidate();
    }

    setEntries(settings.entries);
    return {
      predict,
      suggestExtra,
      record,
      setEntries,
      add(item) {
        add(item);
        invalidate();
      },
      recent: () => recents.map((item) => item.value),
      get size() {
        return entries.size;
      },
      stats,
    };
  }

  let instances = 0;
  function attach(input, predictor, options = {}) {
    const doc = input.ownerDocument;
    const view = doc.defaultView;
    const settings = { label: "Suggestions", limit: 6, syncLimit: 1500, fullDelay: 60, remote: null, remoteDelay: 250, context: () => [], onAccept() {}, onCommit() {}, ...options };
    const uid = `${input.id || "predictive"}-${++instances}`;
    const make = (tag, className, text) => {
      const node = doc.createElement(tag);
      node.className = className;
      if (text) node.textContent = text;
      return node;
    };
    const field = make("div", "predictive-field");
    const ghost = make("div", "predictive-ghost");
    const track = make("span", "predictive-ghost-track");
    const typed = make("span", "predictive-typed");
    const suffix = make("span", "predictive-suffix");
    const list = make("ul", "predictive-list");
    const hint = make("span", "predictive-hint", "Suggestions appear as you type. Tab or Right Arrow accepts the inline suggestion, Up and Down Arrow browse alternatives, Enter confirms and Escape dismisses.");
    const status = make("span", "predictive-status");
    ghost.setAttribute("aria-hidden", "true");
    track.append(typed, suffix);
    ghost.append(track);
    list.id = `${uid}-list`;
    list.hidden = true;
    list.setAttribute("role", "listbox");
    list.setAttribute("aria-label", settings.label);
    hint.id = `${uid}-hint`;
    hint.hidden = true;
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    Object.assign(status.style, { position: "absolute", width: "1px", height: "1px", overflow: "hidden", clipPath: "inset(50%)", whiteSpace: "nowrap" });
    input.before(field);
    field.append(input, ghost, list, hint, status);
    input.setAttribute("role", "combobox");
    input.setAttribute("aria-autocomplete", "both");
    input.setAttribute("aria-expanded", "false");
    input.setAttribute("aria-controls", list.id);
    input.setAttribute("aria-describedby", [input.getAttribute("aria-describedby"), hint.id].filter(Boolean).join(" "));
    input.setAttribute("autocomplete", "off");
    input.setAttribute("spellcheck", "false");

    let suggestions = [];
    let highlight = -1;
    let open = false;
    let focused = doc.activeElement === input;
    let composing = false;
    let dismissed = false;
    let accepting = false;
    let fullTimer = 0;
    let remoteTimer = 0;
    let statusTimer = 0;
    let remoteController = null;
    let announced = "";

    function syncMetrics() {
      const style = view.getComputedStyle(input);
      for (const property of ["fontFamily", "fontSize", "fontWeight", "fontStyle", "letterSpacing", "wordSpacing", "textTransform", "lineHeight"]) ghost.style[property] = style[property];
      const side = (name) => `${parseFloat(style[`padding${name}`]) + parseFloat(style[`border${name}Width`])}px`;
      ghost.style.padding = `${side("Top")} ${side("Right")} ${side("Bottom")} ${side("Left")}`;
    }
    const caretAtEnd = () => input.selectionStart === input.value.length && input.selectionEnd === input.value.length;
    const active = () => suggestions[highlight >= 0 ? highlight : 0] ?? null;

    function renderGhost() {
      const suggestion = active();
      const visible = Boolean(suggestion && focused && !composing && !dismissed && caretAtEnd());
      typed.textContent = input.value;
      suffix.textContent = !visible ? "" : suggestion.completion.mode === "inline" ? suggestion.completion.text : `  \u2192 ${suggestion.value}`;
      field.classList.toggle("has-prediction", visible);
      field.classList.toggle("is-replacement", visible && suggestion.completion.mode !== "inline");
      track.style.transform = input.scrollLeft ? `translateX(${-input.scrollLeft}px)` : "";
    }
    function renderList() {
      const show = open && focused && !dismissed && suggestions.length > 0;
      list.replaceChildren(...suggestions.map((suggestion, index) => {
        const option = make("li", "predictive-option");
        option.id = `${uid}-option-${index}`;
        option.setAttribute("role", "option");
        option.setAttribute("aria-selected", String(index === highlight));
        const label = make("span", "predictive-option-value");
        let cursor = 0;
        for (const [start, end] of suggestion.marks) {
          if (start > cursor) label.append(suggestion.value.slice(cursor, start));
          label.append(make("mark", "", suggestion.value.slice(start, end)));
          cursor = end;
        }
        if (cursor < suggestion.value.length) label.append(suggestion.value.slice(cursor));
        option.append(label);
        if (suggestion.kind) option.append(make("span", "predictive-option-kind", suggestion.kind));
        if (suggestion === active()) {
          const key = make("kbd", "predictive-option-key", highlight >= 0 ? "Enter" : "Tab");
          key.setAttribute("aria-hidden", "true");
          option.append(key);
        }
        option.addEventListener("pointerdown", (event) => event.preventDefault());
        option.addEventListener("click", () => accept(suggestion));
        return option;
      }));
      if (show && list.hidden) {
        list.hidden = false;
        void list.offsetWidth;
        list.classList.add("is-open");
      } else if (!show) {
        list.hidden = true;
        list.classList.remove("is-open");
      }
      input.setAttribute("aria-expanded", String(show));
      if (show && highlight >= 0) {
        input.setAttribute("aria-activedescendant", `${uid}-option-${highlight}`);
        list.children[highlight]?.scrollIntoView?.({ block: "nearest" });
      } else input.removeAttribute("aria-activedescendant");
    }
    function announce(message) {
      view.clearTimeout(statusTimer);
      statusTimer = view.setTimeout(() => {
        if (message === announced) return;
        announced = message;
        status.textContent = message;
      }, 450);
    }
    function render() {
      renderGhost();
      renderList();
      const suggestion = active();
      if (!suggestion || dismissed || !focused) return announce("");
      const more = suggestions.length - 1;
      announce(`${suggestion.value}${suggestion.kind ? `, ${suggestion.kind}` : ""} suggested.${more ? ` ${more} more.` : ""}`);
    }
    function show(next) {
      const current = highlight >= 0 ? suggestions[highlight]?.value : null;
      suggestions = next;
      highlight = current ? suggestions.findIndex((item) => item.value === current) : -1;
      open = suggestions.length > 1 || (open && suggestions.length > 0);
      render();
    }
    function context() {
      try {
        return settings.context() ?? [];
      } catch {
        return [];
      }
    }
    function update() {
      view.clearTimeout(fullTimer);
      const query = input.value;
      highlight = -1;
      if (!normalize(query) || composing) {
        suggestions = [];
        open = false;
        render();
        return;
      }
      const large = predictor.size > settings.syncLimit;
      show(predictor.predict(query, { context: context(), limit: settings.limit, tiers: large ? "fast" : "full" }));
      if (large) {
        fullTimer = view.setTimeout(() => {
          if (input.value === query) show(predictor.predict(query, { context: context(), limit: settings.limit }));
        }, settings.fullDelay);
      }
      requestRemote(query);
    }
    function requestRemote(query) {
      view.clearTimeout(remoteTimer);
      remoteController?.abort();
      if (typeof settings.remote !== "function" || normalize(query).length < 2) return;
      remoteTimer = view.setTimeout(async () => {
        const controller = new AbortController();
        remoteController = controller;
        try {
          const extra = await settings.remote(query, { signal: controller.signal, context: context() });
          if (controller.signal.aborted || input.value !== query || dismissed) return;
          const known = new Set(suggestions.map((item) => normalize(item.value)));
          const merged = predictor.suggestExtra(query, extra, { context: context(), limit: settings.limit }).filter((item) => !known.has(normalize(item.value)));
          if (merged.length) show([...suggestions, ...merged].slice(0, settings.limit));
        } catch {
          // Optional remote suggestions never block local prediction.
        }
      }, settings.remoteDelay);
    }
    function close() {
      open = false;
      highlight = -1;
      render();
    }
    function accept(suggestion) {
      if (!suggestion) return;
      input.value = suggestion.value;
      input.setSelectionRange(input.value.length, input.value.length);
      predictor.record(suggestion.value);
      suggestions = [];
      dismissed = true;
      close();
      accepting = true;
      try {
        input.dispatchEvent(new view.Event("input", { bubbles: true }));
      } finally {
        accepting = false;
      }
      announced = "";
      announce(`${suggestion.value} accepted.`);
      settings.onAccept(suggestion);
    }
    function move(step) {
      if (!suggestions.length) return;
      open = true;
      highlight = highlight + step;
      if (highlight >= suggestions.length) highlight = 0;
      if (highlight < -1) highlight = suggestions.length - 1;
      render();
    }

    input.addEventListener("input", () => {
      if (accepting) return;
      dismissed = false;
      update();
    });
    input.addEventListener("keydown", (event) => {
      if (event.isComposing || composing || event.altKey || event.ctrlKey || event.metaKey) return;
      const suggestion = active();
      const ready = suggestion && !dismissed && caretAtEnd();
      if ((event.key === "Tab" && !event.shiftKey) || event.key === "ArrowRight") {
        if (ready) {
          event.preventDefault();
          accept(suggestion);
        }
      } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        if (dismissed && normalize(input.value)) {
          dismissed = false;
          update();
        }
        if (suggestions.length) {
          event.preventDefault();
          move(event.key === "ArrowDown" ? 1 : -1);
        }
      } else if (event.key === "Enter") {
        if (open && highlight >= 0 && suggestions[highlight]) {
          event.preventDefault();
          accept(suggestions[highlight]);
        } else if (normalize(input.value)) {
          settings.onCommit(input.value);
          dismissed = true;
          close();
        }
      } else if (event.key === "Escape" && suggestions.length && !dismissed) {
        event.preventDefault();
        dismissed = true;
        close();
      }
    });
    for (const type of ["keyup", "click", "select", "scroll"]) input.addEventListener(type, renderGhost);
    input.addEventListener("compositionstart", () => {
      composing = true;
      renderGhost();
    });
    input.addEventListener("compositionend", () => {
      composing = false;
      update();
    });
    input.addEventListener("focus", () => {
      focused = true;
      syncMetrics();
      if (!dismissed) update();
    });
    input.addEventListener("blur", () => {
      focused = false;
      open = false;
      highlight = -1;
      render();
    });
    view.addEventListener("resize", syncMetrics);
    syncMetrics();

    return {
      field,
      refresh() {
        if (focused && !dismissed) update();
      },
      dismiss() {
        dismissed = true;
        close();
      },
      get suggestions() {
        return suggestions.slice();
      },
    };
  }

  return { normalize, prefixDistance, createPredictor, attach };
});
