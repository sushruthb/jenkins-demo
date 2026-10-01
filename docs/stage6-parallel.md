# Jenkins Stage 6 — Parallel Stages Reference

## parallel {} at the stage level

Wraps multiple `stage()` blocks so they run concurrently. The parent stage acts as a container — it has no `steps {}` of its own.

```groovy
stage('Verify') {
    parallel {
        stage('Test') {
            steps { sh './test.sh' }
        }
        stage('Security Scan') {
            steps { sh './scan.sh' }
        }
    }
}
```

Jenkins Stage View shows `Test` and `Security Scan` as side-by-side columns under `Verify`. Each branch runs on its own executor (subject to agent availability).

**When to use:** Independent CI checks that don't share output — test suites, linters, security scans, platform builds.

## Nesting parallel stages inside a parallel branch

In Declarative Pipeline, `parallel {}` can only contain `stage()` blocks — you cannot call `parallel()` as a step inside `steps {}`. To run sub-tasks in parallel within one branch, nest another `parallel {}` block inside that branch's stage:

```groovy
stage('Verify') {
    parallel {
        stage('Test') {          // branch 1 — itself a parallel wrapper
            parallel {
                stage('Unit Tests') {
                    steps { sh 'bash test.sh' }
                }
                stage('Lint') {
                    steps { sh 'bash lint.sh' }
                }
            }
        }
        stage('Security Scan') { // branch 2
            steps { sh './scan.sh' }
        }
    }
}
```

Jenkins Stage View shows `Unit Tests` and `Lint` as nested columns inside `Test`, alongside `Security Scan`.

**Note:** The `parallel(name: { closure })` step syntax works in Scripted Pipeline (`node {}`) but is **not valid** in Declarative Pipeline (`pipeline {}`). Always use nested `parallel { stage(...) }` blocks in Declarative.

**When to use:** Sub-tasks within one branch that are independent — multiple test suites, multiple lint targets.

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
| Parallel stages | `stage { parallel { stage... } }` | Independent CI checks — test, scan, multi-platform build |
| Nested parallel stages | `stage { parallel { stage { parallel { stage... } } } }` | Sub-tasks within one branch — multiple test suites, lint + tests |

## Verifying parallel execution in Jenkins

1. Open the build in Jenkins Stage View
2. `Test` and `Security Scan` appear as side-by-side columns under `Verify`
3. Check timestamps in Console Output — both branches log concurrently (interleaved lines)
4. If one branch fails, the other shows "Aborted" in Stage View
