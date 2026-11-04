#!/bin/bash
set -euo pipefail

# Wersja minor Kubernetesa (repozytorium pkgs.k8s.io); aktualna: https://kubernetes.io/releases/
KUBERNETES_VERSION="${KUBERNETES_VERSION:-v1.37}"

export DEBIAN_FRONTEND=noninteractive

# swap musi być wyłączony
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# moduły jądra i sysctl wymagane przez Kubernetes
cat <<MODULES > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES
modprobe overlay
modprobe br_netfilter

cat <<SYSCTL > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
sysctl --system > /dev/null

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release

install -d -m 0755 /etc/apt/keyrings

# --- containerd (runtime kontenerów; Docker Engine nie jest już potrzebny) ---
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y containerd.io

containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
systemctl enable containerd
systemctl restart containerd
echo "containerd configured"

# --- kubeadm / kubelet / kubectl ---
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key" | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# kubelet ma używać adresu z sieci prywatnej Vagranta
NODE_IP="$(ip -4 -o addr show | awk '/ 10\.0\.0\./ {print $4}' | cut -d/ -f1 | head -1)"
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl enable kubelet
