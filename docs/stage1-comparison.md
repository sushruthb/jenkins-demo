# Jenkins Pipeline Types — Stage 1 Reference

## Freestyle Jobs

- Configured entirely through the Jenkins UI (no code)
- Each setting (shell command, trigger, artifact) is a UI field
- Job configuration is stored in Jenkins internals — not in your repo
- Cannot be version controlled, reviewed, or reused easily
- Good for: quick one-off experiments, learning the Jenkins UI
- Bad for: anything you want to maintain, share, or repeat reliably

## Scripted Pipeline

- Defined in Groovy code using `node { stage('Name') { ... } }` blocks
- Highly flexible — full Groovy language available
- No enforced structure — easy to write hard-to-read spaghetti code
- No built-in `post` block; must use try/catch/finally manually
- Stored in a file (e.g., `scripted-pipeline.groovy`) and version controlled
- See `scripted-pipeline.groovy` in this repo for a working example

## Declarative Pipeline

- Defined in a `Jenkinsfile` using a structured DSL (`pipeline { ... }`)
- Enforced structure: `agent`, `stages`, `stage`, `steps`, `post`
- Easier to read, lint, and share across teams
- Built-in `post` block handles success/failure/always cleanly
- The modern standard — use this unless you need Scripted flexibility
- See `Jenkinsfile` in this repo for a working example

## When to Use Which

| | Freestyle | Scripted | Declarative |
|---|---|---|---|
| Defined in code | No | Yes | Yes |
| Easy to read | Yes (UI) | No | Yes |
| Version controlled | No | Yes | Yes |
| Built-in post actions | No | No (manual) | Yes |
| Recommended for beginners | UI exploration only | No | Yes |

## Key Declarative Pipeline Blocks

| Block | Purpose |
|---|---|
| `agent any` | Run on any available Jenkins node |
| `stages` | Container for all stage blocks |
| `stage('Name')` | A named step in the pipeline (shown in UI) |
| `steps` | The actual commands inside a stage |
| `sh 'command'` | Run a shell command |
| `echo 'message'` | Print a message to the console log |
| `post { success }` | Run only if all stages passed |
| `post { failure }` | Run only if any stage failed |
| `post { always }` | Run regardless of outcome |
