provider "aws" {
}


variable "myTag" {
  description = "My Input Tag"
  default = "alextag"
}


resource "aws_instance" "web" {
  ami = "ami-0950a18001c172f3a"
  instance_type = "t2.nano"

  tags = {
  "type" = var.myTag
  }
  
}
