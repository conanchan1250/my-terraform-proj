variable "TEST_EC2_S3_ROLE_NAME" {
    type = string
    description = "Name of the IAM role for EC2 machine to access S3"
    default = "TEST_EC2_S3_READ_ONLY"
}

variable "ami" {
  default = "ami-0f924dc71d44d23e2"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "key_name" {
  default = "Az-Linux-KP"
}
