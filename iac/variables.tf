variable "aws_region" {
  description = "The AWS region to create things in."
}

variable "access_key" {
  description = "access key of the account"
}

variable "secret_key" {
  description = "secret key of the account"
}

variable "env" {
  description = "branch"
}

variable "tags" {
  type = map(any)
}

variable "image_uri" {
  description = "Pth to code image stored in ecr"
}

