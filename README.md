# 🐳 Containerised Application Deployment with Terraform (AWS ECS Fargate)

## 📌 Overview

This project demonstrates how to deploy a **containerised web application** on **Amazon Web Services (AWS)** using **HashiCorp Terraform** Infrastructure as Code (IaC) with **AWS ECS Fargate**.

Terraform provisions and configures all required AWS resources automatically — including a custom VPC, Application Load Balancer, CloudFront HTTPS distribution, ECS Fargate cluster, task definitions, IAM roles, CloudWatch logging, automated ECR image push, and CPU/memory-based auto scaling — enabling repeatable and version-controlled container deployments with zero server management.

The infrastructure includes:
- Custom VPC with public subnets across 2 Availability Zones
- Application Load Balancer (ALB) with health checks
- **AWS CloudFront distribution providing free trusted HTTPS — no custom domain required**
- ECS Fargate cluster with FARGATE and FARGATE_SPOT capacity providers
- ECS task definition running Nginx via **Amazon ECR private repository**
- **Automated ECR image push via Terraform `null_resource` — no manual Docker steps**
- ECS service with desired count of 2 tasks
- Auto scaling on CPU (70%) and Memory (80%) thresholds
- IAM execution role with least-privilege permissions
- CloudWatch log group with 30-day retention
- Least-privilege security groups (ALB → ECS tasks)
- Amazon ECR private registry with vulnerability scanning and lifecycle policy

This project highlights serverless container orchestration, HTTPS via CloudFront, automated image delivery, high availability design, automated scaling, and cloud-native DevOps practices.

---

## 🏗️ Architecture

```
User Browser
     ↓ HTTPS (trusted *.cloudfront.net certificate)
AWS CloudFront Distribution
     ↓ HTTP :80 (origin request to ALB)
Application Load Balancer (ALB)
     ↓ HTTP :80 (health check: /)
┌──────────────────────────────────────────┐
│             VPC (10.0.0.0/16)            │
│                                          │
│   Public Subnet 1      Public Subnet 2   │
│   (eu-west-2a)         (eu-west-2b)      │
│   10.0.1.0/24          10.0.2.0/24       │
│        ↓                    ↓            │
│   ECS Fargate Task     ECS Fargate Task  │
│   (Nginx container)    (Nginx container) │
│        ↓                    ↓            │
│         CloudWatch Logs (/ecs/project)   │
└──────────────────────────────────────────┘
         ↕ Auto Scaling (2–6 tasks)
         CPU > 70% → Scale Out
         Memory > 80% → Scale Out
```

> 📸 **Architecture Screenshot:**
<img width="1024" height="1536" alt="image" src="https://github.com/user-attachments/assets/ea19aa13-c49b-4f3e-a257-343ab845128d" />

---

## ☁️ AWS Deployment

### Provisioned Resources

| Resource | Description |
|---|---|
| VPC | Custom network `10.0.0.0/16` with DNS hostnames enabled |
| Public Subnets (×2) | `10.0.1.0/24` and `10.0.2.0/24` across `eu-west-2a` / `eu-west-2b` |
| Internet Gateway | Routes public traffic into the VPC |
| Route Table | Directs `0.0.0.0/0` through the Internet Gateway |
| ALB Security Group | Accepts inbound HTTP (port 80) from internet |
| ECS Tasks Security Group | Accepts HTTP only from ALB security group |
| Application Load Balancer | Public-facing ALB across both public subnets |
| Target Group | IP-based target group with `/` health check |
| HTTP Listener | Forwards port 80 traffic to the target group |
| CloudFront Distribution | HTTPS termination on `*.cloudfront.net` — free trusted certificate |
| ECS Cluster | Fargate cluster with Container Insights enabled |
| Capacity Providers | 70% FARGATE / 30% FARGATE_SPOT for cost optimisation |
| ECS Task Definition | Fargate task: 512 CPU / 1024 MB, Nginx image from private ECR |
| ECS Service | Runs 2 desired tasks across both public subnets |
| IAM Execution Role | Allows ECS to pull images from ECR and write CloudWatch logs |
| CloudWatch Log Group | `/ecs/<project>` with 30-day log retention |
| Auto Scaling Target | ECS service scaling between 2 and 6 tasks |
| CPU Scaling Policy | Scales out when CPU exceeds 70% |
| Memory Scaling Policy | Scales out when Memory exceeds 80% |
| ECR Repository | Private container registry with vulnerability scanning on push |
| ECR Lifecycle Policy | Retains 10 most recent images, expires older ones automatically |
| ECR Image Push | Nginx pulled from Docker Hub and pushed to ECR automatically by Terraform |

