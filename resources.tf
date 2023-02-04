resource "azurerm_resource_group" "rg" {
    name = "RG-LabTerra"
    location = "eastus2"
}

resource "azurerm_virtual_network" "vnet" {
    name = "VNET-Terra"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = [ "10.20.0.0/16" ]
}

resource "azurerm_subnet" "gwsub" {
    name = "GatewaySubnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.20.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
    name = "PIP"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vngw" {
  name = "VGW-Terraform"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type = "Vpn"
  vpn_type = "RouteBased"
  active_active = false
  enable_bgp = false
  sku = "VpnGw1"

  ip_configuration {
    name = "vnetGatewayConfig"
    public_ip_address_id = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.gwsub.id
  }

  vpn_client_configuration {
    address_space = [ "172.16.0.0/24" ]
    vpn_client_protocols = [ "OpenVPN" ]
    aad_tenant = "https://login.microsoftonline.com/72d7263b-25da-40d1-aefe-040dc7e089e6"
    aad_audience = "6a85bcc0-3e0b-4d98-b7d7-2efc706768f6"
    aad_issuer = "https://sts.windows.net/72d7263b-25da-40d1-aefe-040dc7e089e6/"
  }
}

resource "azurerm_subnet" "sub" {
      name = "SUB-LAN-TERRAFORM"
      resource_group_name = azurerm_resource_group.rg.name
      virtual_network_name = azurerm_virtual_network.vnet.name
      address_prefixes = [ "10.20.0.0/24" ]
}

resource "azurerm_network_interface" "vnic01" {
    name = "vnic"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.sub.id
      private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_windows_virtual_machine" "vm" {
    name = "VM-Terra01"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    size = "Standard_F2"
    admin_username = "admin.icos"
    admin_password = "icosidodecX-0"
    network_interface_ids = [ azurerm_network_interface.vnic01.id,]

    source_image_reference {
      publisher = "MicrosoftWindowsServer"
      offer = "WindowsServer"
      sku = "2016-Datacenter"
      version = "latest"
    }

    os_disk {
      storage_account_type = "Standard_LRS"
      caching = "ReadWrite"
    }
  
}