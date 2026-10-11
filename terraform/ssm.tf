resource "aws_ssm_parameter" "db_host" {
  name  = "${local.ssm_prefix}/host"
  type  = "SecureString"
  value = aws_db_instance.postgres.address
  tags  = local.tags
}

resource "aws_ssm_parameter" "db_port" {
  name  = "${local.ssm_prefix}/port"
  type  = "SecureString"
  value = "5432"
  tags  = local.tags
}

resource "aws_ssm_parameter" "db_user" {
  name  = "${local.ssm_prefix}/username"
  type  = "SecureString"
  value = aws_db_instance.postgres.username
  tags  = local.tags
}

resource "aws_ssm_parameter" "db_password" {
  name  = "${local.ssm_prefix}/password"
  type  = "SecureString"
  value = random_password.rds.result
  tags  = local.tags
}
