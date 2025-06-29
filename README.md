# 🔐 AWS Security Group Auto-Remediation using AWS Config, Lambda, and SSM

This project demonstrates how to automatically detect and remediate EC2 Security Groups that allow open SSH access (`0.0.0.0/0`) using:

- ✅ **AWS Config** to detect insecure Security Groups
- ✅ **SSM Automation** to invoke remediation
- ✅ **AWS Lambda** function to remove the offending rule

---

## 📐 Architecture Diagram

![AWS Auto Remediation Flow](https://raw.githubusercontent.com/habbasius/aws-security-group-remediation/main/assets/aws-remediation-diagram.png)

---

## 📁 Project Structure

├── terraform/ # Terraform IaC: EC2, Config rule, Lambda, SSM
│ └── main.tf
├── lambda/ # Python code to revoke open SSH rule
│ └── lambda_function.py
├── reset.sh # Cleanup script
├── .gitignore
├── README.md


---

## 🚀 Deployment Steps

1. **Clone this repo:**

```bash
git clone https://github.com/habbasius/aws-security-group-remediation.git
cd aws-security-group-remediation

2. Deploy Terraform:

cd terraform
terraform init
terraform apply

3.     Verify:

AWS Config (INCOMING_SSH_DISABLED) 
         ↓
AWS Config Remediation → SSM Automation
         ↓
    Invokes Lambda function
         ↓
Lambda removes SSH ingress from SG

How It Works (Event-Driven Flow)

AWS Config (INCOMING_SSH_DISABLED) 
         ↓
AWS Config Remediation → SSM Automation
         ↓
    Invokes Lambda function
         ↓
Lambda removes SSH ingress from SG

Lambda Function (Sample)

import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    group_id = event['GroupId']
    ec2.revoke_security_group_ingress(
        GroupId=group_id,
        IpProtocol='tcp',
        FromPort=22,
        ToPort=22,
        CidrIp='0.0.0.0/0'
    )


Author

Hamid Abbasi — AWS Solution Architect | Security & Automation | Medium Author

