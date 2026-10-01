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
