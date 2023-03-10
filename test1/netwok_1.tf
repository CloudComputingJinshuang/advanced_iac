provider "aws" {
  region = "us-east-1"
}
#   -----------------  Create a cluster VPC ---------------------
resource "aws_vpc" "cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cluster_vpc"
  }

}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "cluster_igw" {
  vpc_id = aws_vpc.cluster_vpc.id
}

# Create subnets in the VPC
resource "aws_subnet" "cluster_subnet_1" {
  vpc_id = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.32.0/19"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "cluster_subnet_2" {
  vpc_id = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.64.0/19"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "cluster_subnet_3" {
  vpc_id = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.96.0/19"
  availability_zone = "us-east-1c"
}

# Create utility subnets in the VPC
resource "aws_subnet" "utility_subnet_1" {
  vpc_id = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.4.0/22"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "utility_subnet_2" {
  vpc_id = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.8.0/22"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "utility_subnet_3" {
  vpc_id = aws_vpc.cluster_vpc.id
  cidr_block =  "10.0.24.0/22"
  availability_zone = "us-east-1c"
}

# Create a route table for the VPC
resource "aws_route_table" "cluster_rt" {
  vpc_id = aws_vpc.cluster_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster_igw.id
  }
}

# Associate the subnets with the route table
resource "aws_route_table_association" "utility_subnet_1_assoc" {
  subnet_id = aws_subnet.utility_subnet_1.id
  route_table_id = aws_route_table.cluster_rt.id
}

resource "aws_route_table_association" "utility_subnet_2_assoc" {
  subnet_id = aws_subnet.utility_subnet_2.id
  route_table_id = aws_route_table.cluster_rt.id
}

# Associate the subnets with the route table
resource "aws_route_table_association" "utility_subnet_3_assoc" {
  subnet_id = aws_subnet.utility_subnet_3.id
  route_table_id = aws_route_table.cluster_rt.id
}



# ------------------------ create a database vpc ---------------------

# Create a VPC
resource "aws_vpc" "database_vpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "database_vpc"
  }
}

# Create subnets in the VPC
resource "aws_subnet" "database_subnet_1" {
  vpc_id = aws_vpc.database_vpc.id
  cidr_block = "192.168.1.0/24"
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id = aws_vpc.database_vpc.id
  cidr_block = "192.168.2.0/24"
}

resource "aws_subnet" "database_subnet_3" {
  vpc_id = aws_vpc.database_vpc.id
  cidr_block = "192.168.3.0/24"
  availability_zone = "us-east-1c"
}

resource "aws_subnet" "database_subnet_4" {
  vpc_id = aws_vpc.database_vpc.id
  cidr_block = "192.168.4.0/24"
  availability_zone = "us-east-1d"
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "database_igw" {
  vpc_id = aws_vpc.database_vpc.id
}

# Create a route table for the VPC
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.database_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.database_igw.id
  }
}

# Associate the subnets with the route table
resource "aws_route_table_association" "database_subnet_1_assoc" {
  subnet_id = aws_subnet.database_subnet_1.id
  route_table_id = aws_route_table.database_rt.id
}

resource "aws_route_table_association" "database_subnet_2_assoc" {
  subnet_id = aws_subnet.database_subnet_2.id
  route_table_id = aws_route_table.database_rt.id
}

# Associate the subnets with the route table
resource "aws_route_table_association" "database_subnet_3_assoc" {
  subnet_id = aws_subnet.database_subnet_3.id
  route_table_id = aws_route_table.database_rt.id
}

resource "aws_route_table_association" "database_subnet_4_assoc" {
  subnet_id = aws_subnet.database_subnet_4.id
  route_table_id = aws_route_table.database_rt.id
}

# ----------------------- vpc peering ---------------------

resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.cluster_vpc.id
  peer_vpc_id = aws_vpc.database_vpc.id
  tags = {
    Name = "vpc-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "accepter" {

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept = true

  tags = {
    Name = "accepted-peer-connection"
  }
}

resource "aws_route" "cluster2db" {
  route_table_id = aws_route_table.cluster_rt.id
  destination_cidr_block = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# resource "aws_route" "cluster2db1" {
#   route_table_id = "rtb-0cb461214a00426a9"
#   destination_cidr_block = aws_vpc.database_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }

resource "aws_route" "db2cluster" {
  route_table_id = aws_route_table.database_rt.id
  destination_cidr_block = aws_vpc.cluster_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "db2cluster1" {
  route_table_id = aws_vpc.database_vpc.main_route_table_id
  destination_cidr_block = aws_vpc.cluster_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}


# --------------- create database ------------------

resource "aws_security_group" "rds" {
  name_prefix = "rds-"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [aws_vpc.cluster_vpc.cidr_block]
  }
  # cidr_blocks = [aws_vpc.cluster_vpc.cidr_block]
  # cidr_blocks = ["0.0.0.0/0"]
  vpc_id = aws_vpc.database_vpc.id
}

# Create DB subnet group
resource "aws_db_subnet_group" "database_vpc" {
  name = "todo-subnet-group"
  subnet_ids = [
    aws_subnet.database_subnet_1.id,
    aws_subnet.database_subnet_2.id,
    aws_subnet.database_subnet_3.id,
    aws_subnet.database_subnet_4.id
  ]
}

resource "aws_db_instance" "RDSmySql" {
  identifier = "todo"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0.31"
  instance_class = "db.t2.micro"
  db_name = "todo"
  username = "root"
  password = "password"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.database_vpc.name
}



# ----------------------------- outputs---------------------------------

output "cluster_vpc_id" {
  value = aws_vpc.cluster_vpc.id
}

output "db_endpoint" {
  value = aws_db_instance.RDSmySql.endpoint
}

output "subnet1" {
  value = aws_subnet.cluster_subnet_1.id
}

output "subnet2" {
  value = aws_subnet.cluster_subnet_2.id
}

output "subnet3" {
  value = aws_subnet.cluster_subnet_3.id
}

output "utility1" {
  value = aws_subnet.utility_subnet_1.id
}

output "utility2" {
  value = aws_subnet.utility_subnet_2.id
}

output "utility3" {
  value = aws_subnet.utility_subnet_3.id
}

