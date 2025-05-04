### 1 Update and Install Dependencies

sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl

### 1.2 Disable Swap (Required by Kubernetes)

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

### 1.3 Configure Kernel Parameters for Kubernetes

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

### 1.4 Install containerd

sudo apt install -y containerd

### 1.5 Configure containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

### 1.6 Restart containerd

sudo systemctl restart containerd
sudo systemctl enable containerd

### 1.7 Add Kubernetes APT Repository

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo tee /etc/apt/trusted.gpg.d/kubernetes.asc
echo "deb https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

### 1.8 Install kubeadm, kubelet, kubectl

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

## 1.9: Initialize Kubernetes Cluster (ONLY ON MASTER NODE)

sudo kubeadm init --pod-network-cidr=192.168.0.0/16

### 2.1 Configure kubectl for the current user

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

### 2.2 print-join-command

sudo kubeadm token create --print-join-command

### 2Deploy a Pod Network (Calico)

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/calico.yaml

kubectl get nodes




