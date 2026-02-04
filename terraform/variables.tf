variable "mariadb_root_password" {
  description = "Root password for MariaDB"
  type        = string
  sensitive   = true
  default     = "glpi_root_password"
}

variable "mariadb_database" {
  description = "Database name for GLPI"
  type        = string
  default     = "glpi"
}

variable "mariadb_user" {
  description = "Database user for GLPI"
  type        = string
  default     = "glpi_user"
}

variable "mariadb_password" {
  description = "Database password for GLPI user"
  type        = string
  sensitive   = true
  default     = "glpi_password"
}

variable "domain" {
  description = "Domain name for Let's Encrypt"
  type        = string
  default     = "glpi.example.com"
}

variable "email" {
  description = "Email for Let's Encrypt notifications"
  type        = string
  default     = "admin@example.com"
}

variable "nginx_replicas" {
  description = "Number of Nginx reverse proxy replicas"
  type        = number
  default     = 3
}
