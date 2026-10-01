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

**Default (fail fast):** If one parallel branch fails, Jenkins aborts the remaining branches immediately. No extra configuration needed.

**Explicit fail fast** (makes intent visible in code):
```groovy
stage('Verify') {
    failFast true
    parallel {
        stage('Test') { ... }
        stage('Security Scan') { ... }
    }
}
```

**Run all to completion** — all branches finish even if one fails, then all failures are reported together:
```groovy
stage('Verify') {
    failFast false
    parallel {
        stage('Test') { ... }
        stage('Security Scan') { ... }
    }
}
```

Use `failFast false` when you want a full picture of all failures before fixing anything (e.g., a nightly report run).

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
