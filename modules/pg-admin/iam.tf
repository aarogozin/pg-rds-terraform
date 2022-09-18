data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# role for ECS 
# TODO:
# Refacror role so each module have limited acces for environment resources.
resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent-${var.env}"
  role = aws_iam_role.ecs_agent.name
}


# Policy and role for esc task, so task can only get specific secret from SSM.
resource "aws_iam_role_policy" "ssm_role" {
  name = "ssm_role=${var.env}"
  role = aws_iam_role.pg_admin_task_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:Describe*",
          "ssm:Get*",
          "ssm:List*"
        ],
        "Resource" : "${aws_ssm_parameter.pg_admin_pass.arn}"
      }
    ]
  })
}


resource "aws_iam_role" "pg_admin_task_role" {
  name = "pg_admin_task_role-${var.env}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
