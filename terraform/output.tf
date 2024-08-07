
output "vm_private_ip_addresses" {
  value = [for i in range(var.vm_count) : openstack_networking_floatingip_v2.floatingips[i].fixed_ip]
}

output "vm_public_ip_addresses" {
  value = [for i in range(var.vm_count) : openstack_networking_floatingip_v2.floatingips[i].address]
}

output "lb_public_ip_address" {
  value = openstack_networking_floatingip_v2.floatingip_lb.address
}

output "master_dns" {
  value = selectel_dbaas_postgresql_datastore_v1.datastore_1.connections["MASTER"]
}