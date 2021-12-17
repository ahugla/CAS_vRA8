
provider "aws" {
}


variable "myTag" {
  description = "My Input Tag"
  default = "alextag"
}

variable "myAMI" {
  description = "AMI to use"
}


resource "aws_instance" "web" {
  instance_type = "t2.nano"

  ami = var.myAMI

  tags = {
  "type" = var.myTag
  }

}



# PARIS (eu-west-3)
# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
# ami-0d3c032f5934e1b41 (64-bit (x86))


# IRLAND (eu-west-1)
# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
# ami-04dd4500af104442f (64-bit (x86))




