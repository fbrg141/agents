# Setting up pi for pi-ask

`scripts/pi-ask` runs [pi](https://github.com/badlogic/pi-mono) in print
mode with read-only tools. This repo ships no pi configuration; set pi up
once as below.

**Privacy:** `pi-ask`, and through it `/to-goal`, `/go`, and `/pi`, send
prompts, specs, diffs, and file contents to the hosted models configured in
pi. The models can also read files under the folder `pi-ask` runs in.

## What pi-ask needs
1. `pi` on your `PATH` (`pi --version`).
2. The `pi-ollama-cloud` package, which provides the `ollama-cloud` provider
   and the `ollama_web_search` / `ollama_web_fetch` tools used by `--web`:
   ```bash
   pi install npm:pi-ollama-cloud
   ```
3. An ollama-cloud account with access to the aliased models: `kimi-k3`,
   `glm-5.3`, `mistral-large-3:675b`, `deepseek-v4.1-flash`, `glm-5.3-flash`.
   `pi --list-models` shows what your account can use.

A minimal `~/.pi/agent/settings.json`:
```json
{
  "defaultProvider": "ollama-cloud",
  "defaultModel": "glm-5.3",
  "packages": ["npm:pi-ollama-cloud"]
}
```

## Changing models
Built-in aliases and role presets are in `scripts/pi-ask.models.json`.
To change them without editing the repo, create
`${XDG_CONFIG_HOME:-$HOME/.config}/pi-ask/models.json`. Top-level values
(`provider`, `default`) replace the built-in ones; each entry under
`aliases` and `roles` is merged field by field over the built-in entry of
the same name. Example: make kimi the default, add a `gemma` alias, and use
add it to reviews:
```json
{
  "default": "kimi",
  "aliases": { "gemma": { "model": "gemma4:31b", "thinking": "medium" } },
  "roles": { "review": { "models": ["kimi", "glm", "gemma"] } }
}
```
`"thinking": null` marks a model without thinking support; `--thinking` is
then ignored for it. Full model ids (`--models gpt-oss:120b`) work without
an alias and are checked against `pi --list-models`.

## Verify
```bash
scripts/pi-ask "Reply with exactly: OK"
scripts/pi-ask --models kimi,glm,mistral "Reply with exactly: OK"
```
Each model should answer `OK` under its own `## <alias> (<model id>)`
heading. `scripts/check.sh --live` runs the full set of live checks.

Note: `pi auth check` can report ollama-cloud models as invalid even when
they work. Trust a real call like the one above instead.
