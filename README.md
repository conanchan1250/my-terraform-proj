# my-terraform-proj

## project001-user
Example to setup user, create group, attach policy and add user to group

## project002-vpc
Create VPC.

Based on https://spacelift.io/blog/terraform-aws-vpc

### project002-vpc-module

Create a module to create VPC

## project003-autoscaling
Setup a simple website with 3 EC2 machines and a load balancer.
Create S3 bucket, create Launch template and an auto scaling group.
Create IAM role for the EC2 machine to access the S3 bucket.
Create Security Group for remote SSH and HTTP access.

Prereq: Use module conan-aws-vpc

Based on this course https://kodekloud.com/courses/aws-cloud-for-beginners/

In this chapter https://kodekloud.com/lessons/amazon-elastic-compute-cloud-ec2/

## project004
Setup RDS + Wordpress

Prereq: VPC created by project002

Based on this course https://kodekloud.com/courses/aws-cloud-for-beginners/

In this chapter https://kodekloud.com/lessons/aws-databases/

## project005
Setup ECS + load balancer

