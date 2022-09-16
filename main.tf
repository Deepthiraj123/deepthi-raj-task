provider "aws" {
 region = "us-west-2"  
}
resource "aws_vpc" "deep-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
}
resource "aws_subnet" "deep-private1" {
    vpc_id = "{aws_vpc.deep-vpc}"
    cidr_block = "10.0.1.0/24" 
}
resource "aws_subnet" "deep-private2" {
    vpc_id = "{aws_vpc.deep-vpc}"
    cidr_block = "10.0.3.0/24"
}
resource "aws_subnet" "deep-public1" {
    vpc_id = "{aws_vpc.deep-vpc}"
    cidr_block = "10.0.0.0/24"
}
resource "aws_subnet" "deep-public2" {
    vpc_id = "{aws_vpc.deep-vpc}"
    cidr_block = "10.0.2.0/24"
}
resource "aws_internet_gateway" "deep-igw" {
  vpc_id = "{aws_vpc.deep-vpc}"
}
resource "aws_eip" "deep-eip" {
   vpc   = true
 }
 resource "aws_nat_gateway" "deep-nat" {
   allocation_id = "{aws_eip.deep-nat.id}"
   subnet_id = "{aws_subnet.deep-public1}"
 }
resource "aws_route_table" "deep_RT1" {
  vpc_id = "{aws_vpc.deep-vpc}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "{aws_internet_gateway.deep-igw.id}"
  }  
}
resource "aws_route_table" "deep_RT2" {
  vpc_id = "{aws_vpc.deep-vpc}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "{aws_nat_gateway.deep-nat.id}"
  }  
}
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = "{aws_subnet.deep-public.id}"
    route_table_id = "{aws_route_table.deep-RT1.id}"
 }
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = "{aws_subnet.deep-private.id}"
    route_table_id = "{aws_route_table.deep-RT2.id}"
 }