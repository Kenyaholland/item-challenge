variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "table_name" {
  type = string
  default = "ExamItems"
}

variable "lambda_name" {
  type = string
  default = "exam-api"
}

variable "log_group_name" {
  type  = string
  default = "example-log-group"
}