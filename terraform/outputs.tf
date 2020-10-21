output "aks1_kube_config" {
  value = azurerm_kubernetes_cluster.aks1.kube_config_raw
}

