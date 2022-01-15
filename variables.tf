variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = "rg-demo-westeurope-01"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "storage_account_name" {
  description = "The name of the azure storage account"
  default     = ""
}

variable "account_kind" {
  description = "The type of storage account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
  default     = "StorageV2"
}

variable "skuname" {
  description = "The SKUs supported by Microsoft Azure Storage. Valid options are Premium_LRS, Premium_ZRS, Standard_GRS, Standard_GZRS, Standard_LRS, Standard_RAGRS, Standard_RAGZRS, Standard_ZRS"
  default     = "Standard_RAGRS"
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage and StorageV2 accounts. Valid options are Hot and Cool."
  default     = "Hot"
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account"
  default     = "TLS1_2"
}

variable "allow_blob_public_access" {
  description = "Allow or disallow public access to all blobs or containers in the storage account. Defaults to `false`."
  default     = false
}

variable "assign_identity" {
  description = "Set to `true` to enable system-assigned managed identity, or `false` to disable it."
  default     = true
}

variable "soft_delete_retention" {
  description = "Number of retention days for soft delete. If set to null it will disable soft delete all together."
  type        = number
  default     = 30
}

variable "enable_advanced_threat_protection" {
  description = "Boolean flag which controls if advanced threat protection is enabled."
  default     = false
}

variable "network_rules" {
  description = "Network rules restricing access to the storage account."
  type        = any
  default     = {}
}

variable "containers_list" {
  description = "List of containers to create and their access levels. Each list item is a map with the possible keys `name`, `access_type`."
  type        = list(map(string))
  default     = []
}

variable "file_shares" {
  description = "List of fileshares to create and their quotas. Each list item is a map with the possible keys `name`, `quota`."
  type        = list(map(string))
  default     = []
}

variable "queues" {
  description = "List of tables to create. Each list item is a map with the key `name`."
  type        = list(map(string))
  default     = []
}

variable "tables" {
  description = "List of storage queues to create. Each list item is a map with the key `name`."
  type        = list(map(string))
  default     = []
}
variable "lifecycles" {
  description = "Configure Azure Storage firewalls and virtual networks"
  type        = list(object({ prefix_match = set(string), tier_to_cool_after_days = number, tier_to_archive_after_days = number, delete_after_days = number, snapshot_delete_after_days = number }))
  default     = []
}

variable "is_log_storage" {
  description = "Is this storage account created for Azure Logging and/or Azure Diagnostics storage"
  type        = bool
  default     = false
}

variable "is_dr_storage" {
  description = "Is this storage account created as an Azure Site Recovery cache"
  type        = bool
  default     = false
}

variable "create_private_endpoint" {
  description = "Create an Azure Private Endpoint for the Storage Account"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the Subnet to create the Azure Private Endpoint in"
  type        = string
  default     = ""
}

variable "private_endpoint_dns_zone_ids" {
  description = "The IDs of the private DNS zones to assosciate with the private endpoint"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
