# Terraform infrastructure

Terraform code that creates the AWS environment for the flights API:

- a VPC with **three subnets in three AZs**: public, private app, private database;
- an internet-facing **Application Load Balancer** with an HTTPS listener using an
  existing ACM certificate;
- the API on **ECS Fargate**, reachable only through the ALB;
- a **DocumentDB** cluster reachable only from the API security group;
- **Application Auto Scaling** for the ECS service based on CPU and memory.

## Architecture

```text
Internet
   │ HTTPS 443
   ▼
ALB (public subnet AZ-1 + app subnet AZ-2, ACM certificate)
   │ HTTP 8000 (ALB security group only)
   ▼
ECS Fargate service (app subnet AZ-2, 2-6 tasks)
   │ MongoDB 27017 (API security group only)
   ▼
DocumentDB cluster (db subnet AZ-3)
```

| Subnet | CIDR (default) | AZ | Routing | Contents |
| --- | --- | --- | --- | --- |
| public | 10.0.0.0/24 | AZ-1 | `0.0.0.0/0` → IGW | ALB node |
| app | 10.0.1.0/24 | AZ-2 | `0.0.0.0/0` → IGW | ALB node, Fargate tasks |
| db | 10.0.2.0/24 | AZ-3 | local only | DocumentDB |

Security groups:

| SG | Ingress | Egress |
| --- | --- | --- |
| `alb` | 80, 443 from `0.0.0.0/0` | 8000 to `api` |
| `api` | 8000 from `alb` only | 27017 to `db`, 443 to internet (image pull, logs), 53 to VPC |
| `db` | 27017 from `api` only | none |

## Caveats of the 3-subnet design

These are deliberate consequences of using one subnet per tier:

1. **The app subnet is internet-routed.** An internet-facing ALB requires at
   least two subnets in two AZs, and every attached subnet needs an IGW route.
   The ALB spans the public and app subnets. Fargate tasks get public IPs
   (`assign_public_ip`) because there is no NAT gateway, but the API security
   group only allows port 8000 from the ALB, so the tasks are not reachable
   directly.
2. **The API runs in a single AZ.** The ALB has nodes in two AZs, but all tasks
   are in the app subnet. Autoscaling adds tasks within that AZ; an AZ failure
   takes the API down. Add more app subnets if you need target-level redundancy.
3. **The DocumentDB subnet group spans the app and db AZs.** AWS requires a DB
   subnet group to cover at least two AZs. The primary instance is pinned to the
   db subnet with `availability_zone`; if `docdb_instance_count = 2`, the replica
   is placed in the app subnet. Security groups still restrict access to the API
   security group.
4. **HTTPS needs an existing ACM certificate.** No DNS records are created.
   Point a CNAME/Alias for your hostname at `alb_dns_name`, and make sure the
   certificate covers that hostname.
5. **Local state contains secrets.** The generated DocumentDB password is in the
   state file and in Secrets Manager. State is gitignored.

## Prerequisites

- Terraform >= 1.6
- AWS credentials with permissions for VPC, EC2, ELB, ECS, IAM, CloudWatch
  Logs, Secrets Manager, DocumentDB and Application Auto Scaling
- An ACM certificate in the target region
- A container image built from the repository's `Dockerfile` (the API must
  listen on `0.0.0.0:8000` and include the AWS RDS CA bundle at
  `/app/global-bundle.pem`, which the Dockerfile now does). The image must be
  publicly pullable; if the GHCR package is private, configure ECS repository
  credentials before deploying.

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit certificate_arn and image_uri

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

After apply:

```bash
terraform output alb_dns_name
terraform output documentdb_endpoint
terraform output -raw documentdb_secret_arn | xargs -I{} \
  aws secretsmanager get-secret-value --secret-id {} --query SecretString --output text
```

Point your DNS record at the ALB, then test:

```bash
curl -i https://your-hostname/
curl -i https://your-hostname/flights
```

`GET /` returns `204 No Content`, which the target group health check accepts.

## Scaling

The ECS service starts with `api_desired_count` tasks (default 2) and scales
between `api_min_count` (2) and `api_max_count` (6). Two target-tracking
policies are attached:

- `ECSServiceAverageCPUUtilization` at `api_cpu_target` (70%)
- `ECSServiceAverageMemoryUtilization` at `api_memory_target` (80%)

Both policies act on the same scalable target; AWS scales out if either threshold
is exceeded and scales in when both are below target. No Container Insights is
required for these metrics.

## Connection string

The API receives `MONGO_URI` from Secrets Manager:

```text
mongodb://<user>:<password>@<cluster-endpoint>:27017/?tls=true&tlsCAFile=/app/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

DocumentDB requires TLS and `retryWrites=false`. TLS is explicitly enabled on
the cluster parameter group (`tls = enabled`).

## Destroy

```bash
cd terraform
terraform destroy
```

With the defaults (`docdb_skip_final_snapshot = true`,
`docdb_deletion_protection = false`) destruction is clean. Note that DocumentDB
instances and the ALB are billed per hour and Fargate per task-second, so destroy
the stack when you are done.

## Cost estimate (us-east-1, defaults)

| Resource | Approx. monthly |
| --- | --- |
| Application Load Balancer + public IPv4 | ~$20 |
| 2 × Fargate tasks (0.5 vCPU / 1 GB) | ~$18 |
| DocumentDB `db.t3.medium` + storage | ~$60 |
| Secrets Manager, CloudWatch Logs | ~$1 |
| **Total** | **~$100** |

No NAT gateway is created. Public IPv4 addresses attached to Fargate tasks and
the ALB are billed hourly.
