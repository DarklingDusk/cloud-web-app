# Cloud Web App Deployment with Terraform and Jenkins

## Project Overview

This project demonstrates the deployment of a **Flask web application** on AWS using **Terraform** for infrastructure provisioning and **Jenkins** for CI/CD automation. The application is hosted on an **EC2 instance**, with static files stored in an **S3 bucket**.

Key Features:

* Provision AWS resources (EC2, S3, Security Group, IAM policies) with Terraform.
* Automate deployment via Jenkins pipeline.
* Secure S3 access using IAM policies.
* Manual or automatic approval for Terraform apply.

---

## Project Structure

```
cloud-web-app/
├── flask_app/                  # Your Flask application
│   ├── app.py
│   ├── requirements.txt
│   └── templates/
├── terraform/                  # Terraform configuration files
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── Jenkinsfile                 # Jenkins pipeline definition
└── README.md
```

---

## Prerequisites

* AWS account with access keys
* Terraform installed (v1.5+ recommended)
* Jenkins installed with AWS CLI & Terraform plugin
* Python 3 installed on EC2 instance

---

## Terraform Infrastructure

The Terraform configuration provisions:

1. **EC2 Instance**

   * Instance type: `t2.micro`
   * Security group allows HTTP (80) & HTTPS (443)
   * Optional: SSH access for debugging

2. **S3 Bucket**

   * Bucket for static files
   * Configured with public access (or restricted if needed)

3. **IAM User Policy**

   * Policy attached to `web-app-user` for S3 read/write access

---

### Terraform Commands

```bash
# Initialize Terraform
terraform init

# Generate execution plan
terraform plan -out=tfplan

# Apply plan
terraform apply -input=false tfplan
```

---

## Jenkins Pipeline

The **Jenkinsfile** automates:

1. Checkout code from repository.
2. Terraform initialization and plan generation.
3. Optional manual approval for applying changes.
4. Terraform apply to provision infrastructure.

**Parameters:**

* `autoApprove` – Automatically apply Terraform plan without manual input (default: false)

**Stages:**

* Checkout
* Terraform Init & Plan
* Approval (manual, optional)
* Terraform Apply
* Post actions for success/failure

---

## Deploy Flask App on EC2

After provisioning EC2:

1. SSH into the EC2 instance.
2. Install dependencies (if not already done via `user_data`):

```bash
sudo yum update -y
sudo yum install -y python3 unzip awscli
pip3 install flask
```

3. Deploy your Flask app:

```bash
scp -r flask_app/* ec2-user@<EC2_PUBLIC_IP>:/home/ec2-user/
```

4. Run Flask app:

```bash
cd /home/ec2-user/flask_app
python3 app.py
```

5. Access via `http://<EC2_PUBLIC_IP>:5000`

---

## Notes

* For production, consider using **EC2 IAM Role** instead of IAM user for S3 access.
* Enable **S3 versioning & encryption** for security.
* Use **Terraform remote state** (S3 + DynamoDB) for CI/CD pipelines.

---

## Team Contributors

**Yogesh P** 

**Rishi I**

**Sunil Kumar S**

**Santhosh Kumar R**

**Yogeshwaran M**

---
