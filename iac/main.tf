
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

  name        = "comments-lambda-${var.env}"
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


resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.comments_api.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api" "comments_api" {
  name        = "comments-api-${var.env}"
  description = "API for Comments Lambda function"
}

resource "aws_api_gateway_resource" "comments_resource" {
  rest_api_id = aws_api_gateway_rest_api.comments_api.id
  parent_id   = aws_api_gateway_rest_api.comments_api.root_resource_id
  path_part   = "comments-${var.env}"
}

resource "aws_api_gateway_method" "comments_method" {
  rest_api_id   = aws_api_gateway_rest_api.comments_api.id
  resource_id   = aws_api_gateway_resource.comments_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "comments_integration" {
  rest_api_id             = aws_api_gateway_rest_api.comments_api.id
  resource_id             = aws_api_gateway_resource.comments_resource.id
  http_method             = aws_api_gateway_method.comments_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}
