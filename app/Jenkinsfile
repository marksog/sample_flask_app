pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'marksog/some_sample_flask_app'
        DOCKER_MIGRATION_IMAGE_NAME = 'marksog/some_sample_flask_app_migration'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        GITHUB_CREDENTIALS = credentials('git_credentials')
        GIT_BRANCH = 'main'
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Clone Repository') {
            steps {
                script {
                    git branch: "${GIT_BRANCH}",
                        credentialsId: "${GITHUB_CREDENTIALS}",
                        url: 'https://github.com/marksog/sample_flask_app.git'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dir('app') {
                        docker.build("${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}", '-f Dockerfile .')
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    sh "trivy image --severity CRITICAL ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                    sh "trivy image --severity HIGH ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-credentials') {
                        docker.image("${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}").push()
                    }
                }
            }
        }


        stage('Update Kubernetes Manifest') {
            steps {
                script {
                    update_k8s_manifest(
                        imageTag: env.DOCKER_IMAGE_TAG,
                        manifestsPath: 'k8s/app',
                        gitCredentialsId: 'github_credentials',
                        gitUserName: 'Jenkins',
                        gitUserEmail: 'meyofmarksog@gmail.com'
                    )
                }
            }
        }
    }
}