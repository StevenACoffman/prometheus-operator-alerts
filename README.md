# prometheus-operator-alerts
Add slack or smtp alerts to prometheus operator

## deploy.sh

This script will use helm to install the prometheus operator and kube-prometheus charts, and configure them to send alerts to slack OR email (not both).

## generate-alert-manager-config-secret.sh

This script will replace the alert-manager secret with a revised version. Handy to iterate over solutions rapidly.

### What else?

If you install the vanilla prometheus operator and kube-prometheus, it's hard to know what all is where. It's also hard to compare it to solutions like [the non-helm prometheus operator](https://github.com/camilb/prometheus-kubernetes) or [other prometheus setups](https://github.com/kayrus/prometheus-kubernetes).

You should also know that there is work to centralize Grafana dashboards and Prometheus alerts for Kubernetes in the [monitoring-mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin) project.


```
kubectl get secret  alertmanager-kube-prometheus -o go-template='{{ index .data "alertmanager.yaml" }}' | base64 -D
```

`kubectl get configmap kube-prometheus-grafana -o yaml`
Shows grafana dashboards



```
mkdir -p default
cd default
kubectl get configmaps kube-prometheus -o go-template='{{ index .data "general.rules" }}' > general.rules

kubectl get configmap kube-prometheus-exporter-node -o go-template='{{ index .data "node.rules" }}' > node.rules

kubectl get configmaps kube-prometheus-exporter-kubernetes -o go-template='{{ index .data "kubernetes.rules" }}' > kubernetes.rules

kubectl get configmaps kube-prometheus-exporter-kubelets -o go-template='{{ index .data "kubelet.rules"}}' > kubelet.rules

kubectl get configmaps kube-prometheus-exporter-kube-state -o go-template='{{ index .data "kube-state-metrics.rules"}}' > kube-state-metrics.rules

kubectl get configmaps kube-prometheus-exporter-kube-scheduler -o go-template='{{ index .data "kube-scheduler.rules"}}' > kube-scheduler.rules

kubectl get configmaps kube-prometheus-exporter-kube-etcd -o go-template='{{ index .data "etcd3.rules"}}' > etcd3.rules

kubectl get configmaps kube-prometheus-exporter-kube-controller-manager -o go-template='{{ index .data "kube-controller-manager.rules"}}' > kube-controller-manager.rules

kubectl get configmaps kube-prometheus-alertmanager -o go-template='{{ index .data "alertmanager.rules" }}' > alertmanager.rules

kubectl get configmap  kube-prometheus-prometheus -o go-template='{{ index .data "prometheus.rules" }}' > prometheus.rules
```
