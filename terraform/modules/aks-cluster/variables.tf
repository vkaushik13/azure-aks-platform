variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the cluster"
  type        = string
  default     = "australiaeast"
}

variable "resource_group_name" {
  description = "Resource group for the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "environment" {
  description = "Environment name (dev/uat/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, uat, or prod."
  }
}

variable "system_node_count" {
  description = "Initial node count for system node pool"
  type        = number
  default     = 3
}

variable "system_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "system_min_count" {
  description = "Minimum node count for system pool autoscaler"
  type        = number
  default     = 2
}

variable "system_max_count" {
  description = "Maximum node count for system pool autoscaler"
  type        = number
  default     = 5
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "subnet_id" {
  description = "Subnet resource ID for AKS nodes"
  type        = string
}

variable "managed_identity_id" {
  description = "User-assigned managed identity resource ID"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.100.0.10"
}

variable "admin_group_ids" {
  description = "Azure AD group IDs for cluster admin access"
  type        = list(string)
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = []
}

variable "user_node_pools" {
  description = "Map of user node pool configurations"
  type = map(object({
    vm_size         = string
    node_count      = number
    min_count       = number
    max_count       = number
    os_disk_size_gb = number
    node_labels     = map(string)
    node_taints     = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
