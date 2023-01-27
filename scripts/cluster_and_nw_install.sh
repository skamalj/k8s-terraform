# Initialize cluster with master node
echo "Executing: kubeadm init --apiserver-advertise-address=0.0.0.0 --apiserver-cert-extra-sans=${cluster_endpoint} --kubernetes-version=${version} --pod-network-cidr ${pod_cidr} --service-cidr=${service_cidr}"  >> /var/log/kubeadm-init.log
kubeadm init --apiserver-advertise-address=0.0.0.0 --apiserver-cert-extra-sans=${cluster_endpoint} --kubernetes-version=${version} --pod-network-cidr ${pod_cidr} --service-cidr=${service_cidr} >> /var/log/kubeadm-init.log 2>&1
# Deploy kube network
echo  "Executing: KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f ${cni_provider}"
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f ${cni_provider}  >> /var/log/kubeadm-init.log  2>&1
# Remove taint from master
KUBECONFIG=/etc/kubernetes/admin.conf kubectl taint nodes --all node-role.kubernetes.io/master-  >> /var/log/kubeadm-init.log 2>&1
# Print Join command 
KUBECONFIG=/etc/kubernetes/admin.conf kubeadm token create --print-join-command --ttl 0 >> /var/log/kubeadm-init.log 2>&1
echo ======Cluster Deployed, now execute --as sudo-- join command \(listed above\) on worker node========= >> /var/log/kubeadm-init.log