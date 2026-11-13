data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# One subnet per tier. They intentionally live in three different AZs.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name}-public"
    Tier = "public"
  }
}

# The app subnet needs a route to the internet gateway because the
# internet-facing ALB requires every attached subnet to be internet-routable.
# Fargate tasks keep public IPs disabled at the subnet level and still receive
# one via ECS (assign_public_ip) for image pulls and CloudWatch Logs.
resource "aws_subnet" "app" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.app_subnet_cidr
  availability_zone       = local.azs[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name}-app"
    Tier = "app"
  }
}

# The database subnet has no default route: DocumentDB cannot reach the internet
# and is only reachable through the db security group.
resource "aws_subnet" "db" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.db_subnet_cidr
  availability_zone       = local.azs[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name}-db"
    Tier = "db"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name}-app"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  # No routes: local VPC traffic only.
  tags = {
    Name = "${local.name}-db"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "db" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.db.id
}
