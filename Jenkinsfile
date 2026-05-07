#!/usr/bin/env groovy

pipeline {
    agent any

    parameters {
        string(
            name: 'SONAR_HOST_URL',
            defaultValue: 'http://sonarqube:9000',
            description: 'SonarQube base URL reachable from the Jenkins agent. Default uses the in-network DNS alias \'sonarqube\' (compose.sonar.yml attaches SonarQube to the same Docker network as circleguard-jenkins). Use http://host.docker.internal:9000 only if running outside that network.'
        )
    }

    environment {
        SONAR_PROJECT_KEY = 'cicd-demo'
        DOCKER_IMAGE = 'mi-app:latest'
        DEPLOY_CONTAINER = 'mi-app-run'
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'chmod +x mvnw || true'
                sh './mvnw -B -ntp clean compile'
            }
        }

        stage('Test') {
            steps {
                sh './mvnw -B -ntp test'
            }
        }

        stage('Docker Build') {
            steps {
                sh './mvnw -B -ntp package -DskipTests'
                sh "docker build -t ${env.DOCKER_IMAGE} ."
            }
        }

        stage('Static Analysis (SonarQube)') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        ./mvnw -B -ntp sonar:sonar \\
                          -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \\
                          -Dsonar.host.url='${params.SONAR_HOST_URL}' \\
                          -Dsonar.login=\${SONAR_TOKEN} \\
                          -Dsonar.qualitygate.wait=true
                    """
                }
            }
        }

        stage('Quality Gate (Security Hotspots)') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        export SONAR_HOST_URL='${params.SONAR_HOST_URL}'
                        export SONAR_PROJECT_KEY='${env.SONAR_PROJECT_KEY}'
                        bash jenkins/check-sonar-hotspots.sh
                    """
                }
            }
        }

        stage('Container Security Scan (Trivy)') {
            steps {
                sh """
                    trivy image --exit-code 1 --severity CRITICAL --no-progress ${env.DOCKER_IMAGE}
                """
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                sh """
                    docker rm -f ${env.DEPLOY_CONTAINER} || true
                    docker run -d --name ${env.DEPLOY_CONTAINER} -p 80:80 ${env.DOCKER_IMAGE}
                """
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed: review unit tests, SonarQube (Quality Gate / Security Hotspots), or Trivy CRITICAL findings. Configure mailer or Slack separately if you need external notifications.'
        }
        always {
            echo 'Limpiando entorno...'
            junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
            cleanWs()
        }
    }
}