> 📸 **AWS Console Screenshot:**
<img width="1636" height="568" alt="image" src="https://github.com/user-attachments/assets/ecf5c7d1-b245-4d6d-a5e2-bef478318da7" />

---

## 📂 Repository Structure

```
terraform-ecs-fargate/
├── version.tf             # Terraform, AWS, null, and local provider constraints
├── provider.tf            # AWS provider, region, and default tags
├── variables.tf           # Input variable definitions
├── terraform.tfvars       # Variable values (aws_region, project_name)
├── vpc.tf                 # VPC, subnets, IGW, route tables
├── security-groups.tf     # ALB (port 80 only) and ECS task security groups
├── alb.tf                 # ALB, target group, HTTP listener
├── cloudfront.tf          # CloudFront distribution — HTTPS on *.cloudfront.net
├── ecs-cluster.tf         # ECS cluster and capacity providers
├── ecs-task.tf            # IAM role, task definition, CloudWatch logs
├── ecs-services.tf        # ECS Fargate service and network config
├── autoscaling.tf         # App Auto Scaling for CPU and memory
├── ecr.tf                 # ECR repo, lifecycle policy, IAM pull, automated image push
├── outputs.tf             # CloudFront URL, ALB DNS, ECS service name, ECR outputs
└── ecr_push.cmd           # Auto-generated CMD script used by null_resource (gitignore)
```

### File Explanations

| File | Purpose |
|---|---|
| `version.tf` | Pins Terraform `>=1.14.0`, AWS `~> 5.0`, null `~> 3.0`, local `~> 2.0` |
| `provider.tf` | Configures AWS provider with region and default project tags |
| `variables.tf` | Defines `aws_region` and `project_name` input variables |
| `terraform.tfvars` | Sets `aws_region = eu-west-2` and `project_name = ecs-fargate` |
| `vpc.tf` | Creates VPC, two public subnets, IGW, and route table associations |
| `security-groups.tf` | ALB SG (port 80 only) and ECS SG (HTTP from ALB only) |
| `alb.tf` | Public ALB, IP-based target group with health checks, HTTP listener |
| `cloudfront.tf` | CloudFront distribution with free trusted HTTPS on `*.cloudfront.net` |
| `ecs-cluster.tf` | ECS cluster with Container Insights and FARGATE/FARGATE_SPOT providers |
| `ecs-task.tf` | IAM execution role, CloudWatch log group, Fargate task definition |
| `ecs-services.tf` | ECS service with 2 tasks, ALB integration, waits for ECR push |
| `autoscaling.tf` | Auto Scaling target (2–6 tasks), CPU and memory scaling policies |
| `ecr.tf` | ECR repo, lifecycle policy, IAM pull policy, automated Nginx image push |
| `outputs.tf` | Outputs CloudFront HTTPS URL, ALB DNS, ECS service name, ECR push commands |

---

## ⚙️ Terraform Design Approach

### 1️⃣ Infrastructure as Code

Terraform declaratively defines every AWS resource, enabling:
- Version-controlled infrastructure
- Repeatable deployments across environments
- Automated provisioning with no manual console steps
- Reduced human error in complex multi-resource setups

### 2️⃣ Serverless Container Orchestration with Fargate

AWS Fargate removes the need to manage EC2 instances entirely. Containers are launched directly as tasks — Fargate handles the underlying compute, patching, and scaling of the host infrastructure.

### 3️⃣ Cost Optimisation with FARGATE_SPOT

The ECS cluster is configured with a mixed capacity strategy: 70% standard FARGATE for reliability and 30% FARGATE_SPOT for cost savings, providing a balance between availability and infrastructure cost.

