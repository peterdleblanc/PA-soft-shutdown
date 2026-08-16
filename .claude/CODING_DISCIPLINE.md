# Coding Discipline

> Shared across every project bootstrapped from ClaudeTemplate. Identical fleet-wide,
> so `bootstrap.sh --sync-tooling` refreshes it — do not edit a project's copy. Edit
> `/github/ClaudeTemplate/.claude/CODING_DISCIPLINE.md` and re-sync.
>
> Adapted from [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) (MIT).
> These bias toward caution over speed. On trivial tasks, use judgment.

- **Think before coding.** State assumptions explicitly; if uncertain, ask. Where several readings are possible, present them rather than silently picking one. If a simpler approach exists, say so. If something is unclear, stop and name what is confusing — don't code past it.
- **Simplicity first.** The minimum that solves the problem. No features beyond what was asked, no abstraction for single-use code, no configurability nobody requested, no error handling for impossible cases. If you wrote 200 lines and it could be 50, rewrite it.
- **Surgical changes.** Touch only what you must. Don't "improve" adjacent code, don't refactor what isn't broken, and match the surrounding style even where you'd do it differently. Clean up orphans *your* change created; if you spot unrelated dead code, mention it rather than delete it. The test: every changed line traces to the request.
- **Goal-driven execution.** Make the task verifiable before starting it — "add validation" becomes "write tests for the invalid inputs, then make them pass"; "fix the bug" becomes "write a test that reproduces it, then make it pass". Strong success criteria let you finish without checking in; weak ones ("make it work") guarantee churn.
