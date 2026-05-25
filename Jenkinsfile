pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'bhavyatank13'
        FRONTEND_IMAGE  = 'bhavyatank13/frontend-app'
        BACKEND_IMAGE   = 'bhavyatank13/backend-app'
        APP_SERVER_IP   = '3.68.217.228'   // ← Replace with your App Server IP
        APP_SERVER_USER = 'ubuntu'
        TAG             = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Pulling code from GitHub..."
                checkout scm
            }
        }

        stage('Build Docker Images') {
            steps {
                echo "Building frontend and backend images with tag: ${TAG}"
                sh """
                    docker build -t ${FRONTEND_IMAGE}:${TAG} ./frontend
                    docker build -t ${BACKEND_IMAGE}:${TAG}  ./backend
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "Pushing images to Docker Hub..."
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${FRONTEND_IMAGE}:${TAG}
                        docker push ${BACKEND_IMAGE}:${TAG}
                    """
                }
            }
        }

        stage('Detect Active Environment') {
            steps {
                echo "Detecting which environment is currently active..."
                script {
                    def result = sh(
                        script: """
                            ssh -i /var/lib/jenkins/.ssh/app-server-key \
                                -o StrictHostKeyChecking=no \
                                ${APP_SERVER_USER}@${APP_SERVER_IP} \
                                'cat /opt/blue-green/active-env 2>/dev/null || echo none'
                        """,
                        returnStdout: true
                    ).trim()

                    echo "Current active environment: ${result}"

                    if (result == 'blue') {
                        env.ACTIVE_ENV   = 'blue'
                        env.INACTIVE_ENV = 'green'
                    } else {
                        // first deploy or green is active → deploy to blue
                        env.ACTIVE_ENV   = 'green'
                        env.INACTIVE_ENV = 'blue'
                    }

                    echo "Will deploy to: ${env.INACTIVE_ENV}"
                }
            }
        }

        stage('Deploy to Inactive Environment') {
            steps {
                echo "Deploying to ${env.INACTIVE_ENV} environment with tag ${TAG}..."
                sh """
                    ssh -i /var/lib/jenkins/.ssh/app-server-key \
                        -o StrictHostKeyChecking=no \
                        ${APP_SERVER_USER}@${APP_SERVER_IP} \
                        'bash /opt/blue-green/scripts/deploy-${env.INACTIVE_ENV}.sh ${TAG}'
                """
            }
        }

        stage('Health Check') {
            steps {
                echo "Running health check on ${env.INACTIVE_ENV}..."
                sh """
                    ssh -i /var/lib/jenkins/.ssh/app-server-key \
                        -o StrictHostKeyChecking=no \
                        ${APP_SERVER_USER}@${APP_SERVER_IP} \
                        'bash /opt/blue-green/scripts/health-check.sh ${env.INACTIVE_ENV}'
                """
            }
        }

        stage('Switch Nginx Traffic') {
            steps {
                echo "Switching Nginx traffic to ${env.INACTIVE_ENV}..."
                sh """
                    ssh -i /var/lib/jenkins/.ssh/app-server-key \
                        -o StrictHostKeyChecking=no \
                        ${APP_SERVER_USER}@${APP_SERVER_IP} \
                        'bash /opt/blue-green/scripts/switch.sh ${env.INACTIVE_ENV}'
                """
            }
        }

        stage('Remove Old Environment') {
            steps {
                echo "Removing old ${env.ACTIVE_ENV} containers..."
                sh """
                    ssh -i /var/lib/jenkins/.ssh/app-server-key \
                        -o StrictHostKeyChecking=no \
                        ${APP_SERVER_USER}@${APP_SERVER_IP} \
                        'cd /opt/blue-green && TAG=${TAG} docker compose -f docker-compose.${env.ACTIVE_ENV}.yml down --remove-orphans || true'
                """
            }
        }

    }

    post {
        success {
            echo "=============================="
            echo " Deployment SUCCESS!"
            echo " Active environment: ${env.INACTIVE_ENV}"
            echo " Image tag: ${TAG}"
            echo "=============================="
        }
        failure {
            echo "=============================="
            echo " Deployment FAILED!"
            echo " Running rollback to: ${env.ACTIVE_ENV}"
            echo "=============================="
            sh """
                ssh -i /var/lib/jenkins/.ssh/app-server-key \
                    -o StrictHostKeyChecking=no \
                    ${APP_SERVER_USER}@${APP_SERVER_IP} \
                    'bash /opt/blue-green/scripts/rollback.sh ${env.ACTIVE_ENV}' || true
            """
        }
    }
}