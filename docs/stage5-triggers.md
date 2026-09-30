# Jenkins Stage 5 — Triggers Reference

## triggers { pollSCM(...) } block

Tells Jenkins to periodically check the configured SCM (Git) for new commits. If changes are found, a build is triggered automatically.

```groovy
triggers {
    pollSCM('H/5 * * * *')
}
```

**Cron syntax:** 5 fields — minute, hour, day-of-month, month, day-of-week.

| Field | Value | Meaning |
|---|---|---|
| `H/5` | minute | every 5 minutes (H = hash, spreads load) |
| `*` | hour | every hour |
| `*` | day-of-month | every day |
| `*` | month | every month |
| `*` | day-of-week | every day of week |

**What `H` means:** Instead of all jobs polling at minute :00 and :05 and :10, Jenkins computes a hash of the job name and uses that as the offset. This spreads polling load across the Jenkins instance.

**Important:** The first build after adding `triggers {}` must be triggered manually. Jenkins registers the poll schedule only after the job has run once with the new configuration.

**Verifying poll activity:**
1. Go to `http://localhost:8080/job/<job-name>/`
2. Left sidebar → **Git Polling Log**
3. You'll see entries like: `Changes found. Triggering a build.` or `No changes`

## pollSCM vs Webhooks

| | pollSCM | Webhook |
|---|---|---|
| How it works | Jenkins asks GitHub "any changes?" on a schedule | GitHub pushes a notification to Jenkins instantly |
| Latency | Up to poll interval (e.g., 5 min) | Near-instant (seconds) |
| Requires public URL | No | Yes |
| Works on localhost | Yes | Only with ngrok/tunnel |
| Production use | Acceptable for firewalled environments; webhooks preferred otherwise | Preferred |

## Setting Up a Webhook with ngrok

ngrok creates a temporary public HTTPS URL that tunnels to your local Jenkins.

### Step 1: Install ngrok

```bash
brew install ngrok
```

### Step 2: Start the tunnel

```bash
ngrok http 8080
```

You'll see output like:
```
Forwarding  https://abc123.ngrok-free.app -> http://localhost:8080
```

Copy the `https://...ngrok-free.app` URL. Keep this terminal open — closing it kills the tunnel.

### Step 3: Add webhook in GitHub

1. Go to your repo: `https://github.com/sushruthb/jenkins-demo`
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL:** `https://<your-ngrok-url>/github-webhook/`
4. **Content type:** `application/json`
5. **Which events:** select `Just the push event`
6. Click **Add webhook**

### Step 4: Enable webhook trigger in Jenkins

1. Go to `http://localhost:8080/job/<job-name>/configure`
2. Under **Build Triggers**, check **GitHub hook trigger for GITScm polling**
3. Click **Save**

### Step 5: Test it

Make a small change, commit and push:
```bash
echo "# trigger" >> README.md
git add README.md
git commit -m "test: trigger webhook"
git push origin main
```

Jenkins should start a build within a few seconds.

## Verifying Triggers

**Poll log (pollSCM):**
- Jenkins job → left sidebar → **Git Polling Log**
- Shows each poll attempt and whether changes were found

**Webhook delivery (GitHub):**
- GitHub repo → **Settings** → **Webhooks** → click your webhook → **Recent Deliveries** tab
- Green checkmark = Jenkins received and acknowledged the payload
- Red X = delivery failed (check Jenkins URL and GitHub hook trigger setting)
