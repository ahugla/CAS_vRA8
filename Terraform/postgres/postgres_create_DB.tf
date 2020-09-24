variable "postgres_password" {
  type = string
}


provider "postgresql" {
  host            = "172.19.2.219"
  port            = 5432
  username        = "postgres"
  password        = "var.postgres_password!"
  sslmode         = "disable"
}


resource "postgresql_role" "role1" {
  name     = "alex1"
  login    = true
  password = "123456789"
}


resource "postgresql_database" "my_db1" {
  name              = "my_db1"
  owner             = "alex1"
  template          = "template0"
  lc_collate        = "C"
  connection_limit  = -1
  allow_connections = true

  depends_on = [postgresql_role.role1]
}
