terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
  }
}

module "module_prod" {
    source = "./modules"
    prefix = "prod"
    vnet_cidr_prefix = "10.20.0.0/16"
    subnet1_cidr_prefix = "10.20.1.0/24"
    RGname = "prod-RG2"
    subnet = "prodSubnet"
}