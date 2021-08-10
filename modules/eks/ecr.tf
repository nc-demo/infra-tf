resource "aws_ecr_repository" "repo" {
  name                 = "notejam"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "nc-demo-policy" {
  repository = aws_ecr_repository.repo.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
      }
    ]
  }
  EOF
}

data "aws_ecr_authorization_token" "token" {
}

locals {
  service_name = "users"
  login_server = aws_ecr_repository.repo.repository_url
  username = data.aws_ecr_authorization_token.token.user_name
  password = data.aws_ecr_authorization_token.token.password
}

locals {
  docker-credentials = {
    auths = {
      "${local.login_server}" = {
        auth = base64encode("${local.username}:${local.password}")
      }
    }
  }
}

resource "kubernetes_secret" "docker_credentials" {
  metadata {
    name = "nc-demo"
  }

  data = {
    ".dockerconfigjson" = jsonencode(local.docker-credentials)
  }

  type = "kubernetes.io/dockerconfigjson"
}