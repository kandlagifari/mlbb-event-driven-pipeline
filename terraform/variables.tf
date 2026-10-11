variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "alert_email" {
  description = "Email address that receives level-up notifications"
  type        = string
}
