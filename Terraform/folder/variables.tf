
variable "vCenterPassword" {
  description = "Password du compte 'admin' de vCenter"
}


variable "FolderList" {
  type = list(string)
  description = "Nom des Folders"
}
