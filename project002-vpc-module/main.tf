module "my-aws-vpc" {
  source = "../modules/conan-aws-vpc"

  name       = "My VPC 1"
  cidr_block = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones   = ["us-east-2a", "us-east-2b", "us-east-2c"]
}


output vpcid {
  value = module.my-aws-vpc.vpcid
}


output "public_subnet_ids" {
  value = module.my-aws-vpc.public_subnet_ids
}
