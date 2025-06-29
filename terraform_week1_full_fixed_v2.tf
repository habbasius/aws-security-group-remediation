provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "open_ssh_sg" {
  name        = "open-ssh-sg"
  description = "Allow SSH from anywhere"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "example" {
  ami           = data.aws_ssm_parameter.latest_ami.value
  instance_type = "t2.micro"
  security_groups = [aws_security_group.open_ssh_sg.name]
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# ✅ Add Inline EC2 Permissions
resource "aws_iam_policy" "lambda_ec2_policy" {
  name = "lambda-ec2-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy" {
  name       = "lambda-policy-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

resource "aws_lambda_function" "remediate" {
  function_name = "remediateOpenSSHNew"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "remediate_openssh_lambda.zip"
  source_code_hash = filebase64sha256("remediate_openssh_lambda.zip")

  timeout     = 30
  memory_size = 256
}

resource "aws_iam_role" "ssm_automation_role" {
  name = "SSMAutomationRemediationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ssm.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ssm_automation_policy" {
  name       = "ssm-automation-policy-attachment"
  roles      = [aws_iam_role.ssm_automation_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_ssm_document" "remediation_doc" {
  name          = "NewRunbook5"
  document_type = "Automation"
  content = jsonencode({
    schemaVersion = "0.3",
    description   = "Remediate OpenSSH rule via Lambda",
    assumeRole    = aws_iam_role.ssm_automation_role.arn,
    parameters    = {
      GroupId = {
        type = "String"
        description = "Security Group ID to remediate"
      }
    },
    mainSteps = [{
      name = "remediateStep",
      action = "aws:invokeLambdaFunction",
      inputs = {
        FunctionName = aws_lambda_function.remediate.function_name,
        Payload = jsonencode({ GroupId = "{{ GroupId }}" })
      }
    }]
  })
}

resource "aws_lambda_permission" "allow_ssm" {
  statement_id   = "allow-ssm-remediation-v3"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.remediate.function_name
  principal      = "ssm.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}
