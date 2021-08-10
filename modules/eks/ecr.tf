resource "aws_ecr_repository" "repo" {
  name                 = "notejam"
  image_tag_mutability = "IMMUTABLE"
}

//# security/policy
//resource "aws_iam_policy" "read" {
//  name        = format("%s-ecr-read", "nc-demo")
//  description = format("Allow to read images from the ECR")
//  path        = "/"
//  policy = jsonencode({
//    Statement = [{
//      Action = [
//        "ecr:BatchCheckLayerAvailability",
//        "ecr:BatchGetImage",
//        "ecr:DescribeImages",
//        "ecr:DescribeRepositories",
//        "ecr:GetAuthorizationToken",
//        "ecr:GetDownloadUrlForLayer",
//        "ecr:ListImages"
//      ]
//      Effect   = "Allow"
//      Resource = [aws_ecr_repository.repo.arn]
//    }]
//    Version = "2012-10-17"
//  })
//}
//
//resource "aws_iam_policy" "write" {
//  name        = format("%s-ecr-write", "nc-demo")
//  description = format("Allow to push and write images to the ECR")
//  path        = "/"
//  policy = jsonencode({
//    Statement = [{
//      Action = [
//        "ecr:PutImage",
//        "ecr:UploadLayerPart",
//        "ecr:InitiateLayerUpload",
//        "ecr:CompleteLayerUpload",
//      ]
//      Effect   = "Allow"
//      Resource = [aws_ecr_repository.repo.arn]
//    }]
//    Version = "2012-10-17"
//  })
//}

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
