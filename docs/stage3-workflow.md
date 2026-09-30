# Jenkins Stage 3 — Real Workflow Reference

## The Build→Test→Archive Pattern

Each stage has one responsibility and depends on the previous succeeding:

1. **Checkout** — pulls all files from GitHub into the Jenkins workspace
2. **Build** — runs the app/script and produces output (`output.txt`)
3. **Test** — verifies the output is correct; fails the pipeline if not
4. **Archive** — stores the output as a Jenkins artifact for later retrieval

If Build fails, Jenkins skips Test and Archive automatically. If Test fails, Archive is skipped. This ensures you never archive untested output.

## checkout scm

`checkout scm` is a Jenkins built-in step that clones your Git repository into the workspace. This is what was missing in Stage 1 — the workspace was empty because there was no checkout step.

When a Jenkins job is configured with "Pipeline script from SCM", `checkout scm` uses the repo URL and branch you configured in the job settings. You don't hardcode the URL in the Jenkinsfile — Jenkins injects it at runtime.

## archiveArtifacts

`archiveArtifacts artifacts: 'output.txt', fingerprint: true` stores `output.txt` in Jenkins after the pipeline runs.

**Where to find it:**
1. Open the build in Jenkins (e.g., `http://localhost:8080/job/jenkins-stage2-scm/1/`)
2. Look for the **Build Artifacts** section on the build page
3. Click `output.txt` to download it

**fingerprint: true** tells Jenkins to compute a checksum of the file and track which builds produced it. Useful when multiple jobs share the same artifact.

## Running Tests Locally

`test.sh` is a plain Bash script — no Jenkins needed:

```bash
# First simulate what the Build stage does
./hello.sh > output.txt

# Then run the tests
bash test.sh
```

All tests should pass. This lets you verify test logic before pushing to GitHub.
