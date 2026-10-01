# Jenkins Stage 6 — Parallel Stages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add parallel execution to the pipeline — `Test` and `Security Scan` run concurrently inside a `Verify` wrapper stage, and `test.sh` + `lint.sh` run as parallel steps inside the Test branch.

**Architecture:** Three files change — `lint.sh` is created first (needed by Jenkinsfile), `Jenkinsfile` is updated to replace the single `Test` stage with a `Verify` parallel wrapper, and `docs/stage6-parallel.md` is created as a reference doc. Tasks are ordered so each produces a testable deliverable independently.

**Tech Stack:** Jenkins Declarative Pipeline (Groovy DSL), Bash

## Global Constraints

- Jenkins installed locally at `http://localhost:8080`
- Remote: `https://github.com/sushruthb/jenkins-demo.git`, branch `main`
- Parallel wrapper stage name must be exactly: `Verify`
- Parallel branches must be exactly: `Test` and `Security Scan`
- Parallel steps inside Test must be named exactly: `unitTests` and `lint`
- `lint.sh` must be committed with executable bit: `git add --chmod=+x lint.sh`
- `output.txt` must NOT be committed
- `triggers { pollSCM('H/5 * * * *') }` must be preserved in Jenkinsfile

---

### Task 1: Create lint.sh

**Files:**
- Create: `lint.sh`

**Interfaces:**
- Produces: `lint.sh` — executable script that checks all `*.sh` files in the current directory with `bash -n`, prints `OK: <filename>` for each, exits non-zero if any file has a syntax error

- [ ] **Step 1: Verify lint works locally before writing the script**

```bash
cd /Users/I504285/Library/CloudStorage/OneDrive-SAPSE/jenkins-demo
bash -n hello.sh && echo "OK: hello.sh"
bash -n test.sh  && echo "OK: test.sh"
```

Expected output:
```
OK: hello.sh
OK: test.sh
```

- [ ] **Step 2: Create lint.sh**

Create `/Users/I504285/Library/CloudStorage/OneDrive-SAPSE/jenkins-demo/lint.sh` with this exact content:

```bash
#!/bin/bash
set -e
echo "--- Lint: checking shell script syntax ---"
for f in *.sh; do
    bash -n "$f" && echo "OK: $f"
done
echo "--- Lint passed ---"
```

- [ ] **Step 3: Run lint.sh locally to verify it works**

```bash
cd /Users/I504285/Library/CloudStorage/OneDrive-SAPSE/jenkins-demo
bash lint.sh
```

Expected output:
```
--- Lint: checking shell script syntax ---
OK: hello.sh
OK: lint.sh
OK: test.sh
--- Lint passed ---
```

- [ ] **Step 4: Commit with executable bit**

```bash
git add --chmod=+x lint.sh
git commit -m "feat: add lint.sh to check shell script syntax"
```

---

### Task 2: Update Jenkinsfile with parallel Verify stage

**Files:**
- Modify: `Jenkinsfile`

**Interfaces:**
- Consumes: `lint.sh` (from Task 1) — must exist in repo before this Jenkinsfile runs
- Produces: updated `Jenkinsfile` with `Verify` stage replacing the old `Test` stage, containing parallel `Test` and `Security Scan` branches, with `unitTests` and `lint` as parallel steps inside `Test`

- [ ] **Step 1: Replace the entire Jenkinsfile contents**

Replace `/Users/I504285/Library/CloudStorage/OneDrive-SAPSE/jenkins-demo/Jenkinsfile` with:

