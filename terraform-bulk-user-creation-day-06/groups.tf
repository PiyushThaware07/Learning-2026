resource "aws_iam_group" "education" {
  name = "Education"
  path = "/groups/"
}

resource "aws_iam_group" "engineers" {
  name = "Engineers"
  path = "/groups/"
}

resource "aws_iam_group" "managers" {
  name = "Managers"
  path = "/groups/"
}

# Education group
resource "aws_iam_group_membership" "education_members" {
  name  = "Education-group-members"
  group = aws_iam_group.education.name

  users = [
    for user in aws_iam_user.users :
    user.name if user.tags["Department"] == "Education"
  ]
}

# Engineers group
resource "aws_iam_group_membership" "engineers_members" {
  name  = "Engineers-group-members"
  group = aws_iam_group.engineers.name

  users = [
    for user in aws_iam_user.users :
    user.name if user.tags["Department"] == "Engineers"
  ]
}

# Managers group
resource "aws_iam_group_membership" "managers_members" {
  name  = "Managers-group-members"
  group = aws_iam_group.managers.name

  users = [
    for user in aws_iam_user.users :
    user.name if user.tags["Department"] == "Managers"
  ]
}