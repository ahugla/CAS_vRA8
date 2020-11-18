provider "vsphere" {
  user           = "admin@cpod-vrealize.az-fkd.cloud-garage.net"
  password       = "VMware1!"
  vsphere_server = "vcsa.cpod-vrealize.az-fkd.cloud-garage.net"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}



data "vsphere_datacenter" "my_dc" {
  name = "cPod-VREALIZE"
}


resource "vsphere_folder" "folder" {
  path          = "TFdemo/terraform-test-folder"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.my_dc.id
}
