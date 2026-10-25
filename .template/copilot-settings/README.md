# Moorkyz Copilot Settings

Portable PowerShell setup for **VS Code + GitHub Copilot**. A single command configures user and/or workspace settings with a reusable JSON config.

## When to use

Use this tool when a task needs reviewed VS Code/Copilot settings or a starting
agent guide. Consult the [template-tool catalog](../README.md) and preview with `-WhatIf`
before applying changes. Always specify the intended `-ProjectPath` if it is not
your shell's current directory; the script does not infer it from its location.

## Quick start (Windows)

From the repository root, open PowerShell and run:

```powershell
Set-Location .\.template\copilot-settings
.\Setup-CopilotProject.ps1 -ProjectPath "C:\path\to\your-repo"
```

Run the commands below from this directory. To reuse the setup elsewhere, copy
the entire directory, including [AGENTS.template.md](helpers/AGENTS.template.md), beside
the script. Configuration, the agent template and the BYOK example are supporting
files under `helpers/`; keep that subfolder when copying the tool.

If the PowerShell execution policy blocks local scripts, inspect the script before changing execution policy. A process-scoped workaround is `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Setup-CopilotProject.ps1 -ProjectPath "C:\path\to\your-repo"`.

**Defaults:** `-Scope Both` configures `%APPDATA%\Code\User\settings.json` and `<repo>\.vscode\settings.json`. It creates `<repo>\AGENTS.md` only if absent. No MCP server is installed until one is added to `copilot-config.json`.

## Commands

```powershell
# Current folder as project
.\Setup-CopilotProject.ps1

# Only the project's settings and AGENTS.md
.\Setup-CopilotProject.ps1 -ProjectPath "C:\Code\app" -Scope Project

# Only global settings
.\Setup-CopilotProject.ps1 -Scope Global

# Preview changes, write nothing
.\Setup-CopilotProject.ps1 -ProjectPath "C:\Code\app" -WhatIf

# Check the entrypoint only: no config/settings reads, writes or prompts
.\Setup-CopilotProject.ps1 -DryRun

# Automation: show the result and exit without waiting for a key
.\Setup-CopilotProject.ps1 -ProjectPath "C:\Code\app" -NoPause

# VS Code Insiders
.\Setup-CopilotProject.ps1 -ProjectPath "C:\Code\app" -VSCode Insiders

# Alternative config file
.\Setup-CopilotProject.ps1 -ProjectPath "C:\Code\app" -ConfigPath .\my-config.json
```

## Edit your configuration

Open [helpers/copilot-config.json](helpers/copilot-config.json).

- `globalSettings`: controls your personal VS Code profile, such as Copilot, notifications, default model, and autonomy features.
- `projectSettings`: overrides settings within each repository, including agent request limit and conversation compaction.
- `sandbox`: `auto` (default), `on`, or `off`. Auto activates only for known, verified Windows sandbox baselines (Windows 11 25H2 build 26200.9550+ or 26H1 build 28000.3086+). Other cases stay off; always validate with `/sandbox policy`. Windows sandbox support is experimental.
- `createAgentsMd`: when `true`, adds `AGENTS.md` from the included template if no file exists.
- `mcpServers`: empty by default. Add specific, reviewed MCP servers to merge them into `.vscode/mcp.json`.

**Optional MCP server example** (requires a compatible Node.js installation; invoking may download third-party code):

```json
"mcpServers": {
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
}
```

Do not put credentials into tracked project config. Enabling `chat.mcp.access` permits MCP; it does not automatically install servers or authorize accounts.

## Agent instructions

[AGENTS.template.md](helpers/AGENTS.template.md) is a portable, stack-neutral starting
point for repositories without an agent guide. Fill in its project-specific
context with the actual architecture, verification commands and quality gates.
It includes instruction precedence, honest evidence, secret protection and
focused-change rules without assuming Moorkyz scripts or a scheduler. Its work
steps are Analyzing and Reading, Researching and Planning, Developing, then
Clean Up: tests, quality/safety review, final reference checks, documentation
updates and rechecks, evidence/audit, and an authorized focused commit.
Passing checks do not imply human approval.

