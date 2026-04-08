// S3 bucket for CodeBuild/CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_bucket_ecs" {
  bucket        = "${var.environment}-${var.app_name}-codepipeline-artefacts-ecs"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_block_ecs" {
  bucket                  = aws_s3_bucket.codepipeline_bucket_ecs.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket_ownership_ecs" {
  bucket = aws_s3_bucket.codepipeline_bucket_ecs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
resource "aws_s3_bucket_versioning" "codepipeline_bucket_versioning_ecs" {
  bucket = aws_s3_bucket.codepipeline_bucket_ecs.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_notification" "codepipeline_bucket_notification_ecs" {
  bucket      = aws_s3_bucket.codepipeline_bucket_ecs.id
  eventbridge = true
}
