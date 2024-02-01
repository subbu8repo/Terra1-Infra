terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
  }
}

module "module_uat" {
    source = "./modules"
    prefix = "uat"
    vnet_cidr_prefix = "10.20.0.0/16"
    subnet1_cidr_prefix = "10.20.1.0/24"
    RGname = "uat-RG2"
    subnet = "uatSubnet"
}