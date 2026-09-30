// Scripted Pipeline — reference only, not run by Jenkins directly.
// Compare with Jenkinsfile to see Declarative vs Scripted differences.

node {
    stage('Checkout') {
        echo 'Checking out code...'
        sh 'pwd && ls -la'
    }
    stage('Hello') {
        echo 'Running hello.sh...'
        sh './hello.sh'
    }
    stage('Build') {
        echo 'Build stage — placeholder'
    }
    stage('Test') {
        echo 'Test stage — placeholder'
    }
    stage('Deploy') {
        echo 'Deploy stage — placeholder'
    }
}
