provider "azurerm" {
  version = "=2.0.0"
  features {}
}

resource "azurerm_resource_group" "hashicorp-consul-pov" {
  name     = var.resource_group
  location = var.region
}

resource "azurerm_kubernetes_cluster" "aks1" {
  name                = "aks1"
  location            = azurerm_resource_group.hashicorp-consul-pov.location
  resource_group_name = azurerm_resource_group.hashicorp-consul-pov.name
  dns_prefix          = "aks1"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  service_principal {
   client_id     = "msi"
   client_secret = "msi"
 }

  tags = {
    Environment = "Production"
  }
}