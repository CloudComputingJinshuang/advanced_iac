provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "accepter"
  region = "us-east-1"
}

# ---------- database network resources in database_vpc ----------------

# Create VPC
resource "aws_vpc" "database_vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "database_vpc"
  }
}

# Create subnets
resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.database_vpc.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.database_vpc.id
  availability_zone = "us-east-1b"
}

# Create security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "rds-"
  ingress {
    from_port = 0
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.database_vpc.id
}

# Create DB subnet group
resource "aws_db_subnet_group" "database_vpc" {
  name = "todo-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}


# ---------- cluster network resources in cluster_vpc ---------------

resource "aws_vpc" "cluster_vpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "cluster-vpc"
  }
}

resource "aws_subnet" "cluster_subnet_a" {
  vpc_id     = aws_vpc.cluster_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "cluster-subnet-a"
  }
}

resource "aws_subnet" "cluster_subnet_b" {
  vpc_id     = aws_vpc.cluster_vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "cluster-subnet-b"
  }
}

resource "aws_subnet" "cluster_subnet_c" {
  vpc_id     = aws_vpc.cluster_vpc.id
  cidr_block = "192.168.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "cluster-subnet-c"
  }
}

resource "aws_security_group" "cluster_sg" {
  name_prefix = "cluster-sg"
  vpc_id = aws_vpc.cluster_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}

# --------------------- vpc peering-----------------

resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = aws_vpc.database_vpc.id
  vpc_id      = aws_vpc.cluster_vpc.id

  auto_accept = true

  tags = {
    Name = "vpc-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer_accept" {
  provider      = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  tags = {
    Name = "vpc-peering-accept"
  }
}


# ----------------------- Create RDS instance ---------------
resource "aws_db_instance" "RDSmySql" {
  identifier = "todo"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "todo"
  username = "root"
  password = "password"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.database_vpc.name
}


# -------------- outputs to create kubernete cluster ---------------------

output "cluster_vpc_id" {
  value = aws_vpc.cluster_vpc.id
}

output "subnet_1" {
  value = aws_vpc.cluster_vpc.cluster_subnet_a.id
}

output "subnet_2" {
  value = aws_vpc.cluster_vpc.cluster_subnet_b.id
}

output "subnet_3" {
  value = aws_vpc.cluster_vpc.cluster_subnet_c.id
}




