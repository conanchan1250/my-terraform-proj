variable "TEST_EC2_S3_ROLE_NAME" {
    type = string
    description = "Name of the IAM role for EC2 machine to access S3"
    default = "TEST_EC2_S3_READ_ONLY"
}