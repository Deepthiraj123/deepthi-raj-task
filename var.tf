variable "cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}
variable "availability_zone1" {
    default = "us-west-2a"
    type = string
    description = "availability zone"
}
variable "availability_zone2" {
    default = "us-west-2b"
    type = string
    description = "availability zone"
}
variable "public_subnet1_cidr_block" {
  default     = "10.0.0.0/24"
  type        = string
  description = "List of spublic1 subnet CIDR block"
}
variable "public_subnet2_cidr_block" {
  default     = "10.0.2.0/24"
  type        = string
  description = "List of spublic2 subnet CIDR block"
}
variable "private_subnet1_cidr_block" {
  default     = "10.0.1.0/24"
  type        = string
  description = "List of sprivate1 subnet CIDR block"
}
variable "private_subnet2_cidr_block" {
  default     = "10.0.3.0/24"
  type        = string
  description = "List of sprivate2 subnet CIDR block"
}
