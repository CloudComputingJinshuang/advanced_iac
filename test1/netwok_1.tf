provider "aws" {
  region = "us-east-1"
}

locals {
  route_table_private-us-east-1a_id = "rtb-0e2ffc109e2ecdc39"
  route_table_private-us-east-1b_id = "rtb-07c847ae7ee3085f5"
  route_table_private-us-east-1c_id = "rtb-06ff7a004a796f2f9"
  route_table_public_id = "rtb-0945e09538070af59"
  cluster_vpc_id                    = "vpc-054b9b1cc70eef094"
  cluster_vpc_cidr_block            = "172.20.0.0/16"
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
  vpc_id      = local.cluster_vpc_id
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
  route_table_id = local.route_table_public_id
  destination_cidr_block = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "cluster2db1" {
  route_table_id = local.route_table_private-us-east-1a_id
  destination_cidr_block = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "cluster2db2" {
  route_table_id = local.route_table_private-us-east-1b_id
  destination_cidr_block = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "cluster2db3" {
  route_table_id = local.route_table_private-us-east-1c_id
  destination_cidr_block = aws_vpc.database_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "db2cluster" {
  route_table_id = aws_route_table.database_rt.id
  destination_cidr_block = local.cluster_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# --------------- create database ------------------

resource "aws_security_group" "rds" {
  name_prefix = "rds-"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [local.cluster_vpc_cidr_block]
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

output "db_endpoint" {
  value = aws_db_instance.RDSmySql.endpoint
}

