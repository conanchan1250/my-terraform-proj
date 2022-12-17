// Step 1: create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = var.name
  }
}


// Step 2: add subnets
// Note, require to have same number of subnets and zones 
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name} Public Subnet ${count.index + 1}",
    Tier = "Public"
  }
}
// Note, require to have same number of subnets and zones 
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "${var.name} Private Subnet ${count.index + 1}",
    Tier = "Private"
  }
}


// Step 3: add Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name} IG"
  }
}

// Step 4: create second routing table using Internet gateway
// Reason: default route table was created without Internet gateway.. Therefore nothing can reach internet.  
resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route Table for ${var.name}"
  }
}

// Step 5: Add public subnet to the second routing table
resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.second_rt.id
}


output vpcid {
  value = aws_vpc.main.id
}

output public_subnet_ids {
  value = aws_subnet.public_subnets[*].id
}

output private_subnet_ids {
  value = aws_subnet.private_subnets[*].id
}
