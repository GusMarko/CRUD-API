
data "aws_dynamodb_table" "comments" {
  name = "comments-${var.env}"
}

data "aws_ssm_parameter" "priv_sub_id" {
  name = "/vpc/${var.env}/private_subnet/id"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/vpc/${var.env}/id"
}

resource "aws_lambda_function" "main" {
  function_name = "comments-api-${var.env}"
  role          = aws_iam_role.main.arn
  memory_size   = 128
  timeout       = 3
  package_type  = "Image"
  image_uri     = var.image_uri

  environment {
    variables = {
      dbtablename = data.aws_dynamodb_table.comments.id
    }
  }

  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.priv_sub_id.value]
    security_group_ids = [aws_security_group.main.id]
  }

}

resource "aws_security_group" "main" {

  name        = "comments-${var.env}"
  description = "Security groupd for comments lambda"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      description      = "Allow all egress"
      self             = false
    }
  ]
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "main" {

  name               = "comments-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json

}


resource "aws_iam_role_policy_attachment" "vpc_policy_for_lambda" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" #AWS predefined policy
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTable",
    ]
    resources = [data.aws_dynamodb_table.comments.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name   = "comments-dynamodb-access-${var.env}"
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}
