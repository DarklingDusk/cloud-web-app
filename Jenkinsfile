pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically apply Terraform plan?')
    }

    environment {
        AWS_REGION     = 'us-east-1'
        S3_BUCKET      = 'my-flask-app-bucket'
        ZIP_NAME       = 'flask-app.zip'
        CREDENTIALS_ID = 'aws-credentials'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

       stage('Install Dependencies and Test') {
    steps {
        dir('cloud web app/app') {
            bat 'pip install -r requirements.txt'
            bat 'pytest'
        }
    }
}

        }

        stage('Package Flask App') {
            steps {
                sh """
                cd app
                zip -r ../${ZIP_NAME} *
                """
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir('terraform') {
                    withAWS(region: "${env.AWS_REGION}", credentials: "${env.CREDENTIALS_ID}") {
                        sh '''
                        terraform init
                        terraform plan -out=tfplan
                        terraform show -no-color tfplan > tfplan.txt
                        '''
                    }
                }
            }
        }

        stage('Upload to S3') {
            steps {
                withAWS(region: "${env.AWS_REGION}", credentials: "${env.CREDENTIALS_ID}") {
                    sh "aws s3 cp ${ZIP_NAME} s3://${S3_BUCKET}/${ZIP_NAME} --region ${AWS_REGION}"
                }
            }
        }

        stage('Approval') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }
            steps {
                script {
                    def plan = readFile 'terraform/tfplan.txt'
                    input message: "Do you want to apply this Terraform plan?",
                          parameters: [text(name: 'Plan', description: 'Review the plan below', defaultValue: plan)]
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withAWS(region: "${env.AWS_REGION}", credentials: "${env.CREDENTIALS_ID}") {
                        sh "terraform apply -input=false tfplan"
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Deployment Failed!'
        }
    }
}
