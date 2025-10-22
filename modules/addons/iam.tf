# File: modules/addons/iam.tf
locals {
  alb_sa_name = "aws-load-balancer-controller"
}

# ------------------------
# AWS Load Balancer Controller IAM
# ------------------------
data "aws_iam_policy_document" "alb_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${local.alb_sa_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb" {
  name               = "${var.cluster_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_assume.json
  tags = merge(var.tags, {
    Component = "alb-controller"
  })
}

data "aws_iam_policy_document" "alb_policy" {
  statement {
    actions = [
      "elasticloadbalancing:*",
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "tag:GetResources",
      "tag:TagResources",
      "iam:CreateServiceLinkedRole",
      "waf-regional:*",
      "wafv2:*",
      "shield:*",
      "cognito-idp:DescribeUserPoolClient"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb" {
  name   = "${var.cluster_name}-alb-controller"
  policy = data.aws_iam_policy_document.alb_policy.json
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb.name
  policy_arn = aws_iam_policy.alb.arn
}

// Cluster Autoscaler IRSA removed for MVP
