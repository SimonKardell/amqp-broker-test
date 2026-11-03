variable "broker_url" {
  type        = string
  description = "The base URL of the broker"
  default     = "http://localhost:8080"
}

# This is the local dev environment profile
variable "client_username" {
  type        = string
  description = "Client username for the broker"
  default     = "username"
}

# This is the local dev environment password
variable "client_password" {
  type        = string
  description = "Client password for the broker"
  default     = "password"
}


variable "test_client_username" {
  type        = string
  description = "Test Client username for the broker"
  default     = "test-sa-local"
}

variable "test_client_password" {
  type        = string
  description = "Test Client password for the broker"
  default     = "password"
}
variable "message_vpn_name" {
  type        = string
  description = "Message VPN name for the broker"
  default     = "dev"
}

variable "order_app_username" {
  type        = string
  description = "Client username for the order app"
  default     = "orders-sa-local"
}

variable "order_app_password" {
  type        = string
  description = "Client password for the order app"
  default     = "password"
}