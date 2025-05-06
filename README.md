# How-to-set-up-Kubernetes-clusters-using-Kubeadm

# Kubeadm Setup and Installation

Example: Ubuntu Server (ec2)

## Step 1: Provision EC2 Instances
### 1.1 Choose Instance Type
Select Ubuntu 22.04 LTS as the base OS.  
#### Recommended instance types:  
Control Plane Node: t3.medium (2 vCPUs, 4GB RAM) or higher.  
Worker Nodes: t3.small (2 vCPUs, 2GB RAM) or higher.  

### 1.2 Configure Security Group
Allow the following ports:

| Port | Protocol | Purpose |
|------- |--------- |------- |
22 | TCP | SSH Access
6443 | TCP | Kubernetes API Server
2379-2380 | TCP | etcd Communication
10250-10255 | TCP | Kubelet API
30000-32767 | TCP | NodePort Services


You may also allow ICMP (Ping) for debugging (optional).

### 1.3 Launch EC2 Instances
Create one master node and at least one worker node.
Assign Elastic IP to the master node (optional but recommended).


## Step 2: Prepare EC2 Instances
### 2.1 SSH into Instances
```sh
ssh -i your-key.pem ubuntu@<instance-ip>
```

### 2.2 Update and Install Dependencies
```sh
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl
```

### 2.3 Disable Swap (Required by Kubernetes)
```sh
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 2.4 Configure Kernel Parameters for Kubernetes
```sh
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
```

## Step 3: Install Container Runtime
Kubernetes supports containerd, Docker, and CRI-O. We'll use containerd.
### 3.1 Install containerd
```sh
sudo apt install -y containerd
```
### 3.2 Configure containerd
``` sh
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```
Edit /etc/containerd/config.toml and set SystemdCgroup = true:
```sh
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```
### 3.3 Restart containerd
```sh
sudo systemctl restart containerd
sudo systemctl enable containerd
```

## Step 4: Install Kubernetes Components
### 4.1 Add Kubernetes APT Repository
```sh
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo tee /etc/apt/trusted.gpg.d/kubernetes.asc
echo "deb https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
### 4.2 Install kubeadm, kubelet, kubectl
```sh
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```


## Step 5: Initialize Kubernetes Cluster (ONLY ON MASTER NODE)
### 5.0 Run the following command only on the master node:
```sh
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```
Copy and save the kubeadm join command from the output. You'll need it for worker nodes.
In case you lost it, run:
```sh
sudo kubeadm token create --print-join-command
```
### 5.1 Configure kubectl for the current user
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
5.2 Deploy a Pod Network (Calico)
```sh
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml
```
Check that nodes are ready:
```sh
kubectl get nodes
```

## Step 6: Join Worker Nodes
On each worker node, run the kubeadm join command from Step 5:
```sh
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```
Check that all nodes have joined (On master node):
```sh
kubectl get nodes
```



