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
    sid     = "ElasticLoadBalancing"
    effect  = "Allow"
    actions = [
      # Broad but practical for dev/MVP; you can scope later
      "elasticloadbalancing:*",
      # These two are required for tagging ALB resources
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "EC2SecurityGroupsAndTags"
    effect  = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      # Tagging on EC2 SGs is what your events were denying
      "ec2:CreateTags",
      "ec2:DeleteTags",
      # Describes and Gets are used for subnet/SG/discovery flows
      "ec2:Describe*",
      "ec2:Get*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "IAMServiceLinkedRoleAndCerts"
    effect  = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ACMWAFShieldCognito"
    effect  = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
      "waf-regional:*",
      "wafv2:*",
      "shield:*",
      "cognito-idp:DescribeUserPoolClient"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "TagAPI"
    effect  = "Allow"
    actions = [
      "tag:GetResources",
      "tag:TagResources"
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
