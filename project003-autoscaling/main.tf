///////////////////////////////////////////////////////////
// setup S3 bucket for use by the EC2 machines
resource "aws_s3_bucket" "test_bucket" {
  bucket = "conan-test-20221014"
}

resource "aws_s3_bucket_public_access_block" "test_bucket_pubblock" {
  bucket = aws_s3_bucket.test_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
/*
resource "aws_s3_bucket_acl" "test_bucket_acl" {
  bucket = aws_s3_bucket.test_bucket.id
  acl    = "private"
}
*/

resource "aws_s3_object" "upload_index" {
  bucket = aws_s3_bucket.test_bucket.id
  key    = "index.txt"
  source = "./files/index.txt"
}

resource "aws_s3_object" "upload_names" {
  bucket = aws_s3_bucket.test_bucket.id
  key    = "names.csv"
  source = "./files/names.csv"
}

///////////////////////////////////////////////////////////
// create IAM profile (role)) to allow EC2 machine to read from S3
resource "aws_iam_role" "test_ec2_read_s3_role" {
  name = var.TEST_EC2_S3_ROLE_NAME

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

data "aws_iam_policy" "s3_read_only_access" {
  name = "AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "s3_read_only-attach" {
  role       = aws_iam_role.test_ec2_read_s3_role.name
  policy_arn = data.aws_iam_policy.s3_read_only_access.arn
}

// note: must associate it with an instance profile in order attach to EC2
resource "aws_iam_instance_profile" "test_role_profile" {
  name = var.TEST_EC2_S3_ROLE_NAME
  role = "${aws_iam_role.test_ec2_read_s3_role.name}"
}


///////////////////////////////////////////////////////////
// Get VPC and its public subnets
data "aws_vpc" "test_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Test VPC"]
  }
}

data "aws_subnets" "test_public_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.test_vpc.id]
  }

  tags = {
    Tier = "Public"
    //Name = "Public Subnet 1"
  }
}


///////////////////////////////////////////////////////////
// Create security group for web access
resource "aws_security_group" "test_web_access" {
  name        = "TEST_WEB_ACCESS"
  description = "Allow Basic Web access"
  vpc_id      = data.aws_vpc.test_vpc.id

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
// Create Launch Template
data "template_file" "user-data-file" {
  template = file("./files/user-data.sh")
  vars = {
    s3_bucket_name = "${aws_s3_bucket.test_bucket.id}"
  }
}

resource "aws_launch_template" "test_launch_template" {
  name                    = "TEST_LT"
  image_id                = var.ami
  instance_type           = var.instance_type
  key_name                = var.key_name
  disable_api_stop        = false
  disable_api_termination = false
  
  iam_instance_profile {
    name = aws_iam_instance_profile.test_role_profile.name
  } 
  
  vpc_security_group_ids = [aws_security_group.test_web_access.id]
  //user_data               = filebase64("./files/user-data.sh")
  user_data = base64encode(data.template_file.user-data-file.rendered)
}


///////////////////////////////////////////////////////////
// Setup Load balancer
resource "aws_lb_target_group" "test_web_tg" {
  name     = "TEST-WEB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.test_vpc.id
}


resource "aws_lb" "test_lb" {
  name               = "test-lb-tf"
  internal           = false
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.test_web_access.id]
  subnets            = data.aws_subnets.test_public_subnet.ids

  enable_deletion_protection = false
  enable_http2               = true

  access_logs {
    bucket  = ""
    prefix  = ""
    enabled = false
  }

  tags = {
    Environment = "Test"
  }
}

resource "aws_lb_listener" "lb_http_listener" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test_web_tg.id
  }
}

//////////////////////////////////////////////////////////
// Create Auto Scaling group

resource "aws_autoscaling_group" "test_my_asg" {
  name = "TEST-MY-ASG"
  //availability_zones = var.azs
  //availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  desired_capacity = 3
  max_size         = 3
  min_size         = 3

  launch_template {
    id = aws_launch_template.test_launch_template.id
    //version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.test_web_tg.arn]
  termination_policies = [
    "Default",
  ]
  vpc_zone_identifier = data.aws_subnets.test_public_subnet.ids
}


//////////////////////////////////////////
// TODO add output
output publicdns {
  value = aws_lb.test_lb.dns_name
}
