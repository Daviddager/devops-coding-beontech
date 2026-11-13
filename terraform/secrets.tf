resource "random_password" "docdb" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "docdb" {
  name                    = "${local.name}/docdb"
  description             = "DocumentDB credentials and MongoDB connection URI for ${local.name}"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name}-docdb"
  }
}

resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id = aws_secretsmanager_secret.docdb.id

  secret_string = jsonencode({
    username  = var.docdb_master_username
    password  = random_password.docdb.result
    MONGO_URI = local.mongo_uri
  })
}
