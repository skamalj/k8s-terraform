# Terraform template to create k8s cluster on GCP as per CKS course killer.sh

This repository contains terraform code and associated scripts to create k8s cluster on GCP.  It creates following resources:-

* VPC Network
* Associated Subnet
* Firewall
* Master Node
* "N" number of worker nodes
* "gvisor" based worked node
* Create any cluster version supported on Ubuntu18 (OS is still hardcoded)
* Cluster endpoint is exposed on public IP as well in case you need to work on personal machine. Copy the kubeconfig 
from master to local and change the serverIP to public IP of master.  This IP is printed by terraform on completion.

## Following variables can be passed

* GCP Project name
* Cloud region for cluster creation
* Service and POD CIDR's
* Network plugin - calico and weavenet
* kubernetes version

## Pre-requisite

> I have tested it on Ubuntu22 desktop, if anybody tests it on windows let me know. I will update
> Have a GCP account and log in to it. Whichever account below comand is using will be used by the terraform (projects can be different)

<pre>
gcloud compute instances list
</pre>

## Usage

> Create cluster without gvisor

<pre>
terraform init
terraform apply -var="gcp_project=<yourprojectid>" -auto-approve
</pre>

> Then login to master and wait for install to finish (takes about 1-2 mins). Last of the the log will state deployment completed.

<pre>
gcloud compute ssh k8s-master
cat /var/log/kubeadm-init.log
</pre>

> Copy kubeadm join command from the log and execute it on worker nodes (and gvisor node if created)
> On worker node (remeber sudo)

<pre>
sudo kubeadm join 10.1.0.4:6443 --token xxxxxxxxxxxxxxxxxx \
    --discovery-token-ca-cert-hash yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
</pre>

## Customize deployment with variables

> You can choose the flags and values based on definition in "variables.tf" file.

<pre>
terraform init
terraform   apply  -var="gvisor=y" -var="num_of_workers=2" -var="cni_provider=calico" -auto-approve
</pre>

## Creating cluster with older version for upgrade task

<pre>
terraform apply -var="k8s_version=1.18.3" -auto-approve
</pre>

## Providing inputs via file

>You can create file terraform.tfvars, place it in root directory, and provide values in it, like below

<pre>
gcp_project="yourproject"
gvisor="y"
num_of_workers=2
cni_provider="calico"
</pre>

> you can then run terraform command as below

<pre>
terraform apply -auto-approve
</pre>

## Deleting the resources

> Instead of apply use destroy command like below

<pre>
terraform destroy  -auto-approve
terraform destroy  -var="gvisor=y" -var="num_of_workers=2" -var="cni_provider=calico" -auto-approve
</pre>

## Advanced Usage

### Adding nodes after initial creation

> Below command will add 2 extra nodes after you have created initial cluster

<pre>
terraform apply -var="num_of_workers=3" -auto-approve
</pre>

> If below command is executed after the above command, it will take out 2 nodes from cluster (make sure you know what you are doing)

<pre>
terraform apply -var="num_of_workers=1" -auto-approve
</pre>

### Adding gvisor and removing it

> Add gvisor node to existing cluster

<pre>
terraform apply -var="gvisor=y" -auto-approve
</pre>

> Remove gvisor node from existing cluster (Do drain and delete node)

<pre>
terraform apply -var="gvisor=N" -auto-approve
</pre>

### Troubleshoot:  DNS lookup not working from pods
Restart coredns pods

`kubectl -n kube-system rollout restart deployment coredns`
