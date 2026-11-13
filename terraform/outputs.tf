output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Subnet IDs by tier."
  value = {
    public = aws_subnet.public.id
    app    = aws_subnet.app.id
    db     = aws_subnet.db.id
  }
}

output "availability_zones" {
  description = "Availability zone used by each tier."
  value = {
    public = aws_subnet.public.availability_zone
    app    = aws_subnet.app.availability_zone
    db     = aws_subnet.db.availability_zone
  }
}

output "alb_dns_name" {
  description = "DNS name of the load balancer. Point your domain here (or use certificate_arn with a matching domain)."
  value       = aws_lb.this.dns_name
}

output "alb_https_endpoint" {
  description = "HTTPS endpoint of the load balancer (requires a certificate matching the host you call it with)."
  value       = "https://${aws_lb.this.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.api.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the API task definition."
  value       = aws_ecs_task_definition.api.arn
}

output "documentdb_endpoint" {
  description = "DocumentDB cluster endpoint."
  value       = aws_docdb_cluster.this.endpoint
}

output "documentdb_reader_endpoint" {
  description = "DocumentDB reader endpoint."
  value       = aws_docdb_cluster.this.reader_endpoint
}

output "documentdb_secret_arn" {
  description = "Secrets Manager secret containing the DocumentDB credentials and MONGO_URI."
  value       = aws_secretsmanager_secret.docdb.arn
  sensitive   = true
}
