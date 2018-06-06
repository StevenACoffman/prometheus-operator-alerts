# prometheus-operator-alerts
Add slack or smtp alerts to prometheus operator

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
