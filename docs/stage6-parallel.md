# Jenkins Stage 6 — Parallel Stages Reference

## parallel {} at the stage level

Wraps multiple `stage()` blocks so they run concurrently. The parent stage acts as a container — it has no `steps {}` of its own.

```groovy
stage('Verify') {
    parallel {
        stage('Unit Tests') {
            steps { sh 'bash test.sh' }
        }
        stage('Lint') {
            steps { sh 'bash lint.sh' }
        }
        stage('Security Scan') {
            steps { sh './scan.sh' }
        }
    }
}
```

Jenkins Stage View shows all three branches as side-by-side columns under `Verify`. Each branch runs on its own executor (subject to agent availability).

**When to use:** Independent CI checks that don't share output — test suites, linters, security scans, platform builds.

**Important constraint:** Declarative Pipeline does **not** allow nesting `parallel` inside `parallel`. All parallel branches must be at the same level. If you need sub-tasks within one branch, put them in separate top-level parallel branches instead.

## Nesting parallel stages inside a parallel branch

Declarative Pipeline does **not** support nested `parallel` inside `parallel`, and the `parallel()` step syntax from Scripted Pipeline is also not valid here. The only supported pattern is a single flat `parallel {}` block containing multiple `stage()` branches.

If you need what looks like "sub-parallel" behavior, flatten it: instead of nesting `Unit Tests` and `Lint` inside a `Test` branch, promote them to top-level parallel branches alongside `Security Scan`.

**Scripted Pipeline only** — the `parallel()` step call works in Scripted Pipeline (`node {}`):
```groovy
node {
    parallel(
        unitTests: { sh 'bash test.sh' },
        lint:      { sh 'bash lint.sh' }
    )
}
```
This syntax is **not valid** in Declarative Pipeline (`pipeline {}`).

## Fail fast vs run-all

**Default (run-all):** All parallel branches run to completion even if one fails. All failures are reported together at the end. No extra configuration needed.

**Explicit run-all** (makes intent visible in code):
```groovy
stage('Verify') {
    failFast false
    parallel {
        stage('Test') { ... }
        stage('Security Scan') { ... }
    }
}
```

**Fail fast** — abort remaining branches immediately when one fails:
```groovy
stage('Verify') {
    failFast true
    parallel {
        stage('Test') { ... }
        stage('Security Scan') { ... }
    }
}
```

Use `failFast true` when a failing branch means the rest of the work is pointless (e.g., tests fail so there's no point running the security scan).

## When to use each pattern

| Pattern | Syntax | Use when |
|---|---|---|
| Parallel stages (Declarative) | `stage { parallel { stage... } }` | Independent CI checks — all branches at same level, no nesting |
| Parallel steps (Scripted only) | `parallel(name: { ... })` | Scripted Pipeline only — not valid in Declarative |

## Verifying parallel execution in Jenkins

1. Open the build in Jenkins Stage View
2. `Unit Tests`, `Lint`, and `Security Scan` appear as side-by-side columns under `Verify`
3. Check timestamps in Console Output — all three branches log concurrently (interleaved lines)
4. If one branch fails, the others show "Aborted" in Stage View (with `failFast true`)
