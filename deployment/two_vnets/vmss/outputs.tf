output "VMSS_SPN" {
  value = "${lookup(azurerm_virtual_machine_scale_set.scaleset.identity[0], "principal_id")}"
}

output "gateway_id" {
  value = "${azurerm_virtual_network_gateway.gateway.id}"
}
