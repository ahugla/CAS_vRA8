provider "aws" {
  region = "eu-west-1"
  access_key = "xxxx"
  secret_key = "xxxx"
}


resource "aws_instance" "web" {
  ami = "ami-08a2aed6e0a6f9c7d"
  instance_type = "t2.micro"
}


