#!/bin/bash
set -e

K8S_MINOR="1.33"
K8S_PATCH="1.33.2-1.1"

echo "👉 Désactivation du swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "👉 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "👉 Installation de containerd..."
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "👉 Activation des modules noyau et paramètres réseau..."
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

echo "👉 Ajout du dépôt Kubernetes pour v${K8S_MINOR}..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "👉 Installation de kubelet, kubeadm et kubectl version ${K8S_PATCH}..."
sudo apt update
sudo apt install -y kubelet=${K8S_PATCH} kubeadm=${K8S_PATCH} kubectl=${K8S_PATCH}
sudo apt-mark hold kubelet kubeadm kubectl

echo "✅ Kubernetes v${K8S_PATCH} installé avec succès"
