resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${local.project}-rds/postgresql"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_db_instance" "postgres" {
  identifier        = "${local.project}-rds"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "mlbb"
  username = "mlbb_admin"
  password = random_password.rds.result

  db_subnet_group_name   = aws_db_subnet_group.public.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # security group restricts access; public subnet for demo simplicity
  skip_final_snapshot    = true
  depends_on             = [aws_cloudwatch_log_group.rds]

  tags = local.tags
}

resource "random_password" "rds" {
  length  = 32
  special = false
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "public" {
  name       = "${local.project}-subnet-group"
  subnet_ids = data.aws_subnets.public.ids
  tags       = local.tags
}

# allow port 5432 only from the processor Lambda SG
resource "aws_security_group" "rds" {
  name   = "${local.project}-rds-sg"
  vpc_id = data.aws_vpc.default.id
  tags   = local.tags

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.processor_lambda.id]
  }
}
