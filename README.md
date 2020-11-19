# Consul Single AKS Learning environment

## Overview
This repo provides the infrastructure needed to build a single AKS cluster with an application using Consul service mesh.
The [Terraform folder](terraform) provides simple instructions to spin up this infrastructure.

## Terraform Install
Modify the terraform/variables.tf to use the appropriate Resource Group and Region.
***IMPORTANT**: The resource group in this repo defaults to use my name in the resource group. Please change it to your own.*

Provision the AKS cluster:
```
cd terraform
terraform init
terraform apply
cd ..
```

## Helm Setup

 - Install helm. This can easily be done with a package manager.
 - Add the Consul helm chart to your repo after you've installed [HELM](https://helm.sh/docs/helm/helm_install/)

```
helm repo add hashicorp https://helm.releases.hashicorp.com
```

 - If the hashicorp repo has previously been installed, you may need to update the chart to the latest version.
```
helm repo update
helm search repo hashicorp/consul --versions
```
## Connecting to AKS

Use the Azure CLI to  get the credentials for each cluster.
***NOTE:** You will need to change the resource group in the az command to match the resource group you used.*

```
rm ./config/kube/aks1.yaml
az aks get-credentials --name aks1 --resource-group jwolfer-aks-single -f ./config/kube/aks1.yaml
KUBECONFIG=./config/kube/aks1.yaml kubectl config view --merge --flatten > ~/.kube/config
```

## Deploy Consul Connect to AKS1

**Configure Consul**
- Replace your license in the license command.
- "consul keygen" requires that the Consul binary is installed and in your path.

```
kubectl config use-context aks1
kubectl create secret generic consul-gossip-encryption-key --from-literal=key="$(consul keygen)"
kubectl create secret generic consul-license --from-literal=key="<your license>"
```
**Install Consul**
- Parameters in the helm chart can be customized first, such as the Consul Enterprise version
- All the pod configs for Jaeger rely on the Consul DC being "aks1". Don't change the Consul DC name.
- Make sure to run this from the repo root, as the path to the helm config is static.
```
helm install consul hashicorp/consul -f ./config/helm/helm.yaml --debug
```

**Add .Consul resolution to kube-dns**
```
CONSUL_DNS_IP=$(kubectl get svc consul-dns -o jsonpath='{.spec.clusterIP}')
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  consul.server: |
    consul {
           errors
           cache 30
           forward . $CONSUL_DNS_IP
    }
EOF
kubectl delete pod --namespace kube-system -l k8s-app=kube-dns
```
*Deleted DNS pods will be automatically re-created automatically by the k8s deployment, but will now use the new DNS forwarder*

## Deploy Monitoring
Our AKS1 cluster will run Grafana and Jaeger endpoints that the other AKS clusters will share.

**Install Grafana via Helm**
```
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana
```
**Install grafana and jaeger**
```
kubectl apply -f grafana/grafana-service.yaml
kubectl apply -f jaeger/jaeger-all-in-one-template-modified.yml
```

## Configure Consul
**Consul binary -> API access**
```
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_ADDR=https://$(kubectl get svc consul-ui -o json | jq -r '.status.loadBalancer.ingress[0].ip')
export CONSUL_HTTP_TOKEN=$(kubectl get secret consul-bootstrap-acl-token -o json | jq -r '.data.token' | base64 -d)
```

**Configure proxy-defaults and default allow intention**
```
consul config write config/consul/proxy-defaults.hcl
consul intention create -allow '*/*' '*/*'
```

**Get the Consul UI address**
```
echo $CONSUL_HTTP_ADDR
```

## Deploy the Fake Service application

**Deploy the Fake Service application into the cluster.**

```
kubectl apply -f apps/frontend
kubectl apply -f apps/backend
```

**Get the address of the Fake Service Web server**
- This takes a little while for the AKS load balancer to assign the public IP.
- kube shows the "EXTERNAL-IP" as "\<pending>" until it is assigned. Be patient.
```
watch kubectl get services web
```
**Access the Fake Service UI**
The UI can be accessed via:
```
echo "http://$(kubectl get svc web -o json | jq -r '.status.loadBalancer.ingress[0].ip')/ui"
```