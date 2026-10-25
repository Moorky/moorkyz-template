import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { performance } from "node:perf_hooks";

export function verifyPredictiveSearch() {
  const { normalize, prefixDistance, createPredictor } = createRequire(import.meta.url)("./assets/predictive-search.js");
  const places = ["Karlsruhe", "Kelsterbach", "Kassel", "Kiel", "Köln", "Konstanz", "Kaiserslautern", "Heidelberg", "Mannheim", "Pforzheim", "Stuttgart", "Zürich"];
  const top = (predictor, query, options) => predictor.predict(query, options)[0];

  assert.equal(normalize("  Zürich-Altstadt!  Straße "), "zurich altstadt strasse");
  assert.equal(normalize("ÉCOLE / Œuvre"), "ecole oeuvre");
  assert.equal(prefixDistance("karlsruge", "karlsruhe", 2.4), 0.5, "Adjacent-key substitutions are cheap.");
  assert.equal(prefixDistance("kalrsruhe", "karlsruhe", 2.4), 0.6, "Transpositions are cheap.");

  // Acceptance: KLSE predicts Karlsruhe from the dictionary alone, ahead of a tighter subsequence.
  const cities = createPredictor({ entries: places });
  const klse = top(cities, "KLSE");
  assert.equal(klse.value, "Karlsruhe");
  assert.equal(klse.match, "abbreviation");
  assert.deepEqual(klse.completion, { mode: "replace", text: "Karlsruhe" }, "Non-prefix predictions are shown, never written into the input.");

  const prefix = top(cities, "Karl");
  assert.deepEqual([prefix.value, prefix.match, prefix.completion.mode, prefix.completion.text], ["Karlsruhe", "prefix", "inline", "sruhe"]);
  assert.deepEqual(prefix.marks, [[0, 4]], "Typed characters stay distinguishable from predicted text.");
  for (const typo of ["Karlsruge", "Karlruhe", "Kalrsruhe", "karlsruhee"]) assert.equal(top(cities, typo)?.value, "Karlsruhe", `Typo: ${typo}`);
  assert.equal(top(cities, "stutgart").value, "Stuttgart", "Missing letters are tolerated.");
  assert.equal(top(cities, "zur").value, "Zürich", "Accents are normalized.");
  assert.equal(top(cities, "HDLBG").value, "Heidelberg", "Consonant abbreviations are supported.");
  assert.equal(top(cities, "uhe").value, "Karlsruhe", "Normalized substrings are found.");
  assert.ok(!cities.predict("kar").some((item) => item.value === "Kassel"), "Short queries only tolerate near-key typos.");
  assert.ok(!cities.predict("Karlsruhe").some((item) => item.value === "Karlsruhe"), "An exact value needs no completion.");
  assert.deepEqual(cities.predict(""), []);
  assert.deepEqual(cities.predict("qqqq"), []);

  // Contextual and personalized ranking, plus dictionary aliases.
  const ranked = createPredictor({ entries: [{ value: "Kelsterbach", contexts: ["hessen"] }, { value: "Karlsruhe", contexts: ["baden"] }, "Kassel"] });
  assert.equal(top(ranked, "kls").value, "Kelsterbach");
  assert.equal(top(ranked, "kls", { context: ["baden"] }).value, "Karlsruhe", "Active workspace context reorders predictions.");
  ranked.record("Karlsruhe");
  assert.equal(top(ranked, "kls").value, "Karlsruhe", "Recently used values are prioritized.");
  assert.equal(top(ranked, "k").value, "Karlsruhe");
  assert.deepEqual(ranked.recent(), ["Karlsruhe"]);
  ranked.record("Ettlingen");
  assert.equal(top(ranked, "ettl").value, "Ettlingen", "Confirmed new values become predictable.");
  assert.equal(top(ranked, "ettl").kind, "Recent");
  const alias = createPredictor({ entries: [{ value: "Karlsruhe", kind: "Location", aliases: ["KA", "Fächerstadt"] }, "Kassel"] });
  assert.deepEqual([top(alias, "ka").value, top(alias, "ka").match], ["Karlsruhe", "alias"]);
  assert.equal(top(alias, "facher").value, "Karlsruhe");
  const weighted = createPredictor({ entries: ["Kassel", { value: "Karlsruhe", weight: 50 }], kindBoost: {} });
  assert.equal(top(weighted, "ka").value, "Karlsruhe", "Known names can be weighted.");

  // Multiword phrases, acronyms, filenames and settings-like values.
  const workspace = createPredictor({ entries: ["Midnight blue", "Orbital composition", "Moorkyz Template", "01-aether/landing.html", { value: "Reduced motion", kind: "Setting" }] });
  const phrase = top(workspace, "orbital comp");
  assert.deepEqual([phrase.value, phrase.completion.mode, phrase.completion.text], ["Orbital composition", "inline", "osition"]);
  assert.equal(top(workspace, "midn bl").value, "Midnight blue");
  assert.equal(top(workspace, "midnigth blu").value, "Midnight blue");
  assert.equal(top(workspace, "MT").match, "acronym");
  assert.equal(top(workspace, "aether landing").value, "01-aether/landing.html");
  assert.equal(top(workspace, "landing.htm").value, "01-aether/landing.html");
  assert.equal(top(workspace, "redu").kind, "Setting");
  assert.deepEqual(workspace.suggestExtra("klse", ["Karlsruhe", "Something semantic"]).map((item) => [item.value, item.match]), [["Karlsruhe", "abbreviation"], ["Something semantic", "remote"]], "Optional remote results merge after lexical matches.");

  // Caching and responsiveness on a large local dictionary.
  const before = { ...cities.stats };
  cities.predict("KLSE");
  assert.equal(cities.stats.hits, before.hits + 1, "Repeated queries are cached.");
  const syllables = ["ka", "rl", "sru", "he", "mo", "or", "ky", "zt", "em", "pla", "te", "ber", "gen", "sta", "dt", "wa", "ld"];
  const large = Array.from({ length: 5000 }, (_, i) => {
    let word = "";
    for (let n = i + 7, k = 0; k < 4; k++, n = Math.floor(n / syllables.length) + k * 13) word += syllables[n % syllables.length];
    return `${word[0].toUpperCase()}${word.slice(1)} ${i}`;
  });
  const bulk = createPredictor({ entries: [...large, "Karlsruhe"] });
  const queries = ["k", "ka", "kar", "karl", "KLSE", "mozt", "statd", "bergen wa", "zzzz", "plate"];
  const start = performance.now();
  for (const query of queries) bulk.predict(query);
  const average = (performance.now() - start) / queries.length;
  assert.ok(average < 40, `Uncached prediction over 5,001 entries averaged ${average.toFixed(1)} ms.`);
  const fastStart = performance.now();
  for (const query of ["m", "mo", "moo", "moor"]) bulk.predict(query, { tiers: "fast" });
  const fast = (performance.now() - fastStart) / 4;
  assert.ok(fast < 15, `Immediate prefix prediction averaged ${fast.toFixed(1)} ms.`);
  console.log(`PASS: predictive search: KLSE -> Karlsruhe, prefix/typo/accent/abbreviation/phrase/alias/context/recency ranking and cache; 5,001-entry uncached average ${average.toFixed(1)} ms, fast tier ${fast.toFixed(1)} ms.`);
}
