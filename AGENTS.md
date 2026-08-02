# Repository Agent Notes

## Windows Sandbox Execution

- In this repository, avoid parallel `shell_command` reads through PowerShell on Windows when using the managed sandbox. The sandbox can fail at process startup with `CreateProcessAsUserW failed: 5 (Access is denied)`, which is an executor permission issue rather than a project failure.
- Prefer one `rg` query, one targeted PowerShell command, or sequential file reads for local inspection. If a required command still fails with the same sandbox startup error, retry it once with the normal approval flow instead of treating it as a code or test failure.
- Keep user-facing updates concise: mention the sandbox fallback only when it affects progress or requires approval.

## Local Version Control

- After a cohesive implementation batch has passed its required verification gates, create a local Git commit without waiting for an additional request.
- Stage only files belonging to the verified batch. Preserve unrelated working-tree changes and untracked local tooling files.
- Commit messages must be concise Chinese descriptions. Do not automatically push, create pull requests, or alter remote branches; those actions still require explicit user authorization.
