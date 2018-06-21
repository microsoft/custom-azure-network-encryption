###############################################################################
# Shared Variables
###############################################################################

# Add this application to the subscriptions' IAM with permission to create resources
variable "client_id" {
  description = "Application ID value from an Active Directory App Registration."
}

variable "client_secret" {
  description = "Secret value obtained by creating a key for the App Registration."
}

variable "tenant_id" {
  description = "Active Directory 'Directory ID' property."
}

variable "subscription_id" {
  description = "Azure Subscription Id."
}

###############################################################################
# Common Scale Set Variables
###############################################################################

variable "storage_account_tier" {
  description = "Defines the Tier of storage account to be created. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Defines the Replication Type to use for this storage account. Valid options include LRS, GRS etc."
  default     = "LRS"
}

variable "vm_sku" {
  default = "Standard_D2s_v3"
}

variable "image_sku" {
  default = "7.3"
}

variable "image_publisher" {
  description = "The name of the publisher of the image (az vm image list)"
  default     = "OpenLogic"
}

variable "image_offer" {
  description = "The name of the offer (az vm image list)"
  default     = "CentOS"
}

variable "instance_count" {
  description = "Number of VM instances (100 or less)."
  default     = "3"
}

variable "admin_username" {
  description = ""
}

variable "admin_password" {
  description = ""
}

variable "command" {
  description = ""
}

variable "files" {
  description = ""
}

###############################################################################
# Scale Set #1 Variables
###############################################################################

variable "resource_group_name_1" {
  description = "The name of the resource group in which to create the virtual network."
}

variable "location_1" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "eastus"
}

variable "vmss_prefix_1" {
  description = ""
}

variable "vnet_address_space_1" {
  type = "list"
}

variable "vnet_subnet_address_prefix_1" {}

variable "vnet_gateway_subnet_address_prefix_1" {}

###############################################################################
# Scale Set #2 Variables
###############################################################################

variable "resource_group_name_2" {
  description = "The name of the resource group in which to create the virtual network."
}

variable "location_2" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "eastus"
}

variable "vmss_prefix_2" {
  description = ""
}

variable "vnet_address_space_2" {
  type = "list"
}

variable "vnet_subnet_address_prefix_2" {}

variable "vnet_gateway_subnet_address_prefix_2" {}
