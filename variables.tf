variable "cluster_id" {
  type        = string
  description = "ECS Cluster ID"
}

variable "cluster_name" {
  type        = string
  description = "ECS Cluster Name"
}

variable "name" {
  type        = string
  description = "Task/Service name"
}

variable "env" {
  type        = string
  description = "Using environment"
}

variable "port" {
  type        = number
  default     = 80
  description = "Exposed port"
}

variable "cpu" {
  type        = number
  default     = 256
  description = "CPU units for task"
}

variable "memory" {
  type        = number
  default     = 512
  description = "Memory for task"
}

variable "image" {
  type        = string
  description = "ECR repository URL"
}

variable "execution_role_arn" {
  type        = string
  description = "Execution role ARN"
}

variable "task_role_arn" {
  type        = string
  description = "Task role ARN"
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Desired count of tasks. Will be applied only on start"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "security_groups" {
  type        = list(string)
  default     = null
  description = "Security_groups"
}

variable "assign_public_ip" {
  type        = bool
  default     = false
  description = "Assign public IP. If it's false, subnet_ids should for private subnets with NAT"
}

variable "lb_listener_arn" {
  type        = string
  default     = null
  description = "ALB listener ARN"
}

variable "lb_listener_priority" {
  type        = number
  default     = null
  description = "ALB priority"
}

variable "lb_rule_subdomain" {
  type        = bool
  default     = false
  description = "Create load balance rule with subdomain"
}

variable "lb_rule_path" {
  type        = bool
  default     = false
  description = "Create load balance rule with path"
}

variable "domain_names" {
  type        = list(string)
  default     = []
  description = "Domain name for service"
}

variable "assign_path" {
  type        = list(string)
  default     = null
  description = "Specific path names for service"
}

variable "additional_domain_names" {
  type        = list(string)
  default     = []
  description = "Additional domain names"
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Health check path"
}

variable "health_check_port" {
  type        = string
  default     = "traffic-port"
  description = "Health check port"
}

variable "health_check_matcher" {
  type        = string
  default     = "200"
  description = "Health check status codes"
}

variable "cloudwatch_logs_retention_period" {
  type        = number
  default     = 7
  description = "CloudWatch logs retention period"
}

variable "region" {
  type        = string
  description = "CloudWatch log region"
}

variable "environment" {
  type        = map
  description = "Environment variables"
}

variable "secure_environment" {
  type        = map
  default     = {}
  description = "Environment variables"
}

variable "tags" {
  description = "Tags"
}

variable "efs_volumes" {
  type = list(object({
    path            = string
    name            = string
    fs_id           = string
    access_point_id = string
  }))
  default     = []
  description = "EFS volumes"
}

variable "ecs_autoscale_min_instances" {
  type    = number
  default = 1
}
variable "ecs_autoscale_max_instances" {
  type    = number
  default = 5
}

variable "launch_type" {
  type    = string
  default = "FARGATE"
}