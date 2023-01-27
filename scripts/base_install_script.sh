# (Install Docker CE)
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
apt-get update -y && sudo apt-get install -y \
apt-transport-https ca-certificates curl software-properties-common gnupg2 vim strace binutils psmisc lsof
# Add Docker's official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -
# Add the Docker apt repository:
add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

# Install Docker CE
apt-get update && sudo apt-get install -y \
linux-headers-$(uname -r) \
containerd.io \
docker-ce \
docker-ce-cli
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
        },
    "storage-driver": "overlay2"
}
EOF
# Create /etc/systemd/system/docker.service.d
mkdir -p /etc/systemd/system/docker.service.d

#Start Containerd
### Containerd config
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF
systemctl enable containerd
systemctl restart containerd
# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Install kubelet kubeadm etcdctl and kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update -y
apt-get install -y kubelet=${version}-00 kubeadm=${version}-00 kubectl=${version}-00 etcd-client podman
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

#Install Crictl
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/v${cri_version}/crictl-v${cri_version}-linux-amd64.tar.gz --output crictl-v${cri_version}-linux-amd64.tar.gz
sudo tar zxvf crictl-v${cri_version}-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-v${cri_version}-linux-amd64.tar.gz

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

# install trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Install kube-bench
curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.3.1/kube-bench_0.3.1_linux_amd64.deb -o kube-bench_0.3.1_linux_amd64.deb
sudo apt install ./kube-bench_0.3.1_linux_amd64.deb -f

