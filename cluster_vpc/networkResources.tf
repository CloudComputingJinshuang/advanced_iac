# Create a VPC
resource "aws_vpc" "kubernetes_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "kubernetes_subnet_1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.kubernetes_vpc.id
}

resource "aws_subnet" "kubernetes_subnet_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.kubernetes_vpc.id
}

resource "aws_subnet" "kubernetes_subnet_3" {
  cidr_block = "10.0.3.0/24"
  vpc_id     = aws_vpc.kubernetes_vpc.id
}

# Create security group for Kubernetes API server
resource "aws_security_group" "kubernetes_api_server_sg" {
  name_prefix = "kubernetes_api_server_sg"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubernetes_api_server_sg"
  }
}

# Create security group for Kubernetes worker nodes
resource "aws_security_group" "kubernetes_worker_nodes_sg" {
  name_prefix = "kubernetes_worker_nodes_sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.kubernetes_api_server_sg.id]
  }

  tags = {
    Name = "kubernetes_worker_nodes_sg"
  }
}
