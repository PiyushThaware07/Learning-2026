# ------------------------
# S3 Bucket
# ------------------------
resource "aws_s3_bucket" "flowbit_s3_bucket" {
  bucket = "flowbit-bucket"
}

# ------------------------
# Upload ZIP (v1 - BLUE)
# ------------------------
resource "aws_s3_object" "flowbit_s3_object_v1" {
  bucket = aws_s3_bucket.flowbit_s3_bucket.id
  key    = "app-v1.zip"
  source = "app.zip"

  etag = filemd5("app.zip")
}

# ------------------------
# Upload ZIP (v2 - GREEN)
# ------------------------
resource "aws_s3_object" "flowbit_s3_object_v2" {
  bucket = aws_s3_bucket.flowbit_s3_bucket.id
  key    = "app-v2.zip"
  source = "app.zip"

  etag = filemd5("app.zip")
}

# ------------------------
# IAM Role for EC2 (Beanstalk)
# ------------------------
resource "aws_iam_role" "eb_instance_role" {
  name = "flowbit-eb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_worker_tier" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "eb_multicontainer" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

# Instance Profile
resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "flowbit-eb-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

# ------------------------
# Elastic Beanstalk App
# ------------------------
resource "aws_elastic_beanstalk_application" "flowbit_app" {
  name = "flowbit-app"
}

# ------------------------
# Application Version (v1 - BLUE)
# ------------------------
resource "aws_elastic_beanstalk_application_version" "v1" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.flowbit_app.name
  bucket      = aws_s3_bucket.flowbit_s3_bucket.id
  key         = aws_s3_object.flowbit_s3_object_v1.key

  depends_on = [aws_s3_object.flowbit_s3_object_v1]
}

# ------------------------
# Application Version (v2 - GREEN)
# ------------------------
resource "aws_elastic_beanstalk_application_version" "v2" {
  name        = "v2"
  application = aws_elastic_beanstalk_application.flowbit_app.name
  bucket      = aws_s3_bucket.flowbit_s3_bucket.id
  key         = aws_s3_object.flowbit_s3_object_v2.key

  depends_on = [aws_s3_object.flowbit_s3_object_v2]
}

# ------------------------
# Environment (BLUE)
# ------------------------
resource "aws_elastic_beanstalk_environment" "blue_env" {
  name                = "flowbit-blue"
  application         = aws_elastic_beanstalk_application.flowbit_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.10.1 running Node.js 20"
  version_label       = aws_elastic_beanstalk_application_version.v1.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}

# ------------------------
# Environment (GREEN)
# ------------------------
resource "aws_elastic_beanstalk_environment" "green_env" {
  name                = "flowbit-green"
  application         = aws_elastic_beanstalk_application.flowbit_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.10.1 running Node.js 20"
  version_label       = aws_elastic_beanstalk_application_version.v2.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  # SAME IAM PROFILE (shared)
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}