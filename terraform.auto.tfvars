
# Azure account name in Controller
azure_account_name = "TM-Azure"

# Transit FireNet Variables
firewall_image         = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
firewall_image_version = "9.1.0"
firewall_size          = "Standard_D3_v2"

# Azure Region 
region = "East US"

# Transit CIDRs
ew_transit_cidr     = "10.1.0.0/20"
egress_transit_cidr = "10.2.0.0/20"

# Azure GW Size
azure_gw_size = "Standard_B2ms"

# Spokes to Create Add/Remove per your requirement
azure_spoke_params = {
  azure_spoke1 = {
    azure_spoke_vpc_name = "web-ingress-xff-vnet"
    azure_spoke_vpc_cidr = "10.70.0.0/16"
    azure_spoke_gw_name  = "web-ingress-xff-spoke-gw"
    azure_spoke_region   = "East US"
    azure_region_alias   = "east-us"
    azure_account_name   = "TM-Azure"
  }
  azure_spoke2 = {
    azure_spoke_vpc_name = "shared-svcs-vnet"
    azure_spoke_vpc_cidr = "10.71.0.0/16"
    azure_spoke_gw_name  = "shared-svcs-spoke-gw"
    azure_spoke_region   = "East US"
    azure_region_alias   = "East-us"
    azure_account_name   = "TM-Azure"
  }
  azure_spoke3 = {
    azure_spoke_vpc_name = "app1-vnet"
    azure_spoke_vpc_cidr = "10.72.0.0/16"
    azure_spoke_gw_name  = "app1-spoke-gw"
    azure_spoke_region   = "East US"
    azure_region_alias   = "east-us"
    azure_account_name   = "TM-Azure"
  }
  azure_spoke4 = {
    azure_spoke_vpc_name = "app2-vnet"
    azure_spoke_vpc_cidr = "10.73.0.0/16"
    azure_spoke_gw_name  = "app2-spoke-gw"
    azure_spoke_region   = "East US"
    azure_region_alias   = "east-us"
    azure_account_name   = "TM-Azure"
  }
}