#!/bin/bash
set -euo pipefail

MASTER_IP="10.0.0.10"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
CALICO_VERSION="v3.33.0"

kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

kubeadm init \
  --apiserver-advertise-address="$MASTER_IP" \
  --apiserver-cert-extra-sans="$MASTER_IP" \
  --pod-network-cidr="$POD_CIDR" \
  --node-name "$NODENAME"

mkdir -p "$HOME/.kube"
cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Save Configs to shared /vagrant location
# For Vagrant re-runs, delete the existing configs before saving the new ones.

config_path="/vagrant/configs"

if [ -d "$config_path" ]; then
  rm -f "$config_path"/*
else
  mkdir -p "$config_path"
fi

cp -f /etc/kubernetes/admin.conf "$config_path/config"
touch "$config_path/join.sh"
chmod +x "$config_path/join.sh"

kubeadm token create --print-join-command > "$config_path/join.sh"

# Install Calico Network Plugin

kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"

# Install Metrics Server
# (kubelet w Vagrancie ma certyfikat bez SAN dla IP, stąd --kubelet-insecure-tls)

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Uwaga: Kubernetes Dashboard zostało zarchiwizowane przez projekt (następcy m.in. Headlamp),
# dlatego nie jest już instalowane.

sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
sudo cp -f /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF
