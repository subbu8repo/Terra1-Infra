terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
  }
}

provider "azurerm" {
  subscription_id="bcf92cad-aa6d-4aa3-a0b4-c6bda7016ae7"
  client_id="28223dee-1940-43c5-9f34-583c413f003b"
  client_secret="qLV8Q~5t7EbqiB8Xyvlq4PKnnMUYRr67RyPJjcqE"
  tenant_id="b671838d-f099-4497-8fa4-7fba0e446bf4"
  features {}  
}

resource "azurerm_resource_group" "RG" {
  name     = "${var.RGname}"
  location = "${var.RGlocation}"
}

terraform {
  backend "azurerm" {
    resource_group_name = "${azurerm_resource_group.RG.name}"
    storage_account_name = "healthpathsstore"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-10"
  resource_group_name = "${azurerm_resource_group.RG.name}"
  location            = "${azurerm_resource_group.RG.location}"
  address_space       = ["${var.vnet_cidr_prefix}"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = "${azurerm_resource_group.RG.name}"
  address_prefixes     = ["${var.subnet1_cidr_prefix}"]
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg1"
  resource_group_name = "${azurerm_resource_group.RG.name}"
  location            = "${azurerm_resource_group.RG.location}"
}

# NOTE: this allows RDP from any network
resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  resource_group_name         = "${azurerm_resource_group.RG.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                            = "${var.prefix}-vm1"
  resource_group_name             = azurerm_resource_group.RG.name
  location                        = azurerm_resource_group.RG.location
  size                            = "Standard_B1s"
  admin_username                  = "suadmin"
  admin_password                  = "subbu@123456"
  network_interface_ids = [ azurerm_network_interface.nic1.id ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}