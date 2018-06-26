provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

module "vmss1" {
  source = "./vmss"

  resource_group_name = "${var.resource_group_name_1}"
  location            = "${var.location_1}"

  storage_account_tier     = "${var.storage_account_tier}"
  storage_replication_type = "${var.storage_replication_type}"

  vnet_address_space                 = "${var.vnet_address_space_1}"
  vnet_subnet_address_prefix         = "${var.vnet_subnet_address_prefix_1}"
  vnet_gateway_subnet_address_prefix = "${var.vnet_gateway_subnet_address_prefix_1}"

  vm_sku          = "${var.vm_sku}"
  image_sku       = "${var.image_sku}"
  image_publisher = "${var.image_publisher}"
  image_offer     = "${var.image_offer}"

  vmss_prefix    = "${var.vmss_prefix_1}"
  instance_count = "${var.instance_count}"

  admin_username = "${var.admin_username}"
  admin_password = "${var.admin_password}"
  command        = "${var.command}"
  files          = "${var.files}"
}

module "vmss2" {
  source = "./vmss"

  resource_group_name = "${var.resource_group_name_2}"
  location            = "${var.location_1}"

  storage_account_tier     = "${var.storage_account_tier}"
  storage_replication_type = "${var.storage_replication_type}"

  vnet_address_space                 = "${var.vnet_address_space_2}"
  vnet_subnet_address_prefix         = "${var.vnet_subnet_address_prefix_2}"
  vnet_gateway_subnet_address_prefix = "${var.vnet_gateway_subnet_address_prefix_2}"

  vm_sku          = "${var.vm_sku}"
  image_sku       = "${var.image_sku}"
  image_publisher = "${var.image_publisher}"
  image_offer     = "${var.image_offer}"

  vmss_prefix    = "${var.vmss_prefix_2}"
  instance_count = "${var.instance_count}"

  admin_username = "${var.admin_username}"
  admin_password = "${var.admin_password}"
  command        = "${var.command}"
  files          = "${var.files}"
}

resource "azurerm_virtual_network_gateway_connection" "vmss1-to-vmss2" {
  name                = "vmss1-to-vmss2"
  location            = "${var.location_1}"
  resource_group_name = "${var.resource_group_name_1}"

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = "${module.vmss1.gateway_id}"
  peer_virtual_network_gateway_id = "${module.vmss2.gateway_id}"

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_virtual_network_gateway_connection" "vmss2-to-vmss1" {
  name                = "vmss2-to-vmss1"
  location            = "${var.location_2}"
  resource_group_name = "${var.resource_group_name_2}"

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = "${module.vmss2.gateway_id}"
  peer_virtual_network_gateway_id = "${module.vmss1.gateway_id}"

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}