This repository uses the more detailed [root guide](../../AGENTS.md). Existing
project guides are preserved, not replaced or merged by setup. Apply any desired
template improvements manually after reviewing the project's own instructions.

## Important behavior

- **Result:** ends with `ALL SET` only when every requested configuration step succeeds (including unchanged/preserved files). Otherwise it prints `FAILED` and a list naming each failed step and its error; independent steps still run and successful changes are kept for a safe rerun. Invalid inputs stop before any writes. `-WhatIf` reports `PREVIEW ONLY`, never success; declined changes report `INCOMPLETE`.
- **Visible completion:** prints **Press any key to exit...** after success, preview or failure so a right-click launch stays visible. Use `-NoPause` for automation; redirected input never waits. Exit code `0` means configuration completed or a valid preview/dry run finished; `1` means failures, declined changes or a console-input error.
- **Configuration, not service health:** `ALL SET` confirms the requested local configuration steps, not installed extensions, Copilot sign-in, model access or effective sandbox protection. Restart the Copilot session and verify those separately.
- **Non-destructive:** merges keys, preserving unrelated settings; existing `AGENTS.md` is never overwritten. Modified JSON files receive timestamped `.bak.*` copies.
- **JSONC:** accepts VS Code `settings.json` with line/block comments and trailing commas. Because settings files are regenerated, their comments/formatting are not preserved (backups contain the originals). Review diffs before committing workspace settings.
- **Idempotent:** rerunning unchanged settings does not create another backup.
- **Autonomy:** settings enable supported agent features. Starting a task and choosing *Autopilot* are separate actions. Scheduled automations must also be created in VS Code; `chat.automations.enabled` only shows the feature.
- **Safety:** `chat.permissions.default` stays `default` and `chat.tools.global.autoApprove` is `false`. Autopilot uses its own approval semantics and may auto-approve destructive commands; use isolated Git worktrees, especially on important projects. Terminal auto-approval deny patterns are **not** a security boundary.
- **Sandbox:** requires supported OS features; it is not a VM. In `auto` mode, unsupported/unknown Windows builds get `off` rather than a broken configuration. Set `on` explicitly only after verifying support.
- **Model:** `chat.defaultModel: "opus"` is a model-family preference, **not** a guaranteed exact release. You must have an available matching model; otherwise use `"auto"`.
- **Token limits:** managed Copilot model max-output tokens cannot be overridden by this tool. A ready-to-edit `chatLanguageModels.example.json` shows BYOK model limits (`maxInputTokens`, `maxOutputTokens`). Configure your endpoint via `Chat: Manage Language Models` and transfer the applicable values into its managed `chatLanguageModels.json`; limits are constrained by provider and model. This tool does not install credentials or overwrite provider configuration.
- **Platform:** the script targets Windows PowerShell 5.1+ and standard VS Code or VS Code Insiders user profiles.

## Files written

| Destination | Trigger |
|---|---|
| `%APPDATA%\Code\User\settings.json` | `-Scope Both` or `-Scope Global` |
| `<repo>\.vscode\settings.json` | `-Scope Both` or `-Scope Project` |
| `<repo>\AGENTS.md` | Project scope + `createAgentsMd: true`, only if missing |
| `<repo>\.vscode\mcp.json` | Project scope + non-empty `mcpServers` |

## Documentation

- [VS Code AI settings](https://code.visualstudio.com/docs/agents/reference/ai-settings)
- [MCP configuration](https://code.visualstudio.com/docs/agents/reference/mcp-configuration)
- [Sandboxing requirements](https://code.visualstudio.com/docs/agents/run/agent-sandboxing)
- [Language models and BYOK](https://code.visualstudio.com/docs/agent-customization/language-models)
