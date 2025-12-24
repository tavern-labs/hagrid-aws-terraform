terraform {
  backend "s3" {
    bucket = "tfstate-tavernlabs-03711579496081468369"
    key    = "aws/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
    use_lockfile = true
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
