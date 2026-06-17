# Project Agents

Reusable Codex sub-agent instructions for Cat Break Timer live here.

## Files

- `senior-developer-agent.md`: technical lead, code review, implementation, architecture, testing, and risk analysis.
- `ux-ui-designer-agent.md`: minimal, cute, clean, friendly UX/UI review and design guidance.
- `tech-lead-orchestrator-agent.md`: task decomposition, agent delegation, output review, and final planning.

## How to Use in Codex

Reference the agent file when starting a Codex task or sub-agent:

```text
Use .agents/senior-developer-agent.md to review this change for maintainability and test coverage.
```

```text
Use .agents/ux-ui-designer-agent.md to improve the timer UI while keeping it minimal and cute.
```

```text
Use .agents/tech-lead-orchestrator-agent.md to decompose this feature and assign work to the project agents.
```

For best results, pair the agent with a concrete target file, feature, or question.
