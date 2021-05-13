provider "azurerm" {
  version = "=2.0.0"
  features {}
}
#Comment line 5/13 workshop

resource "azurerm_resource_group" "hashicorp-consul-pov" {
  name     = var.resource_group
  location = var.region
  tags = {
    owner = "Bryce Harvey"
    se-region = "South Strategic"
    purpose = "demonstration and testing"
    ttl = "-1"
    terraform = "true"
    }
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
    owner = "Bryce Harvey"
    se-region = "South Strategic"
    purpose = "demonstration and testing"
    ttl = "-1"
    terraform = "true"
  }
}