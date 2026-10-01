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

## parallel() step inside a stage

Runs multiple step groups concurrently within a single stage branch. Called as a map of name → closure.

```groovy
stage('Test') {
    steps {
        parallel(
            unitTests: { sh 'bash test.sh' },
            lint:      { sh 'bash lint.sh' }
        )
    }
}
```

Both closures run at the same time on the same executor. The stage completes when both finish (or one fails).

**When to use:** Sub-tasks within one logical stage — multiple test suites, multiple lint targets, parallel file processing.

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
| Parallel steps | `parallel(name: { ... })` | Sub-tasks within one branch — multiple test suites, multiple lint targets |

## Verifying parallel execution in Jenkins

1. Open the build in Jenkins Stage View
2. `Test` and `Security Scan` appear as side-by-side columns under `Verify`
3. Check timestamps in Console Output — both branches log concurrently (interleaved lines)
4. If one branch fails, the other shows "Aborted" in Stage View
