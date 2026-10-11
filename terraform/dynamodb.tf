resource "aws_dynamodb_table" "leaderboard" {
  name         = "lane_leaderboard"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute { name = "pk";           type = "S" }
  attribute { name = "sk";           type = "S" }
  attribute { name = "lane";         type = "S" }
  attribute { name = "style_points"; type = "N" }

  global_secondary_index {
    name            = "lane-points-index"
    hash_key        = "lane"
    range_key       = "style_points"
    projection_type = "ALL"
  }

  ttl { attribute_name = "ttl" enabled = true }
}
