# Jenkins Stage 4 — Parameters & Environment Reference

## parameters {} block

Defines build-time inputs shown in the Jenkins UI under "Build with Parameters".

```groovy
parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
}
```

Common parameter types:
- `choice(name, choices, description)` — dropdown list
- `string(name, defaultValue, description)` — free-text input
- `booleanParam(name, defaultValue, description)` — checkbox

Access parameters in steps with `params.NAME`:
```groovy
echo "Selected: ${params.ENVIRONMENT}"
```

**Note:** The first build after adding `parameters {}` runs with the default value automatically. From the second build onward, Jenkins shows the "Build with Parameters" UI.

## environment {} block

Sets environment variables available to all stages in the pipeline.

```groovy
environment {
    APP_ENV = "${params.ENVIRONMENT}"
}
```

- Variables are set before any stage runs
- Access with `${VAR_NAME}` in Groovy strings or `$VAR_NAME` in shell steps
- Can reference `params.*` to derive values from build parameters
- Jenkins Credentials Store values can also be injected here (Stage 5 topic)

## when { expression { ... } } condition

Skips a stage based on a Groovy expression. The stage runs only when the expression returns `true`.

```groovy
stage('Deploy') {
    when {
        expression { params.ENVIRONMENT == 'prod' }
    }
    steps {
        echo "Deploying to ${APP_ENV}..."
    }
}
```

**Important:** Use `params.ENVIRONMENT` inside `when`, not `env.APP_ENV`. The `environment {}` block variables are not accessible in `when` expressions in Declarative Pipeline.

Other common `when` conditions:
- `when { branch 'main' }` — run only on main branch
- `when { not { branch 'main' } }` — skip on main branch
- `when { expression { currentBuild.number > 1 } }` — skip first build

## Running the Parameterized Pipeline

1. Push changes to GitHub
2. Click **Build Now** — first build runs with `ENVIRONMENT=dev` (default), Deploy stage is skipped
3. From the second build onward, click **Build with Parameters**
4. Select `prod` → Deploy stage runs
5. Select `dev` or `staging` → Deploy stage is skipped (shown as grey in Stage View)

## Running test.sh Locally

Test 4 checks that `APP_ENV` is set. When running locally, pass it explicitly:

```bash
./hello.sh > output.txt
APP_ENV=dev bash test.sh
```
