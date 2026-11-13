terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local state is used for this exercise. To move to remote state, configure
  # an S3 backend and run `terraform init -migrate-state`. `use_lockfile`
  # requires Terraform >= 1.10; on older versions use `dynamodb_table`.
  #
  # backend "s3" {
  #   bucket       = "my-terraform-state"
  #   key          = "beontech/dev/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
