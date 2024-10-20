# main.tf

provider "aws" {
  region = var.aws_region
}

# Retrieve available availability zones for the specified region
data "aws_availability_zones" "available" {}

# VPC Creation
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "MyVPC"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  count = 3

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1) # Public subnets start after the base CIDR
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count = 3

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4) # Private subnets start after the public subnets
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public_assoc" {
  count = 3

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id
  # Add routes for private subnets if needed (e.g., to a NAT Gateway)
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private_assoc" {
  count = 3

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
