VPC USING TERRAFORM
====================
STEPS TO CREATE VPC
----------------------------------
VPC
====
my-vpc = 10.0.0.0/16

SUBNET
======= 
public-subnet =  10.0.1.0/24
private-subnet = 10.0.2.0/24

INETRNET GATEWAY
=================
igw = 10.10.11.10

ROUTE TABLE
============
public-rt = 10.0.1.0/24 =>0.0.0.0/0

INSTANCE IN PUBLIC AND PRIVATE SUBNET
====================================
webserver = 10.0.1.3/24 with route to internet by internet gateway
databaseserver= 10.0.2.3/24 with no internet

FOR UPDATION IN DATABASE SERVER WE ATTACH NAT GATEWAY
=====================================================
nat-gateway 10.0.2.0/24 with route to internet by nat gatway 0.0.0.0/0

HERE IS THE CODE FOR TERRAFORM
================================
#provider defination like AWS
provider "aws" {
  region     = "us-west-1"
  access_key = "AKIA2YFFND7RZSRK3VNZ"
  secret_key = "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"
}


#VPC RESOURCE DEFINATION

resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }
}

#PUBLIC SUBNET

resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}


#PRIVATE SUBNET

resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}





#INTERNET GATEWAY

resource "aws_internet_gateway" "vpc-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "vpc-igw"
  }
}



#ROUTE TABLE

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.my-vpc.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-igw.id
  }

    tags = {
    Name = "public-route"
  }
}


#ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "route-assoc" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route.id
}

#SECURITY GROUP

resource "aws_security_group" "vpc-sg" {
  name        = "vpc-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-sg"
  }
}


#KEY-PAIR

resource "aws_key_pair" "vpc-key" {
  key_name   = "vpc-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+G92jJZzhl4NcJydufUAaXUNVAs+txWYKc3w+eR92gOD+HJkFoZ2HksJjJlXoU6sVF+vEAO/QCQQOrNvoODqu/c+57nj/dvcMK1SjfI4cklnxfPsvT6bWWAx2m+FxBaaKL0MdI+COXI/t79LNVbIqpFryoR1FphpZwsQxE01GwZrtYw5bYaKVJ+6aWblvYNfyjQkVBJJijhHJZoWq6HqNm96ycg5DE4Gbtsf1a6yz6+LLAToBm8hCG70KNjAAuo6YsvOanzQd687HYbd3Vz4smRj6VtgU/uBKO7xAIFpWrxfzEBPkXNyxIXnFnze9C2JuGDM+L0W3LyMq/qN52QGx root@ip-172-31-11-159.us-west-1.compute.internal"

}


#EC2-INSTANCE

resource "aws_instance" "web-server" {
  ami           = "ami-0a741b782c2c8632d"
  instance_type = "t2.micro"
  key_name = aws_key_pair.vpc-key.id
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.vpc-sg.id]

  tags = {
    Name = "web-server"
  }
}

#PUBLIC IP ASSIGN NOW

resource "aws_eip" "public_ip" {
  instance = aws_instance.web-server.id
  vpc      = true
}


#EC2-INSTANCE FOR DATABASE

resource "aws_instance" "database-server" {
  ami           = "ami-0a741b782c2c8632d"
  instance_type = "t2.micro"
  key_name = aws_key_pair.vpc-key.id
  subnet_id = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.vpc-sg.id]

  tags = {
    Name = "database-server"
  }
}

#NAT GATEWAY

resource "aws_nat_gateway" "vpc-nat" {
  allocation_id = aws_eip.public_ip_nat.id
  subnet_id     = aws_subnet.public-subnet.id
}


#PUBLIC IP ASSIGN FOR NAT GATEWAY

resource "aws_eip" "public_ip_nat" {
  vpc      = true
}


#ROUTE TABLE FOR NAT GATEWAY

resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.my-vpc.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.vpc-nat.id
  }

    tags = {
    Name = "private-route"
  }
}


#ROUTE TABLE ASSOCIATION FOR PRIVATE SUBNET

resource "aws_route_table_association" "private-assoc" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-route.id
}

