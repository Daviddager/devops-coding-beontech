locals {
  name = "${var.project_name}-${var.environment}"

  # Ordered by tier: [0] public, [1] app, [2] db.
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  docdb_port = 27017

  # DocumentDB requires TLS. The CA bundle is baked into the container image at
  # /app/global-bundle.pem (see the Dockerfile at the repository root).
  mongo_uri = format(
    "mongodb://%s:%s@%s:%d/?tls=true&tlsCAFile=/app/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false",
    var.docdb_master_username,
    urlencode(random_password.docdb.result),
    aws_docdb_cluster.this.endpoint,
    local.docdb_port,
  )
}

check "fargate_cpu_memory" {
  assert {
    condition = contains([
      "256:512", "256:1024", "256:2048",
      "512:1024", "512:2048", "512:3072", "512:4096",
      "1024:2048", "1024:3072", "1024:4096", "1024:5120",
      "1024:6144", "1024:7168", "1024:8192",
      "2048:4096", "2048:5120", "2048:6144", "2048:7168",
      "2048:8192", "2048:9216", "2048:10240", "2048:11264",
      "2048:12288", "2048:13312", "2048:14336", "2048:15360",
      "2048:16384",
      "4096:8192", "4096:9216", "4096:10240", "4096:11264",
      "4096:12288", "4096:13312", "4096:14336", "4096:15360",
      "4096:16384", "4096:17408", "4096:18432", "4096:19456",
      "4096:20480", "4096:21504", "4096:22528", "4096:23552",
      "4096:24576", "4096:25600", "4096:26624", "4096:27648",
      "4096:28672", "4096:29696",
    ], "${var.api_cpu}:${var.api_memory}")
    error_message = "api_cpu and api_memory are not a valid Fargate CPU/memory combination."
  }
}

check "autoscaling_bounds" {
  assert {
    condition = (
      var.api_min_count >= 1 &&
      var.api_max_count >= var.api_min_count &&
      var.api_desired_count >= var.api_min_count &&
      var.api_desired_count <= var.api_max_count
    )
    error_message = "Require 1 <= api_min_count <= api_desired_count <= api_max_count."
  }
}
