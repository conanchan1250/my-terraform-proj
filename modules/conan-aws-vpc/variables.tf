variable "name" {  
    type = string
}

variable "cidr_block" {  
    type = string
    default = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {  
    type = bool
    default = true
}

variable "public_subnet_cidrs" {
    description = "List of public subnet cidrs"
    type = list(string)
}

variable "private_subnet_cidrs" {
    description = "List of private subnet cidrs"
    type = list(string)
}

variable "availability_zones" {  
    description = "Availability zones"
    type = list(string)
}

