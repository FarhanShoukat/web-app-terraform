variable "environment" {
  description = "An environment name that will be prefixed to resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "The IP range (CIDR notation) for this VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The IP ranges (CIDR notations) for the public subnets in the Availability Zones"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The IP ranges (CIDR notations) for the private subnets in the Availability Zones"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}


variable "s3_bucket" {
  description = "S3 bucket from where the archive will be downloaded"
  type        = string
}

variable "archive_path" {
  description = "Path to archive to be deployed on EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type to use for EC2 instnaces"
  type        = string
  default     = "t3.medium"
}

variable "min_instances" {
  description = "Minimum number of EC2 instances that AutoScaling group can scale down to"
  type        = number
  default     = 4
}

variable "max_instances" {
  description = "Maximum number of EC2 instances that AutoScaling group can scale up to"
  type        = number
  default     = 4
}