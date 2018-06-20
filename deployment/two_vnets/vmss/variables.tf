variable "resource_group_name" {
  description = "The name of the resource group in which to create the virtual network."
}

variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "storage_account_tier" {
  description = "Defines the Tier of storage account to be created. Valid options are Standard and Premium."
}

variable "storage_replication_type" {
  description = "Defines the Replication Type to use for this storage account. Valid options include LRS, GRS etc."
}

variable "vmss_prefix" {
  description = "Prefix used for VMs in VM Scale Set"
}

variable "vm_sku" {
  description = "VMs sku."
}

variable "image_sku" {
  description = "VM sku image version."
}

variable "image_publisher" {
  description = "The name of the publisher of the image (az vm image list)"
}

variable "image_offer" {
  description = "The name of the offer (az vm image list)"
}

variable "instance_count" {
  description = "Number of VM instances (100 or less)."
}

variable "admin_username" {
  description = "Administrator username."
}

variable "admin_password" {
  description = "Administrator password."
}

variable "command" {
  description = "Startup command for custom script extension."
}

variable "files" {
  description = "List of files to upload to the VM."
}

variable "vnet_address_space" {
  description = "List of VNET address spaces."
  type        = "list"
}

variable "vnet_subnet_address_prefix" {
  description = "VNET VMSS subnet address prefix."
}

variable "vnet_gateway_subnet_address_prefix" {
  description = "VNET gateway subnet address prefix."
}
