pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                sh 'pwd && ls -la'
            }
        }
        stage('Hello') {
            steps {
                echo 'Running hello.sh...'
                sh './hello.sh'
            }
        }
        stage('Build') {
            steps {
                echo 'Build stage — placeholder for compile/package step'
            }
        }
        stage('Test') {
            steps {
                echo 'Test stage — placeholder for running test suite'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploy stage — placeholder for deployment step'
            }
        }
    }

    post {
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed — check logs above.' }
        always  { echo 'Pipeline finished.' }
    }
}
