variable "gcp_project" {
  type = string
  default = "none"
  description = "Your GCP Project"
}

variable "gcp_region" {
  type = string
  default = "us-central1"
  description = "GCP Region, zone for VMs is obtained by adding '-a' to region"
}

variable "pod_cidr" {
  type = string
  default = "10.2.0.0/16"
  description = "POD CIDR range for cluster, have not been able to make it work - clusters works just fine though"
}

variable "service_cidr" {
  type = string
  default = "10.3.0.0/16"
  description = "Service CIDR range for your cluster i.e decides your service internal IPs"
}

variable "k8s_version" {
  type = string
  default = "1.19.6"
  description = <<EOF
  Kubernetes version to use, be careful changing it, 
  as other softwares like docker / containerd etc are using hardcoded Versions
  EOF 
}

variable "cni_provider" {
  type = string
  default = "weavenet"
  description = "Allows to choose between calico and weavenet"
}

variable "num_of_workers" {
  type =  number
  default = 1
  description = "Total numbers  of workers to create, does not include gvisor node (even though it is worker)"
}

variable "gvisor" {
  type =  string
  default = "N"
  description = "Creates an extra  worker node with gvisor and container.d"
}

