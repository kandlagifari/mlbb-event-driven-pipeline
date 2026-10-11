provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

locals {
  project    = "mlbb-leaderboard"
  ssm_prefix = "/mlbb/db"
  tags       = { project = local.project }
}
