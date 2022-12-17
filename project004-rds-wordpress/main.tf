module "main-vpc" {
  source = "../modules/conan-aws-vpc"

  name       = "My WordPress VPC"
  cidr_block = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones   = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

///////////////////////////////////////////////////////////
// Create security group for web access
resource "aws_security_group" "sg_web_access" {
  name        = var.WEB_SECURITY_GROUP_NAME
  description = var.WEB_SECURITY_GROUP_DESCRIPTION
  vpc_id      = module.main-vpc.vpcid

  ingress {
    description = "SSH from Everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from Everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    //ipv6_cidr_blocks = ["::/0"]
  }

}

///////////////////////////////////////////////////////////
// Setup RDS with MySQL
resource "aws_security_group" "sg_db_access" {
  name        = var.DB_SECURITY_GROUP_NAME
  description = var.DB_SECURITY_GROUP_DESCRIPTION
  vpc_id      = module.main-vpc.vpcid

  ingress {
    description     = "MySQL access from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web_access.id]
  }
}

resource "aws_db_subnet_group" "wpdb_subnet_group" {
  name       = "wpdb-subnet-group"
  subnet_ids = module.main-vpc.public_subnet_ids

  tags = {
    Name = "My WP DB subnet group"
  }
}

resource "aws_db_instance" "wpdb" {
  identifier             = "wpdb-1"
  allocated_storage      = 20
  db_name                = "wpdb"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t2.micro"
  username               = "dbadmin"
  password               = "dbpassword"
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.wpdb_subnet_group.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.sg_db_access.id]
}



///////////////////////////////////////////////////////////
// Create EC2 machine
data "template_file" "user_data_file" {
  template = file("./files/user-data.sh")
}

resource "aws_instance" "wordpress_vm" {
  ami                     = var.ami
  instance_type           = var.instance_type
  key_name                = var.key_name
  disable_api_stop        = false
  disable_api_termination = false
  // associate_public_ip_address  = true

  subnet_id = module.main-vpc.public_subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.sg_web_access.id]
  user_data              = base64encode(data.template_file.user_data_file.rendered)

  tags = {
    Name = "wp-1"
  }
}

output "db_name" {
  value = aws_db_instance.wpdb.name
}

output "db_endpoint" {
  value = aws_db_instance.wpdb.endpoint
}

output "vm_ip" {
  value = aws_instance.wordpress_vm.public_ip
}