provider "aws" {
}


variable "myTag" {
  description = "My Input Tag"
  default = "alextag"
}


resource "aws_instance" "web" {
  ami = "ami-0b850cf02cc00fdc8"
  instance_type = "t2.nano"

  tags = {
  "type" = var.myTag
  }
  
}
