resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Internet-facing ALB: HTTPS from clients, forward to the API tasks"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_security_group" "api" {
  name        = "${local.name}-api"
  description = "Fargate API tasks: accept traffic from the ALB only, reach DocumentDB only"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-api"
  }
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db"
  description = "DocumentDB: accept connections from the API security group only"
  vpc_id      = aws_vpc.this.id

  # Security groups are stateful, so responses to allowed inbound connections
  # are permitted without explicit egress rules.
  egress = []

  tags = {
    Name = "${local.name}-db"
  }
}

# ALB: clients -> ALB over HTTP/HTTPS
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet, redirected to HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# ALB -> API tasks (includes target group health checks)
resource "aws_vpc_security_group_egress_rule" "alb_to_api" {
  security_group_id            = aws_security_group.alb.id
  description                  = "API tasks"
  referenced_security_group_id = aws_security_group.api.id
  from_port                    = var.api_container_port
  to_port                      = var.api_container_port
  ip_protocol                  = "tcp"
}

# API tasks: only the ALB may connect
resource "aws_vpc_security_group_ingress_rule" "api_from_alb" {
  security_group_id            = aws_security_group.api.id
  description                  = "API port from the ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.api_container_port
  to_port                      = var.api_container_port
  ip_protocol                  = "tcp"
}

# API tasks -> DocumentDB only
resource "aws_vpc_security_group_egress_rule" "api_to_db" {
  security_group_id            = aws_security_group.api.id
  description                  = "DocumentDB"
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = local.docdb_port
  to_port                      = local.docdb_port
  ip_protocol                  = "tcp"
}

# Required to pull the image from ghcr.io and to ship logs to CloudWatch.
resource "aws_vpc_security_group_egress_rule" "api_https" {
  security_group_id = aws_security_group.api.id
  description       = "HTTPS egress for image pull and CloudWatch Logs"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "api_dns_udp" {
  security_group_id = aws_security_group.api.id
  description       = "DNS to the VPC resolver"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "api_dns_tcp" {
  security_group_id = aws_security_group.api.id
  description       = "DNS over TCP to the VPC resolver"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}

# DocumentDB: only the API security group may connect.
resource "aws_vpc_security_group_ingress_rule" "db_from_api" {
  security_group_id            = aws_security_group.db.id
  description                  = "DocumentDB from the API tasks"
  referenced_security_group_id = aws_security_group.api.id
  from_port                    = local.docdb_port
  to_port                      = local.docdb_port
  ip_protocol                  = "tcp"
}
