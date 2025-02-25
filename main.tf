# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Generate a random string to ensure bucket name uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create an S3 bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-example-bucket-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "My Example Bucket"
    Environment = "Dev"
  }
}

# Output the generated bucket name
output "bucket_name" {
  value = aws_s3_bucket.example_bucket.bucket
}