### 4️⃣ Automatic Scaling

The ECS service scales between a minimum of 2 and maximum of 6 tasks using two independent policies:
- **CPU scaling** — triggers when average CPU utilisation exceeds 70%
- **Memory scaling** — triggers when average memory utilisation exceeds 80%

Both policies use a 60-second scale-out cooldown and 300-second scale-in cooldown to prevent thrashing.

### 5️⃣ Least-Privilege Security Groups

Each layer only accepts traffic from the layer directly above it:
- ALB accepts HTTP from `0.0.0.0/0` (CloudFront origin requests arrive on port 80)
- ECS tasks accept HTTP only from the ALB security group
- No direct public access to containers is permitted

### 6️⃣ Observability

All container logs are streamed to CloudWatch Logs under `/ecs/<project_name>` with a 30-day retention policy, and Container Insights is enabled on the cluster for metrics and performance monitoring.

### 7️⃣ Amazon ECR Private Registry

Container images are hosted in a **private Amazon ECR repository**. The `ecr.tf` file creates the repository with automatic vulnerability scanning on every push, a lifecycle policy that retains only the 10 most recent images, and an inline IAM policy granting the ECS execution role exactly the four permissions needed to pull images. The task definition in `ecs-task.tf` references the private repository URL dynamically via a Terraform resource reference — no hardcoded URIs anywhere in the codebase.

> 📸 **ECR Repository Console Screenshot:**
<img width="1708" height="242" alt="Image" src="https://github.com/user-attachments/assets/bacf39dd-77bc-4f84-a4b5-fa8e140a74e3" />

### 8️⃣ Automated ECR Image Push

The Nginx image is pulled from Docker Hub and pushed to ECR **automatically during `terraform apply`** via a `null_resource` with a `local-exec` provisioner. A `.cmd` script file is written to disk by a `local_file` resource and executed via `cmd.exe` — this approach bypasses PowerShell pipe encoding issues that cause `400 Bad Request` errors when the ECR token is passed through a PowerShell variable or `Get-Content`. The ECS service explicitly depends on `null_resource.push_nginx_to_ecr` so tasks never start before the image exists in ECR.

> ⚠️ Docker Desktop must be running when `terraform apply` executes for the image push to succeed.

### 9️⃣ HTTPS via AWS CloudFront

HTTPS is provided by an **AWS CloudFront distribution** placed in front of the ALB. CloudFront uses its own free, fully trusted, AWS-managed certificate on a `*.cloudfront.net` domain — no custom domain, no ACM certificate request, no DNS validation, and no browser security warnings are required. CloudFront terminates HTTPS from the browser and forwards plain HTTP to the ALB on port 80 internally. The ALB security group only accepts port 80 since all public HTTPS traffic enters via CloudFront.

| Concern | Solution |
|---|---|
| Trusted HTTPS certificate | CloudFront default certificate — free, no configuration |
| No custom domain needed | Uses `*.cloudfront.net` subdomain automatically |
| No browser security warning | AWS-managed certificate is publicly trusted |
| No ACM clock skew issues | No self-signed certificate involved at all |

---

