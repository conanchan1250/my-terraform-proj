/*
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project VPC"
  }
}
*/

/*
data "aws_iam_group" "admin" {
  group_name = "Admin"
}
*/

// get arn of the built in policy for AdministratorAccess
data "aws_iam_policy" "admin_access" {
  name = "AdministratorAccess"
}

resource "aws_iam_user" "lucy" {
  name = "lucy"
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.lucy.name
  policy_arn = data.aws_iam_policy.admin_access.arn
}


// Create User Group for Dev with full EC2 access
resource "aws_iam_group" "developers" {
  name = "gen_developers"
}

// get arn of the built in policy for AmazonEC2FullAccess
data "aws_iam_policy" "ec2_full_access" {
  name = "AmazonEC2FullAccess"
}
resource "aws_iam_group_policy_attachment" "dev-ec2-attach" {
  group      = aws_iam_group.developers.name
  policy_arn = data.aws_iam_policy.ec2_full_access.arn
}

// create dev user and add to group
resource "aws_iam_user" "dev-users" {
  name  = var.dev-users[count.index]
  count = length(var.dev-users)
}

resource "aws_iam_user_group_membership" "add-user-to-dev-group" {
  user = aws_iam_user.dev-users[count.index].name
  count = length(aws_iam_user.dev-users)

  groups = [
    aws_iam_group.developers.name,
  ]
}