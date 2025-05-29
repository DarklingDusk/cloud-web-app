pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically apply Terraform plan?')
    }

    environment {
        AWS_REGION     = 'us-east-1'
        CREDENTIALS_ID = 'aws-credentials'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

       

       stage('Terraform Init & Plan') {
    steps {
        dir('cloud web app/terraform') {
            withAWS(region: 'us-east-1', credentials: 'aws-credentials') {
                bat 'terraform init'
                bat 'terraform plan -out=tfplan'
                bat 'terraform show -no-color tfplan > tfplan.txt'
            }
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
                        bat "terraform apply -input=false tfplan"
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
