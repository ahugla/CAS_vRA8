provider "vsphere" {
  user           = "admin@cpod-vrealizesuite.az-demo.shwrfr.com"
  password       = "VMware1!"
  vsphere_server = "vcsa.cpod-vrealizesuite.az-demo.shwrfr.com"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}



data "vsphere_datacenter" "my_dc" {
  name = "cPod-VREALIZESUITE"
}


resource "vsphere_folder" "folder" {
  path          = "terraform-test-folder"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.my_dc.id
}
