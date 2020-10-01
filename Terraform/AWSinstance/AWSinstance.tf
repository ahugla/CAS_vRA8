variable "access_key" {
  description = "AWS Access Key"
}


variable "secret_key" {
  description = "AWS Secret Key"
}


provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
}


resource "aws_instance" "web" {
  ami = "ami-08a2aed6e0a6f9c7d"
  instance_type = "t2.micro"

  tags = {
    TagKey1 = "MonSuperTag"
  }

}

