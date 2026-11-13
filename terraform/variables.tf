variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used as a prefix for all resources."
  type        = string
  default     = "beontech"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,16}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 2-18 lowercase alphanumeric/hyphen characters and start with a letter."
  }
}

variable "environment" {
  description = "Environment name used as a resource name suffix."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,4}[a-z0-9]$", var.environment))
    error_message = "environment must be 2-6 lowercase alphanumeric/hyphen characters and start with a letter."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (ALB node, AZ 1)."
  type        = string
  default     = "10.0.0.0/24"
}

variable "app_subnet_cidr" {
  description = "CIDR block for the private application subnet (ALB node + Fargate, AZ 2)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR block for the private database subnet (DocumentDB, AZ 3)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zones" {
  description = "Exactly three availability zones, ordered public, app, db. Leave empty to use the first three AZs in the region."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) == 3
    error_message = "availability_zones must be empty or contain exactly three AZs."
  }
}

variable "certificate_arn" {
  description = "ARN of an existing ACM certificate in the same region, used by the ALB HTTPS listener."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:acm:", var.certificate_arn))
    error_message = "certificate_arn must be a valid ACM certificate ARN."
  }
}

variable "image_uri" {
  description = "Container image for the API (for example ghcr.io/owner/repo:tag)."
  type        = string

  validation {
    condition     = length(var.image_uri) > 0
    error_message = "image_uri must not be empty."
  }
}

variable "api_container_port" {
  description = "Port the API container listens on."
  type        = number
  default     = 8000

  validation {
    condition     = var.api_container_port > 0 && var.api_container_port <= 65535
    error_message = "api_container_port must be a valid TCP port."
  }
}

variable "api_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.api_cpu)
    error_message = "api_cpu must be one of 256, 512, 1024, 2048, 4096."
  }
}

variable "api_memory" {
  description = "Fargate task memory in MiB. Must be a valid combination with api_cpu."
  type        = number
  default     = 1024
}

variable "api_desired_count" {
  description = "Initial number of API tasks."
  type        = number
  default     = 2
}

variable "api_min_count" {
  description = "Minimum number of API tasks."
  type        = number
  default     = 2
}

variable "api_max_count" {
  description = "Maximum number of API tasks."
  type        = number
  default     = 6
}

variable "api_cpu_target" {
  description = "Target average CPU utilization percentage for autoscaling."
  type        = number
  default     = 70
}

variable "api_memory_target" {
  description = "Target average memory utilization percentage for autoscaling."
  type        = number
  default     = 80
}

variable "mongo_db_name" {
  description = "MongoDB database name used by the API."
  type        = string
  default     = "flights"
}

variable "docdb_master_username" {
  description = "DocumentDB master username."
  type        = string
  default     = "flightsadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,62}$", var.docdb_master_username))
    error_message = "docdb_master_username must start with a letter and contain only alphanumeric characters."
  }
}

variable "docdb_instance_class" {
  description = "DocumentDB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "docdb_engine_version" {
  description = "DocumentDB engine version. Must match docdb_parameter_group_family."
  type        = string
  default     = "5.0.0"
}

variable "docdb_parameter_group_family" {
  description = "DocumentDB cluster parameter group family matching docdb_engine_version."
  type        = string
  default     = "docdb5.0"

  validation {
    condition     = can(regex("^docdb[0-9]+\\.[0-9]+$", var.docdb_parameter_group_family))
    error_message = "docdb_parameter_group_family must look like docdb5.0 or docdb8.0."
  }
}

variable "docdb_instance_count" {
  description = "Number of DocumentDB instances. The first is pinned to the DB subnet; additional replicas may land in the app subnet because the subnet group spans two AZs."
  type        = number
  default     = 1

  validation {
    condition     = var.docdb_instance_count >= 1 && var.docdb_instance_count <= 2
    error_message = "docdb_instance_count must be 1 or 2 (the subnet group only covers two AZs)."
  }
}

variable "docdb_backup_retention_period" {
  description = "Days to retain DocumentDB backups."
  type        = number
  default     = 1
}

variable "docdb_skip_final_snapshot" {
  description = "Skip the final snapshot when the cluster is destroyed (useful for exercises)."
  type        = bool
  default     = true
}

variable "docdb_deletion_protection" {
  description = "Enable DocumentDB deletion protection."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the API log group."
  type        = number
  default     = 14
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights (adds CloudWatch cost). Autoscaling does not require it."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to every resource."
  type        = map(string)
  default     = {}
}
