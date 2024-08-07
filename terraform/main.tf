
data "openstack_images_image_v2" "image" {
  name        = "Ubuntu 20.04 LTS 64-bit"
  most_recent = true
  visibility  = "public"
}

resource "selectel_vpc_keypair_v2" "keypair_1" {
  name       = "keypair"
  public_key = file("../.keys/the-key.pub")
  user_id    = var.service_user_uid
}

resource "openstack_networking_port_v2" "ports" {
  count      = var.vm_count
  name       = format("%s-port-%d", var.base_name, count.index + 1)
  network_id = var.radozhickij_network_id

  fixed_ip {
    subnet_id = var.radozhickij_subnet_id
  }
}

resource "openstack_blockstorage_volume_v3" "boot_volumes" {
  count                = var.vm_count
  name                 = format("%s-boot-volume-%d", var.base_name, count.index + 1)
  size                 = 5
  image_id             = data.openstack_images_image_v2.image.id
  volume_type          = "fast.ru-9a"
  availability_zone    = "ru-9a"
  enable_online_resize = true

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_blockstorage_volume_v3" "additional_volumes" {
  count                = var.vm_count
  name                 = format("%s-additional-volume-%d", var.base_name, count.index + 1)
  size                 = 7
  volume_type          = "universal.ru-9a"
  availability_zone    = "ru-9a"
  enable_online_resize = true
}

resource "openstack_compute_instance_v2" "servers" {
  count             = var.vm_count
  name              = format("%s-%d", var.base_name, count.index + 1)
  flavor_id         = "1013"
  key_pair          = selectel_vpc_keypair_v2.keypair_1.name
  availability_zone = "ru-9a"

  network {
    port = openstack_networking_port_v2.ports[count.index].id
  }

  lifecycle {
    ignore_changes = [image_id]
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.boot_volumes[count.index].id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.additional_volumes[count.index].id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = -1
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}

resource "openstack_networking_floatingip_v2" "floatingips" {
  count = var.vm_count
  pool  = "external-network"
}

resource "openstack_networking_floatingip_associate_v2" "associations" {
  count       = var.vm_count
  port_id     = openstack_networking_port_v2.ports[count.index].id
  floating_ip = openstack_networking_floatingip_v2.floatingips[count.index].address
}

resource "openstack_lb_loadbalancer_v2" "load_balancer" {
  name          = "load-balancer"
  vip_subnet_id = var.radozhickij_subnet_id
  flavor_id     = "3265f75f-01eb-456d-9088-44b813d29a60"
}

resource "openstack_lb_listener_v2" "listener" {
  name            = "listener"
  protocol        = "HTTP"
  protocol_port   = "80"
  loadbalancer_id = openstack_lb_loadbalancer_v2.load_balancer.id
  insert_headers = {
    X-Forwarded-For = "true"
  }
}

resource "openstack_networking_floatingip_v2" "floatingip_lb" {
  pool    = "external-network"
  port_id = openstack_lb_loadbalancer_v2.load_balancer.vip_port_id
}

resource "openstack_lb_pool_v2" "pool" {
  name        = "pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener.id
}

resource "openstack_lb_member_v2" "members" {
  count         = var.vm_count
  name          = format("%s-member-%d", var.base_name, count.index + 1)
  subnet_id     = var.radozhickij_subnet_id
  pool_id       = openstack_lb_pool_v2.pool.id
#  address       = openstack_networking_floatingip_v2.floatingips[count.index].fixed_ip
  address       = openstack_networking_port_v2.ports[count.index].all_fixed_ips[0]
  protocol_port = "80"
  depends_on    = [
    openstack_compute_instance_v2.servers,
    openstack_lb_pool_v2.pool,
    openstack_lb_listener_v2.listener,
    openstack_lb_loadbalancer_v2.load_balancer,
    openstack_networking_floatingip_associate_v2.associations,
    openstack_networking_floatingip_v2.floatingip_lb,
    openstack_networking_floatingip_v2.floatingips,
    openstack_networking_port_v2.ports
  ]
}

resource "openstack_lb_monitor_v2" "monitor_1" {
  name        = "monitor"
  pool_id     = openstack_lb_pool_v2.pool.id
  type        = "HTTP"
  delay       = "10"
  timeout     = "4"
  max_retries = "5"
  depends_on = [openstack_lb_member_v2.members]
}



data "selectel_dbaas_datastore_type_v1" "datastore_type_1" {
  project_id = var.selectel_radozhickij_uuid
  region     = "ru-9"
  filter {
    engine  = "postgresql"
    version = "16"
  }
}

data "selectel_dbaas_flavor_v1" "flavor_1" {
  project_id = var.selectel_radozhickij_uuid
  region     = "ru-9"
  filter {
    datastore_type_id = data.selectel_dbaas_datastore_type_v1.datastore_type_1.datastore_types[0].id
    fl_size           = "standard"
    vcpus             = 4
    ram               = 16384
    disk              = 128
    }
  }

resource "selectel_dbaas_postgresql_datastore_v1" "datastore_1" {
  name       = "datastore-1"
  project_id = var.selectel_radozhickij_uuid
  region     = "ru-9"
  type_id    = data.selectel_dbaas_datastore_type_v1.datastore_type_1.datastore_types[0].id
  subnet_id  = var.radozhickij_subnet_id
  node_count = 2
  flavor_id  = data.selectel_dbaas_flavor_v1.flavor_1.flavors[0].id
  backup_retention_days = 7
  pooler {
    mode = "transaction"
    size = 50
  }

}



resource "selectel_dbaas_user_v1" "user" {
  project_id   = var.selectel_radozhickij_uuid
  region       = "ru-9"
  datastore_id = selectel_dbaas_postgresql_datastore_v1.datastore_1.id
  name         = "hexlet"
  password     = var.app_db_password_vault
}

resource "selectel_dbaas_postgresql_database_v1" "database" {
  project_id   = var.selectel_radozhickij_uuid
  region       = "ru-9"
  datastore_id = selectel_dbaas_postgresql_datastore_v1.datastore_1.id
  owner_id     = selectel_dbaas_user_v1.user.id
  name         = "hexlet_db"
}
