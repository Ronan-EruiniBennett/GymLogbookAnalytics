// Configure the AWS provider/plugin to allow Terraform to talk to AWS.
provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Owner       = "Ronan"
      Environment = "Practice"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  default_tags {
    tags = {
      Owner       = "Ronan"
      Environment = "Practice"
    }
  }
}
