################################################################################
# General AWS Configuration
################################################################################

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "148761670084"
}

variable "aws_region" {
  description = "AWS Region used for deployments"
  type        = string
  default     = "us-east-2"
}

variable "main_region" {
  description = "Primary region for VPC and global resources"
  type        = string
  default     = "us-east-2"
}

################################################################################
# Environment and Tagging
################################################################################

variable "env_name" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    product   = "fintech-app"
    ManagedBy = "terraform"
  }
}

################################################################################
# EKS Cluster Configuration
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "prod-dominion-cluster"
}

variable "rolearn" {
  description = "IAM role ARN to be added to the aws-auth configmap as admin"
  type        = string
  default     = "arn:aws:iam::148761670084:user/Azong"
}


################################################################################
# EC2 / Client Node Configuration
################################################################################

variable "ami_id" {
  description = "AMI ID for client nodes (leave empty to auto-fetch latest Ubuntu)"
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
}

variable "instance_type" {
  description = "Instance type for EC2-based client nodes"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "azongkey02"
}

################################################################################
# Certificate Manager (ACM) & Route 53
################################################################################

# -------------------------------------------
# ACM Certificate
# -------------------------------------------
resource "aws_acm_certificate" "azongtech_cert" {
  domain_name               = "azongtech.org"
  validation_method         = "DNS"
  subject_alternative_names = ["*.azongtech.org"] # optional wildcard

  tags = {
    Environment = "prod"
  }
}

# -------------------------------------------
# DNS Validation Records in Route 53
# -------------------------------------------
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.azongtech_cert.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = "Z04206282XXO0JKCL1N69" # Replace with your actual hosted zone ID
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 300
  records = [each.value.resource_record_value]
}

# -------------------------------------------
# Validate the ACM Certificate
# -------------------------------------------
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.azongtech_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}




################################################################################
# ECR Repositories
################################################################################

variable "repositories" {
  description = "List of ECR repositories to create"
  type        = list(string)
  default     = ["fintech-app", "gateway"]
}

################################################################################
# Kubernetes Namespaces (for add-ons or app grouping)
################################################################################

variable "namespaces" {
  description = "Kubernetes namespace configurations with annotations and labels"
  type = map(object({
    annotations = map(string)
    labels      = map(string)
  }))
  default = {
    fintech = {
      annotations = {
        name = "fintech"
      }
      labels = {
        app = "webapp"
      }
    },
    monitoring = {
      annotations = {
        name = "monitoring"
      }
      labels = {
        app = "webapp"
      }
    }
  }
}
