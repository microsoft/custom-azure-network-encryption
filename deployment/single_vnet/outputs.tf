output "VMSS SPN" {
  value = "${lookup(azurerm_virtual_machine_scale_set.scaleset.identity[0], "principal_id")}"
}