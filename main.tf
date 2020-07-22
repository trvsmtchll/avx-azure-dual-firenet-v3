resource "random_integer" "subnet" {
  min = 1
  max = 250
}

# Create East/West Aviatrix Transit Firenet vnet
resource "aviatrix_vpc" "ew_transit_firenet" {
  cloud_type           = var.cloud_type
  account_name         = var.azure_account_name
  region               = var.region
  name                 = "East-US-ew-firenet-vnet"
  cidr                 = "10.1.0.0/16"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

# Create Egress Aviatrix Transit Firenet vnet
resource "aviatrix_vpc" "egress_transit_firenet" {
  cloud_type           = var.cloud_type
  account_name         = var.azure_account_name
  region               = var.region
  name                 = "East-US-egress-firenet-vnet"
  cidr                 = "10.2.0.0/16"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}


# Aviatrix Azure Spoke VNETs
resource "aviatrix_vpc" "azure_spoke_vnet" {
  for_each             = var.azure_spoke_params
  cloud_type           = 8
  account_name         = each.value.azure_account_name
  name                 = each.value.azure_spoke_vpc_name
  region               = each.value.azure_spoke_region
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  cidr                 = each.value.azure_spoke_vpc_cidr
}

# Aviatrix Azure Spoke Gateways
# Added HA GWs on Jul 16
resource "aviatrix_spoke_gateway" "azure_spoke_gw" {
  for_each           = var.azure_spoke_params
  cloud_type         = 8
  account_name       = each.value.azure_account_name
  gw_name            = each.value.azure_spoke_gw_name
  vpc_id             = aviatrix_vpc.azure_spoke_vnet[each.key].vpc_id
  vpc_reg            = each.value.azure_spoke_region
  gw_size            = var.azure_gw_size
  ha_gw_size         = var.azure_gw_size
  subnet             = aviatrix_vpc.azure_spoke_vnet[each.key].subnets[0].cidr
  ha_subnet          = aviatrix_vpc.azure_spoke_vnet[each.key].subnets[2].cidr
  enable_active_mesh = true
}


# Create Aviatrix East West Transit FireNet Gateway
resource "aviatrix_transit_gateway" "ew_transit_firenet_gw" {
  cloud_type             = var.cloud_type
  vpc_reg                = var.region
  vpc_id                 = aviatrix_vpc.ew_transit_firenet.vpc_id
  account_name           = aviatrix_vpc.ew_transit_firenet.account_name
  gw_name                = "EW-Transit-FireNet"
  ha_gw_size             = var.azure_gw_size
  gw_size                = var.azure_gw_size
  subnet                 = var.hpe ? cidrsubnet(aviatrix_vpc.ew_transit_firenet.cidr, 10, 4) : aviatrix_vpc.ew_transit_firenet.subnets[2].cidr
  ha_subnet              = var.hpe ? cidrsubnet(aviatrix_vpc.ew_transit_firenet.cidr, 10, 8) : aviatrix_vpc.ew_transit_firenet.subnets[3].cidr
  enable_active_mesh     = true
  enable_transit_firenet = true
  connected_transit      = true
  depends_on             = [aviatrix_vpc.ew_transit_firenet]
}

# Create East West Aviatrix Firewall Instance 1
resource "aviatrix_firewall_instance" "ew_firewall_instance_1" {
  vpc_id                 = aviatrix_vpc.ew_transit_firenet.vpc_id
  firenet_gw_name        = aviatrix_transit_gateway.ew_transit_firenet_gw.gw_name
  firewall_name          = "ew-palo-fw1"
  firewall_image         = var.fw_image
  firewall_size          = var.firewall_size
  firewall_image_version = "9.1.0"
  management_subnet      = aviatrix_vpc.ew_transit_firenet.subnets[0].cidr
  egress_subnet          = aviatrix_vpc.ew_transit_firenet.subnets[1].cidr
  username               = "avtx1234"
  depends_on             = [aviatrix_transit_gateway.ew_transit_firenet_gw]
}

# Create East West Aviatrix Firewall Instance 2
resource "aviatrix_firewall_instance" "ew_firewall_instance_2" {
  vpc_id                 = aviatrix_vpc.ew_transit_firenet.vpc_id
  firenet_gw_name        = "${aviatrix_transit_gateway.ew_transit_firenet_gw.gw_name}-hagw"
  firewall_name          = "ew-palo-fw2"
  firewall_image         = var.fw_image
  firewall_size          = var.firewall_size
  firewall_image_version = "9.1.0"
  management_subnet      = aviatrix_vpc.ew_transit_firenet.subnets[2].cidr
  egress_subnet          = aviatrix_vpc.ew_transit_firenet.subnets[3].cidr
  username               = "avtx1234"
  depends_on             = [aviatrix_transit_gateway.ew_transit_firenet_gw]
}

# Create Aviatrix Transit Firewall instance associations
resource "aviatrix_firenet" "ew_firewall_net" {
  vpc_id             = aviatrix_vpc.ew_transit_firenet.vpc_id
  inspection_enabled = true
  egress_enabled     = true

  firewall_instance_association {
    firenet_gw_name      = aviatrix_transit_gateway.ew_transit_firenet_gw.gw_name
    vendor_type          = "Generic"
    instance_id          = aviatrix_firewall_instance.ew_firewall_instance_1.instance_id
    firewall_name        = aviatrix_firewall_instance.ew_firewall_instance_1.firewall_name
    attached             = true
    lan_interface        = aviatrix_firewall_instance.ew_firewall_instance_1.lan_interface
    management_interface = aviatrix_firewall_instance.ew_firewall_instance_1.management_interface
    egress_interface     = aviatrix_firewall_instance.ew_firewall_instance_1.egress_interface
  }

  firewall_instance_association {
    firenet_gw_name      = "${aviatrix_transit_gateway.ew_transit_firenet_gw.gw_name}-hagw"
    vendor_type          = "Generic"
    instance_id          = aviatrix_firewall_instance.ew_firewall_instance_2.instance_id
    firewall_name        = aviatrix_firewall_instance.ew_firewall_instance_2.firewall_name
    attached             = true
    lan_interface        = aviatrix_firewall_instance.ew_firewall_instance_2.lan_interface
    management_interface = aviatrix_firewall_instance.ew_firewall_instance_2.management_interface
    egress_interface     = aviatrix_firewall_instance.ew_firewall_instance_2.egress_interface
  }
}

### Egress Starts Here 

# Create Aviatrix Egress Transit FireNet Gateway
resource "aviatrix_transit_gateway" "egress_transit_firenet_gw" {
  cloud_type             = var.cloud_type
  vpc_reg                = var.region
  vpc_id                 = aviatrix_vpc.egress_transit_firenet.vpc_id
  account_name           = aviatrix_vpc.egress_transit_firenet.account_name
  gw_name                = "Egress-Transit-FireNet"
  ha_gw_size             = var.azure_gw_size
  gw_size                = var.azure_gw_size
  subnet                 = var.hpe ? cidrsubnet(aviatrix_vpc.egress_transit_firenet.cidr, 10, 4) : aviatrix_vpc.egress_transit_firenet.subnets[2].cidr
  ha_subnet              = var.hpe ? cidrsubnet(aviatrix_vpc.egress_transit_firenet.cidr, 10, 8) : aviatrix_vpc.egress_transit_firenet.subnets[3].cidr
  enable_active_mesh     = true
  enable_transit_firenet = true
  connected_transit      = true
  depends_on             = [aviatrix_vpc.egress_transit_firenet]
}

# Create Egress Aviatrix Firewall Instance 1
resource "aviatrix_firewall_instance" "egress_firewall_instance_1" {
  vpc_id                 = aviatrix_vpc.egress_transit_firenet.vpc_id
  firenet_gw_name        = aviatrix_transit_gateway.egress_transit_firenet_gw.gw_name
  firewall_name          = "egress-palo-fw1"
  firewall_image         = var.fw_image
  firewall_size          = var.firewall_size
  firewall_image_version = "9.1.0"
  management_subnet      = aviatrix_vpc.egress_transit_firenet.subnets[0].cidr
  egress_subnet          = aviatrix_vpc.egress_transit_firenet.subnets[1].cidr
  username               = "avtx1234"
  depends_on             = [aviatrix_transit_gateway.egress_transit_firenet_gw]
}


# Create Egress Aviatrix Firewall Instance 2
resource "aviatrix_firewall_instance" "egress_firewall_instance_2" {
  vpc_id                 = aviatrix_vpc.egress_transit_firenet.vpc_id
  firenet_gw_name        = "${aviatrix_transit_gateway.egress_transit_firenet_gw.gw_name}-hagw"
  firewall_name          = "egress-palo-fw2"
  firewall_image         = var.fw_image
  firewall_size          = var.firewall_size
  firewall_image_version = "9.1.0"
  management_subnet      = aviatrix_vpc.egress_transit_firenet.subnets[2].cidr
  egress_subnet          = aviatrix_vpc.egress_transit_firenet.subnets[3].cidr
  username               = "avtx1234"
  depends_on             = [aviatrix_transit_gateway.egress_transit_firenet_gw]
}

# Create Egress Aviatrix Transit Firewall instance associations
resource "aviatrix_firenet" "egress_firewall_net" {
  vpc_id             = aviatrix_vpc.egress_transit_firenet.vpc_id
  inspection_enabled = true
  egress_enabled     = true

  firewall_instance_association {
    firenet_gw_name      = aviatrix_transit_gateway.egress_transit_firenet_gw.gw_name
    vendor_type          = "Generic"
    instance_id          = aviatrix_firewall_instance.egress_firewall_instance_1.instance_id
    firewall_name        = aviatrix_firewall_instance.egress_firewall_instance_1.firewall_name
    attached             = true
    lan_interface        = aviatrix_firewall_instance.egress_firewall_instance_1.lan_interface
    management_interface = aviatrix_firewall_instance.egress_firewall_instance_1.management_interface
    egress_interface     = aviatrix_firewall_instance.egress_firewall_instance_1.egress_interface
  }

  firewall_instance_association {
    firenet_gw_name      = "${aviatrix_transit_gateway.egress_transit_firenet_gw.gw_name}-hagw"
    vendor_type          = "Generic"
    instance_id          = aviatrix_firewall_instance.egress_firewall_instance_2.instance_id
    firewall_name        = aviatrix_firewall_instance.egress_firewall_instance_2.firewall_name
    attached             = true
    lan_interface        = aviatrix_firewall_instance.egress_firewall_instance_2.lan_interface
    management_interface = aviatrix_firewall_instance.egress_firewall_instance_2.management_interface
    egress_interface     = aviatrix_firewall_instance.egress_firewall_instance_2.egress_interface
  }
  
}
