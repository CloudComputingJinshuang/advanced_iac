provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.example.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.example.id
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
  vpc_id = aws_vpc.example.id
}

# Create DB subnet group
resource "aws_db_subnet_group" "example" {
  name = "todo-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# Create RDS instance
resource "aws_db_instance" "example" {
  identifier = "todo"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "todo"
  username = "admin"
  password = "password"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.example.name
}
