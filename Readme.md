# Terraform template to create k8s cluster on GCP

This repository contains terraform code and associated scripts to create k8s cluster on GCP.  It creates following resources:-

* VPC Network
* Associated Subnet
* Master Node
* "N" number of worker nodes
* "gvisor" based worked node

## Follwing variables can be passed

* GCP Project name
* Cloud region for cluster creation
* Service and POD IO CIDR's
* Network plugin - calico and weavenet

## Usage

Create cluster without gvisor
<pre>
terraform init
terraform apply -auto-approve
</pre>

## Customize deployment with variables

You can choose the flags and values based on definition in "variables.tf" file.
Default values can be defined in terraform.tfvars.
<pre>
terraform init
terraform   apply  -var="gvisor=y" -var="num_of_workers=2" -var="cni_provider=calico" -auto-approve
</pre>

## Deleting the resources

Instead of apply use destry command like below
<pre>
terraform destroy  -auto-approve
terraform destroy  -var="gvisor=y" -var="num_of_workers=2" -var="cni_provider=calico" -auto-approve
</pre>

## Advanced Usage

### Adding nodes after initial creation

Below command will add 2 extra node after you have created initial cluster
<pre>
terraform apply -var="num_of_workers=3" -auto-approve
</pre>
If below command is executed after the above command, it will take out 2 nodes from cluster (make sure you know what you are doing)
<pre>
terraform apply -var="num_of_workers=1" -auto-approve
</pre>

### Adding gvisor and removing it

Add gvisor node to existing cluster
<pre>
terraform apply -var="gvisor=y" -auto-approve
</pre>
Remove gvisor node from existing cluster (Do drain and delete node)
<pre>
terraform apply -var="gvisor=N" -auto-approve
</pre>