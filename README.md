# advanced_iac

This is the repository for IaC

Build a aws_vpc to create RDS MySQL database for task management application

config aws account: 

export AWS_REGION=us-east-1 
export AWS_PROFILE=k8s

export NAME=k8s.csye6225jinshuang.me
export KOPS_STATE_STORE=s3://jin-k8s-com-state-store

1. to create a network resources for database in database_vpc and for k8s cluster in cluster_vpc:

terraform init
terraform plan
terraform apply

-- remove all the resources after 

terraform destroy

save the cluter-vpc, subnets, utility subnets info.

2. create the k8s cluster in  cluster_vpc 

######### k8s_aws

ssh-keygen -t rsa -f ~/.ssh/k8s_key -P ""

export AWS_REGION=us-east-1 
export AWS_PROFILE=k8s

export NAME=k8s.csye6225jinshuang.me
export KOPS_STATE_STORE=s3://jin-k8s-com-state-store
<!-- get from network creation -->
export VPC_ID=vpc-00c9b74d181612a19

db_endpoint = "todo.cob9le38a3hn.us-east-1.rds.amazonaws.com:3306"
mysql -h todo.cob9le38a3hn.us-east-1.rds.amazonaws.com -P 3306 -u root -p

kops create cluster \
--cloud=aws \
--master-zones=us-east-1a,us-east-1b,us-east-1c \
--zones=us-east-1a,us-east-1b,us-east-1c \
--node-count=2 \
--topology private \
--subnets=subnet-0e2dcb25834bb792d,subnet-0bb6c837809f8f394,subnet-088e60970dcc67124 \
--utility-subnets=subnet-002de0069b2fd4f06,subnet-002e707227708ac49,subnet-08e5780ebe1569988 \
--ssh-public-key ~/.ssh/k8s_key.pub \
--authorization RBAC \
--networking canal \
--node-size=t3.medium \
--master-size=t3.medium \
--out=. \
--target=terraform \
--vpc=${VPC_ID} \
${NAME}


terraform init
terraform apply

% kops create secret sshpublickey admin -i ~/.ssh/k8s_key.pub --name ${NAME}

% kops update cluster ${NAME} --yes --out=. --target=terraform 

terraform init 
terraform apply

<!-- kops export kubecfg --admin

kops validate cluster

kops update cluster ${NAME} --yes --out=. --target=terraform  -->

<!-- 

kops validate cluster

grep server ~/.kube/config -->

-------- / add bastion host / -----------

#### create the kubernetes secrete to access the cluster from bastion host:

kubectl create secret generic ssh-key-secret --from-file=id_rsa=/Users/niujinshuang/.ssh/k8s_key

kops update cluster ${NAME} --yes --out=. --target=terraform 

terraform apply

#### create the bastion host:

kops create instancegroup bastions --role Bastion --subnet utility-us-east-1c --name ${NAME}

kops update cluster ${NAME} --yes --out=. --target=terraform 

<!-- kops validate cluster -->

terraform init
terraform apply

bastion_elb_url=`aws elb --output=table describe-load-balancers|grep DNSName.\*bastion|awk '{print $4}'`

ssh -i ~/.ssh/k8s_key ubuntu@${bastion_elb_url}


<!-- ssh admin@i-0175b1819c10720a4 -->

-------- / delete resources and cluster / ------------ 

terraform destroy
kops delete cluster --name ${NAME} --yes 

<!-- Verify you have an SSH agent running. This should match whatever you built your cluster with.
ssh-add -l
If you need to add the key to your agent:
ssh-add path/to/private/key

Now you can SSH into the bastion
ssh -A admin@<bastion-ELB-address>

Where <bastion-ELB-address> is usually bastion.$clustername (bastion.example.kubernetes.cluster) unless otherwise specified -->

#### test vpc peering connection by connecting to RDS database from bastion host: 

sudo apt update
sudo apt install mysql-server
mysql -h todo.cob9le38a3hn.us-east-1.rds.amazonaws.com -P 3306 -u root -p



kubectl create secret generic ssh-key-secret --from-file=id_rsa=~/.ssh/k8s_key

kubectl create secret generic ssh-key-secret --from-file=id_rsa=/Users/niujinshuang/.ssh/k8s_key


---------- / add init container / -----------

kubectl apply -f init2.yml
kubectl logs myapp-pod -c schema-migration

kubectl delete -f init2.yml


<!-- test with flayway image:  -->


sudo apt update

sudo apt install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null