# A DocumentDB subnet group requires subnets in at least two AZs, so it spans
# the app and db subnets. The primary instance is pinned to the db subnet's AZ
# below, which keeps the database in the db subnet for the default single
# instance deployment.
resource "aws_docdb_subnet_group" "this" {
  name       = "${local.name}-docdb"
  subnet_ids = [aws_subnet.app.id, aws_subnet.db.id]

  tags = {
    Name = "${local.name}-docdb"
  }
}

resource "aws_docdb_cluster_parameter_group" "this" {
  name        = "${local.name}-docdb5"
  family      = var.docdb_parameter_group_family
  description = "DocumentDB cluster parameter group with TLS enforced"

  parameter {
    name  = "tls"
    value = "enabled"
  }

  tags = {
    Name = "${local.name}-docdb"
  }
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier              = "${local.name}-docdb"
  engine                          = "docdb"
  engine_version                  = var.docdb_engine_version
  master_username                 = var.docdb_master_username
  master_password                 = random_password.docdb.result
  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  port                            = local.docdb_port

  backup_retention_period = var.docdb_backup_retention_period
  storage_encrypted       = true
  storage_type            = "standard"
  skip_final_snapshot     = var.docdb_skip_final_snapshot
  deletion_protection     = var.docdb_deletion_protection
  apply_immediately       = true

  # DocumentDB auto-assigns a third AZ and that would force a replacement.
  availability_zones = [local.azs[1], local.azs[2]]

  lifecycle {
    ignore_changes = [availability_zones]
  }

  tags = {
    Name = "${local.name}-docdb"
  }
}

resource "aws_docdb_cluster_instance" "this" {
  count = var.docdb_instance_count

  identifier         = "${local.name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.docdb_instance_class
  apply_immediately  = true
  promotion_tier     = count.index

  # The primary instance lives in the db subnet. A second instance is placed in
  # the app subnet because the subnet group only covers those two AZs.
  availability_zone = element([local.azs[2], local.azs[1]], count.index)

  tags = {
    Name = "${local.name}-docdb-${count.index}"
  }
}
