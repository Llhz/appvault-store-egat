terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "appvault-tfstate"
  #   key            = "appvault.terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "appvault-tfstate-lock"
  #   encrypt        = true
  # }
}
