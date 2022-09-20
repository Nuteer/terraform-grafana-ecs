resource "aws_iam_role" "grafana_execution_role" {
  name = "grafana_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Environment = "Desenvolvimento"
    Name        = "grafana"
  }
}
resource "aws_iam_role" "grafana_task_role" {
  name = "grafana_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Environment = "Desenvolvimento"
    Name        = "grafana"
  }
}
data "aws_iam_policy_document" "grafana_execution" {
  statement {
    sid = "1"

    actions = [
      "ec2:*",
      "ecs:*",
      "ecr:*",
      "elasticfilesystem:*",
      "autoscaling:*",
      "elasticloadbalancing:*",
      "application-autoscaling:*",
      "logs:*",
      "tag:*",
      "resource-groups:*",
      "elasticfilesystem:*"
    ]

    resources = [
      "*"
    ]
  }
}
data "aws_iam_policy_document" "grafana_task" {
  statement {
    sid = "1"

    actions = [
      "ec2:*",
      "ecs:*",
      "ecr:*",
      "autoscaling:*",
      "elasticloadbalancing:*",
      "application-autoscaling:*",
      "logs:*",
      "tag:*",
      "resource-groups:*",
      "elasticfilesystem:*",
      "cloudwatch:List*",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
    ]

    resources = [
      "*"
    ]
  }
}
resource "aws_iam_policy" "grafana_execution" {
  name   = "grafana_execution_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.grafana_execution.json
}

resource "aws_iam_role_policy_attachment" "grafana_execution_att" {
  role       = aws_iam_role.grafana_execution_role.name
  policy_arn = aws_iam_policy.grafana_execution.arn
}

resource "aws_iam_policy" "grafana_task" {
  name   = "grafana_task_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.grafana_task.json
}
resource "aws_iam_role_policy_attachment" "grafana_task_att" {
  role       = aws_iam_role.grafana_task_role.name
  policy_arn = aws_iam_policy.grafana_task.arn
}