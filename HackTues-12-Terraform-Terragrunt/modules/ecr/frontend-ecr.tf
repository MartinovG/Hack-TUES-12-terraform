resource "aws_ecr_repository" "frontend" {
  for_each = var.frontend

  name                 = "${var.environment}-${var.app_name}-${each.key}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = false }
  encryption_configuration { encryption_type = "AES256" }
}

resource "aws_ecr_lifecycle_policy" "frontend_policy" {
  for_each   = var.frontend
  repository = aws_ecr_repository.frontend[each.key].name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images over 30 count",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {"type": "expire"}
    }
  ]
}
EOF
}