## 🚀 Deployment Instructions

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.14.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- [Docker Desktop](https://docs.docker.com/get-docker/) installed and **running** before `terraform apply`
- AWS account with ECS, EC2, IAM, CloudWatch, ECR, and **CloudFront** permissions

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/your-username/terraform-ecs-fargate.git
cd terraform-ecs-fargate
```

**2. Initialize Terraform**
```bash
terraform init
```

**3. Validate Configuration**
```bash
terraform validate
```

**4. Review Execution Plan**
```bash
terraform plan
```

**5. Apply Infrastructure**
```bash
terraform apply -auto-approve
```

> ⚠️ Docker Desktop must be running. Terraform will automatically pull Nginx from Docker Hub and push it to ECR during apply — no manual Docker commands needed.

> ⚠️ CloudFront takes **5–10 minutes** to deploy globally after `terraform apply` completes. Wait for full propagation before testing the HTTPS URL.

---

## 🔍 Terraform Deployment Output

After a successful `terraform apply`, you will see:

```
app_url                    = "https://xxxxxxxxxxxx.cloudfront.net"
cloudfront_domain          = "xxxxxxxxxxxx.cloudfront.net"
cloudfront_distribution_id = "XXXXXXXXXXXXXX"
alb_dns_name               = "ecs-fargate-alb-xxxxxxxxxxxx.eu-west-2.elb.amazonaws.com"
ecs_service_name           = "ecs-fargate-service"
vpc_id                     = "vpc-xxxxxxxxxxxxxxxxx"
public_subnet_ids          = ["subnet-xxxxxxxxx", "subnet-xxxxxxxxx"]
ecr_repository_url         = "053732977191.dkr.ecr.eu-west-2.amazonaws.com/ecs-fargate-repo"
ecr_push_commands          = <<commands to authenticate, tag and push>>
```

> 📸 **Deployment Screenshot:**
<img width="707" height="207" alt="image" src="https://github.com/user-attachments/assets/20e012ce-be44-4ffd-a626-11a74ba1c9a8" />

---

## 🌐 Application Validation

Once Terraform completes deployment and CloudFront has propagated (~5–10 minutes), copy the `app_url` from the output and open it in your browser:

```
https://xxxxxxxxxxxx.cloudfront.net
```

The Nginx container responds with the default Nginx welcome page, confirming that:
- The ECS Fargate tasks are running and healthy
- The ALB is successfully routing traffic to the containers
- The target group health checks are passing
- CloudFront is serving the application over trusted HTTPS
- No browser security warning is shown

> 📸 **App Screenshot:**
<img width="1918" height="902" alt="image" src="https://github.com/user-attachments/assets/d29c0155-b187-4ee3-847a-d67da2eb1560" />


---

## 🔒 HTTPS Validation

Navigate to **CloudFront → Distributions** in the AWS Console.

Your distribution will show:
- **Status:** `Enabled`
- **Domain name:** `xxxxxxxxxxxx.cloudfront.net`
- **Certificate:** `Default CloudFront Certificate`
- **Origin:** `ecs-fargate-alb-xxxx.eu-west-2.elb.amazonaws.com`

To confirm the redirect is working:
```bash
curl -I http://xxxxxxxxxxxx.cloudfront.net
# Expected: HTTP/2 200 or redirect to HTTPS
```
<img width="1891" height="277" alt="image" src="https://github.com/user-attachments/assets/5ecab889-0be7-476d-b5bd-ee321f616f4b" />

---

## 📊 Auto Scaling Validation

The ECS service is configured to automatically scale between **2 and 6 tasks** based on real-time resource utilisation.

Navigate to **ECS → Clusters → `ecs-fargate-cluster` → Services → `ecs-fargate-service` → Auto Scaling**

| Policy | Metric | Threshold | Scale Out Cooldown | Scale In Cooldown |
|---|---|---|---|---|
| CPU Scaling | ECS CPU Utilisation | 70% | 60 seconds | 300 seconds |
| Memory Scaling | ECS Memory Utilisation | 80% | 60 seconds | 300 seconds |

> 📸 **Auto Scaling Screenshot:**
<img width="1666" height="676" alt="image" src="https://github.com/user-attachments/assets/47b213d2-e15e-41f1-8d85-d0722455dc73" />
<img width="1917" height="576" alt="image" src="https://github.com/user-attachments/assets/c98cad02-c4f2-4382-be94-f3c49f4bcb59" />

---

## 🐳 Fargate Validation

AWS Fargate removes the need to manage any underlying EC2 instances. The ECS service runs tasks entirely on serverless compute — no servers to patch, provision, or maintain.

### ✅ Fargate Tasks Running

Navigate to **ECS → Clusters → `ecs-fargate-cluster` → Tasks tab**

Each task will show:
- **Launch type:** `FARGATE`
- **Status:** `RUNNING`
- **Platform version:** `LATEST`

> 📸 **Fargate Tasks Screenshot:**
<img width="1908" height="708" alt="image" src="https://github.com/user-attachments/assets/d5979042-ac2f-49c4-b017-6f9018c41006" />

### ✅ Fargate Capacity Providers

Navigate to **ECS → Clusters → `ecs-fargate-cluster` → Cluster configuration tab**

This confirms the mixed capacity strategy:
- `FARGATE` — weight 70 (base: 1)
- `FARGATE_SPOT` — weight 30

> 📸 **Capacity Providers Screenshot:**
<img width="1917" height="792" alt="image" src="https://github.com/user-attachments/assets/ca8b1897-f10c-4aed-a490-a559ae23b0bf" />

---

## 🔐 Security Notes

- `ecr_push.cmd` is auto-generated by Terraform during apply. Add it to `.gitignore`.
- Add the following to your `.gitignore`:
```
ecr_push.cmd
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
```
- ECS tasks are not directly accessible from the internet — they only accept traffic from the ALB security group.
- The ALB is not intended to be accessed directly — use the CloudFront `app_url` output.

---

## 📊 Infrastructure Summary

| Component | Service Used |
|---|---|
| Networking | Amazon VPC, Public Subnets, IGW, Route Tables |
| Load Balancing | AWS Application Load Balancer (ALB) |
| HTTPS / CDN | AWS CloudFront — free trusted certificate on `*.cloudfront.net` |
| Container Orchestration | AWS ECS Fargate |
| Container Registry | Amazon ECR (Private) |
| Container Image | Nginx — automatically pushed to ECR by Terraform |
| Auto Scaling | AWS Application Auto Scaling |
| IAM | ECS Task Execution Role with ECR pull policy |
| Observability | Amazon CloudWatch Logs + Container Insights |
| Infrastructure Provisioning | Terraform >= 1.14.0 |
| AWS Provider | hashicorp/aws ~> 5.0 |
| Region | eu-west-2 (London) |

---

## 🧠 Key Concepts Demonstrated

- Serverless container deployment with AWS ECS Fargate
- Mixed capacity provider strategy (FARGATE + FARGATE_SPOT)
- HTTPS via AWS CloudFront — free trusted certificate, no custom domain required
- Automated ECR image push via `null_resource` and `cmd.exe` local-exec
- Application Load Balancer with IP-based target groups and health checks
- ECS task definition with CloudWatch log configuration
- IAM execution role with least-privilege policy attachment
- CPU and memory-based auto scaling with cooldown management
- Least-privilege security group chaining (ALB → ECS tasks)
- Container Insights for cluster-level observability
- Terraform resource dependency management across multiple files
- Amazon ECR private registry with vulnerability scanning and lifecycle management
- Dynamic Terraform resource references to eliminate hardcoded image URIs
- Least-privilege inline IAM policy for private ECR image pulls
- Windows PowerShell pipe encoding workaround using `cmd.exe` script files

---

## 🏁 Project Outcomes

This project demonstrates the ability to:

- Deploy a fully serverless containerised application on AWS
- Configure ECS Fargate with mixed capacity providers for cost efficiency
- Implement trusted HTTPS using CloudFront without a custom domain
- Automate container image delivery to ECR entirely within Terraform
- Implement automatic horizontal scaling based on resource metrics
- Structure Terraform configurations logically across multiple files
- Apply cloud security best practices at the network and IAM level
- Integrate container logging with CloudWatch from infrastructure code
- Host container images privately in Amazon ECR with automated scanning
- Manage container image lifecycle and storage costs via ECR lifecycle policies
- Diagnose and resolve real-world deployment issues (503 errors, ECR auth failures)

---

## 🔮 Future Improvements

Potential enhancements:

- [x] ~~HTTPS with AWS Certificate Manager + ALB HTTPS listener~~ ✅ Completed via CloudFront
- [x] ~~Amazon ECR for private container image hosting~~ ✅ Completed
- [ ] Custom domain with Route 53 + ACM certificate on CloudFront
- [ ] Private subnets with NAT Gateway for ECS tasks
- [ ] CI/CD pipeline to build and push images with GitHub Actions
- [ ] Terraform remote state with S3 + DynamoDB locking
- [ ] CloudWatch alarms and SNS notifications for scaling events
- [ ] AWS Secrets Manager for environment variable injection

---

## 📄 Author

**Sanjog Shrestha**

---

## 📜 License

This project is intended for educational and portfolio purposes.
