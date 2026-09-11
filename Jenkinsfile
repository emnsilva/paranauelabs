// Arquivo: paranauelabs/Jenkinsfile
// Roteador raiz do Monorepo. 
// Em um cenário real com o plugin "Multibranch Pipeline", este arquivo 
// acionaria o Jenkinsfile interno do laboratório com base na pasta alterada.

pipeline {
    agent any
    stages {
        stage('Detect Lab') {
            steps {
                script {
                    // Para simplificar o laboratório, apontamos diretamente para o lab 01.
                    // Em produção, usar-se-ia um plugin de comparação de commits.
                    echo "Acionando pipeline do laboratório 01-iac-railways..."
                    build job: 'paranauelabs-iac', wait: true
                }
            }
        }
    }
}