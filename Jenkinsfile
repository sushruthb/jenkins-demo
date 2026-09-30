pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code checked out from GitHub'
            }
        }
        stage('Build') {
            steps {
                echo 'Running hello.sh and capturing output...'
                sh './hello.sh > output.txt'
                echo 'Build complete — output.txt created'
            }
        }
        stage('Test') {
            steps {
                echo 'Running test suite...'
                sh './test.sh'
            }
        }
        stage('Archive') {
            steps {
                echo 'Archiving artifacts...'
                archiveArtifacts artifacts: 'output.txt', fingerprint: true
            }
        }
    }

    post {
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed — check logs above.' }
        always  { echo 'Pipeline finished.' }
    }
}
