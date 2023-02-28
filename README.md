# advanced_iac

This is the repository for IaC

Build a aws_vpc to create RDS MySQL database for task management application

config aws account: 

export AWS_REGION=us-east-1 
export AWS_PROFILE=k8s

1. to create a network resources for database in database_vpc and for k8s cluster in cluster_vpc:

terraform init
terraform plan
terraform apply

-- remove all the resources after 

terraform destroy



