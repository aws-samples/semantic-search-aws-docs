### Terraform State about deployment ###
terraform {
  backend "s3" {
    key = "semantic-search/terraform.tfstate"
    #bucket = "tf-backend-bucket-xyz"           # You can replace this with your bucket name!
    #region = "eu-west-1"                       # You can replace this with your AWS region!
    #dynamodb_table = "tf-backend-table"        # You can replace this with your DynamoDB table name!
    encrypt = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.22"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">=3.0.0"
    }
  }
}

