# Main VPC for the high-availability application (10.0.0.0/16)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Public subnet in AZ eu-west-2a (10.0.1.0/24)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}

# Public subnet in AZ eu-west-2b (10.0.2.0/24)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
}

# Internet gateway for outbound internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Public route table with default route to the internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Default route: all traffic to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate public subnet in eu-west-2a with the public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Associate public subnet in eu-west-2b with the public route table
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}