```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    }

    environment {
        APP_ENV = "${params.ENVIRONMENT}"
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Environment: ${APP_ENV}"
            }
        }
        stage('Build') {
            steps {
                echo "Building for ${APP_ENV}..."
                sh './hello.sh > output.txt'
                echo 'Build complete — output.txt created'
            }
        }
        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        echo "Running tests for ${APP_ENV}..."
                        parallel(
                            unitTests: { sh 'APP_ENV=${APP_ENV} bash test.sh' },
                            lint:      { sh 'bash lint.sh' }
                        )
                    }
                }
                stage('Security Scan') {
                    steps {
                        echo 'Running security scan...'
                        sh 'grep -rn "password\\|secret\\|token" . --include="*.sh" || true'
                        echo 'Security scan complete'
                    }
                }
            }
        }
        stage('Archive') {
            steps {
                echo 'Archiving artifacts...'
                archiveArtifacts artifacts: 'output.txt', fingerprint: true
            }
        }
        stage('Deploy') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                echo "Deploying to ${APP_ENV}..."
                echo 'Deploy complete.'
            }
        }
    }

    post {
        success { echo "Pipeline completed successfully for ${APP_ENV}!" }
        failure { echo 'Pipeline failed — check logs above.' }
        always  { echo 'Pipeline finished.' }
    }
}
```

- [ ] **Step 2: Verify the Jenkinsfile has no obvious syntax issues**

Check that `Verify`, `Test`, `Security Scan`, `unitTests`, and `lint` all appear exactly once:

```bash
grep -n "stage\|parallel\|unitTests\|lint" /Users/I504285/Library/CloudStorage/OneDrive-SAPSE/jenkins-demo/Jenkinsfile
```

Expected: lines for `stage('Verify')`, `stage('Test')`, `stage('Security Scan')`, `parallel {`, `parallel(`, `unitTests:`, `lint:` all present.

- [ ] **Step 3: Commit**

```bash
git add Jenkinsfile
git commit -m "feat: add parallel Verify stage with Test and Security Scan branches"
```

---

### Task 3: Create docs/stage6-parallel.md

**Files:**
- Create: `docs/stage6-parallel.md`

**Interfaces:**
- Produces: reference doc covering parallel stages, parallel steps, fail fast vs run-all, and when-to-use table

- [ ] **Step 1: Create docs/stage6-parallel.md**

Create `/Users/I504285/Library/CloudStorage/OneDrive-SAPSE/jenkins-demo/docs/stage6-parallel.md` with this exact content:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add docs/stage6-parallel.md
git commit -m "docs: add stage6 parallel stages reference"
```

---

### Task 4: Push and verify in Jenkins

**Files:** none — push and manual verification

- [ ] **Step 1: Push all commits**

```bash
git push origin main
```

Expected:
```
To https://github.com/sushruthb/jenkins-demo.git
   <old>..<new>  main -> main
```

- [ ] **Step 2: Trigger a build in Jenkins**

1. Go to `http://localhost:8080/job/jenkins-stage2-scm/`
2. Click **Build with Parameters**
3. Select `dev` → click **Build**

- [ ] **Step 3: Verify parallel execution in Stage View**

1. Open the build → **Stage View** (or Pipeline Steps)
2. Confirm `Test` and `Security Scan` appear side by side under `Verify`
3. Confirm all stages green: Checkout → Build → Verify (Test + Security Scan) → Archive

- [ ] **Step 4: Check Console Output for parallel evidence**

Open Console Output and confirm:
- Lines from `unitTests` and `lint` are interleaved (both running at same time)
- `Security Scan` grep output appears alongside Test output
- `--- Lint passed ---` appears
- `Security scan complete` appears
- `Archive` runs after both branches complete

---

## Done Criteria

- [ ] `lint.sh` exists, is executable, checks all `*.sh` files with `bash -n`
- [ ] `Jenkinsfile` has `Verify` stage with `parallel {}` containing `Test` and `Security Scan`
- [ ] Inside `Test`, `parallel()` runs `unitTests` and `lint` concurrently
- [ ] Jenkins Stage View shows `Test` and `Security Scan` side by side
- [ ] `docs/stage6-parallel.md` covers both parallel patterns, fail fast vs run-all, and when-to-use table
- [ ] `output.txt` not committed
