variable "WEB_SECURITY_GROUP_NAME" {
  type        = string
  description = "Name of the security group for web access"
  default     = "WP_WEB_ACCESS"
}

variable "WEB_SECURITY_GROUP_DESCRIPTION" {
  type        = string
  description = "Description of the security group for web access"
  default     = "Allow Basic Web access"
}

variable "DB_SECURITY_GROUP_NAME" {
  type        = string
  description = "Name of the security group for db access"
  default     = "WP_DB_ACCESS"
}

variable "DB_SECURITY_GROUP_DESCRIPTION" {
  type        = string
  description = "Description of the security group for db access"
  default     = "Allow MySQL access"
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
