# Jenkins Stage 6 — Parallel Stages Design Spec

## Goal

Restructure the existing pipeline to run the Test and Security Scan stages concurrently, and run `test.sh` and `lint.sh` as parallel steps inside the Test branch. Add `lint.sh` to check shell script syntax. Document both parallel patterns in `docs/stage6-parallel.md`.

## File Changes

```
jenkins-demo/
├── Jenkinsfile              # UPDATED — parallel wrapper stage + parallel steps inside Test
├── lint.sh                  # NEW — checks all .sh files for syntax errors with bash -n
└── docs/
    └── stage6-parallel.md   # NEW — parallel stages and steps reference
```

## Updated Pipeline Structure

Stage order:

```
Checkout → Build → Verify [Test ‖ SecurityScan] → Archive → Deploy
```

`Verify` is a parallel wrapper stage with two branches running concurrently:
- **Test** branch: runs `test.sh` and `lint.sh` as parallel steps
- **Security Scan** branch: greps `.sh` files for sensitive patterns

If either branch fails, Jenkins aborts the other immediately (fail fast — default behavior).

## Updated Jenkinsfile

Full replacement:

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

## lint.sh

```bash
#!/bin/bash
set -e
echo "--- Lint: checking shell script syntax ---"
for f in *.sh; do
    bash -n "$f" && echo "OK: $f"
done
echo "--- Lint passed ---"
```

Must be committed with executable bit: `git add --chmod=+x lint.sh`

## docs/stage6-parallel.md

Four sections:

### 1. parallel {} at the stage level
- Syntax: wrap multiple `stage()` blocks inside a `parallel {}` block inside a parent stage
- Jenkins Stage View shows parallel branches side by side
- Each branch gets its own agent (or shares `agent any`)
- Example: the `Verify` stage above

### 2. parallel() step inside a stage
- Syntax: call `parallel(name: { steps }, name: { steps })` inside a `steps {}` block
- Runs multiple step groups concurrently within one branch
- Example: `unitTests` and `lint` inside the Test branch above

### 3. Fail fast vs run-all
- Default (fail fast): if one branch fails, Jenkins aborts remaining branches immediately
- Explicit fail fast: `failFast: true` on the parallel wrapper stage (same as default, but makes intent explicit)
- Run all to completion: `failFast: false` — all branches finish, all failures reported together
- Syntax:
  ```groovy
  stage('Verify') {
      failFast true
      parallel { ... }
  }
  ```

### 4. When to use each pattern
| Pattern | Use when |
|---|---|
| Parallel stages (`parallel {}`) | Independent CI checks — test, lint, scan, build for different platforms |
| Parallel steps (`parallel()`) | Sub-tasks within one logical stage — multiple test suites, multiple lint targets |

## Success Criteria

- `Jenkinsfile` has `Verify` stage with `parallel {}` containing `Test` and `Security Scan` branches
- Inside `Test`, `parallel()` runs `unitTests` and `lint` concurrently
- `lint.sh` checks all `.sh` files with `bash -n` and exits non-zero if any fail
- Jenkins Stage View shows `Test` and `Security Scan` running side by side
- `docs/stage6-parallel.md` covers both parallel patterns, fail fast vs run-all, and a when-to-use table
