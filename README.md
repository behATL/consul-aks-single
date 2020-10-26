# Consul Single AKS Learning environment

## Overview
This repo provides the infrastructure needed to build an AKS cluster with an application using Consul service mesh.
The [Terraform folder](terraform) provides simple instructions to spin up this infrastructure.

## Helm Setup
Add the Consul helm chart to your repo after you've installed [HELM](https://helm.sh/docs/helm/helm_install/)

```
helm repo add hashicorp https://helm.releases.hashicorp.com
```

## Connecting to AKS

You can use the Azure CLI to  get the credentials for each cluster.

```
az aks get-credentials --name aks1 --resource-group jwolfer-aks-single -f ./config/kube/aks1.yaml
KUBECONFIG=./config/kube/aks1.yaml kubectl config view --merge --flatten > ~/.kube/config
```

## Deploy Connect to AKS1
Our AKS1 cluster will run Grafana and Jaeger endpoints that the other AKS clusters will share.

Deploy Consul

```
kubectl config use-context aks1
kubectl create secret generic consul-gossip-encryption-key --from-literal=key="$(consul keygen)"
kubectl create secret generic consul-license --from-literal=key="<your license>"
helm install consul hashicorp/consul -f ./config/helm/helm.yaml --debug
kubectl get secret consul-federation -o yaml > consul-federation-secret.yaml
```

Deploy Monitoring

```
#helm install stable/prometheus
helm install grafana stable/grafana
kubectl apply -f grafana/grafana-service.yaml
kubectl apply -f jaeger/jaeger-all-in-one-template-modified.yml
```

## Deploy the sample application
Deploy the Fake Service application into the cluster.

```
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_ADDR=https://$(kubectl get svc consul-ui -o json | jq -r '.status.loadBalancer.ingress[0].ip')
export CONSUL_HTTP_TOKEN=$(kubectl get secret consul-bootstrap-acl-token -o json | jq -r '.data.token' | base64 -d)
consul config write config/consul/proxy-defaults.hcl
consul intention create -allow '*/*' '*/*'

kubectl apply -f apps/frontend
kubectl apply -f apps/backend
```
