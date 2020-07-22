variable "cloud_type" {
  type = string
  default = "8"
}

variable "hpe" {
  type = bool
  default = false
}

variable "fw_image" {
  type = string
  default = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
}

variable "firewall_size" {
  type = string
  default = "Standard_D3_v2"
}

variable "username" {
  type    = string
  default = ""
}

variable "password" {
  type    = string
  default = ""
}

variable "controller_ip" {
  type    = string
  default = ""
}

variable "region" {
  default = "East US"
}

variable "azure_account_name" {
  default = ""
}

variable "ew_transit_cidr" {
  default = "10.1.0.0/20"
}

variable "egress_transit_cidr" {
  default = "10.2.0.0/20"
}

variable "azure_gw_size" {
  default = "Standard_B2ms"
}

variable "firewall_image" {
  default = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
}

variable "firewall_image_version" {
  default = "9.1.0"
}

variable "azure_spoke_params" {
  description = "Azure Spoke Parameters: azure_spoke_vpc_name, azure_spoke_subnet_cidr, azure_spoke_region, azure_region_alias, azure_account_name"
  type = map(object({
    azure_spoke_vpc_name = string
    azure_spoke_vpc_cidr = string
    azure_spoke_gw_name  = string
    azure_spoke_region   = string
    azure_region_alias   = string
    azure_account_name   = string
  }))
}