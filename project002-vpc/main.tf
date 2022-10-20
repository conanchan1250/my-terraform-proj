// This will the following as in the default VPC
// - VPC
//   - default Route tables
//   - default Network ACL
//   - default Security group
// - 6 subnets, 3 private, 3 public
// - 1 Internet gateway
// - 1 Second Route tables using Internet gateway

// Step 1: create VPC
//   When a VPC is created, the following is also created
//   - a default Route table (without Internet Gateway) 
//   - a default Network ACL is created.
//   - a default Security group
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Test VPC"
  }
}


// Step 2: add subnets

// Note, require to have same number of subnets and zones 
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${count.index + 1}",
    Tier = "Public"
  }
}

// Note, require to have same number of subnets and zones 
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}",
    Tier = "Private"
  }
}


// Step 3: add Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Test VPC IG"
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
    Name = "Route Table for Public"
  }
}

// Step 5: Add public subnet to the second routing table
resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.second_rt.id
}