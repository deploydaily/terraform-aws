# ------------------------------------------------------
# IAM Role + Instance Profile for AWX Controller
# ------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "awx_controller_role" {
  name               = "awx-controller-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Minimal permissions — just EC2 describe for now (dynamic inventory later)
data "aws_iam_policy_document" "awx_controller_policy_doc" {
  statement {
    sid = "EC2DynamicInventory"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeTags",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "awx_controller_policy" {
  name   = "awx-controller-policy"
  role   = aws_iam_role.awx_controller_role.id
  policy = data.aws_iam_policy_document.awx_controller_policy_doc.json
}

resource "aws_iam_instance_profile" "awx_controller_instance_profile" {
  name = "awx-controller-profile"
  role = aws_iam_role.awx_controller_role.name
}
