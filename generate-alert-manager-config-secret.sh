#!/usr/bin/env bash
ENVNAME=${1:-test}
# If you wish to update the operator defined secret, you can use this.
# Intended for use after deploying

kubectl delete secret alertmanager-kube-prometheus
kubectl create secret generic alertmanager-kube-prometheus --from-file=alertmanager.yaml=${ENVNAME}/prometheus-add-alertmanager.yaml --dry-run -o yaml > ${ENVNAME}/prometheus-add-alertmanager-secret-config.yaml
kubectl apply -f ${ENVNAME}/prometheus-add-alertmanager-secret-config.yaml
kubectl label secret alertmanager-kube-prometheus app=alertmanager
kubectl label secret alertmanager-kube-prometheus alertmanager=kube-prometheus
kubectl label secret alertmanager-kube-prometheus heritage=Tiller
kubectl label secret alertmanager-kube-prometheus chart=alertmanager-0.1.2
kubectl label secret alertmanager-kube-prometheus release=kube-prometheus

# This will get recreated by the statefulset and pick up the new secret
kubectl delete pod -l alertmanager=kube-prometheus -l alertmanager=kube-prometheus
