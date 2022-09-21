provider "aws" {
 region = "us-west-2"  
}
resource "aws_vpc" "deep-vpc" {
    cidr_block = var.cidr_block
    instance_tenancy = "default"
}
resource "aws_subnet" "deepthi-private1" {
    vpc_id = aws_vpc.deep-vpc.id
    cidr_block= var.private_subnet1_cidr_block
    availability_zone = var.availability_zone1
}
resource "aws_subnet" "deepthi-private2" {
    vpc_id = aws_vpc.deep-vpc.id
    cidr_block= var.private_subnet2_cidr_block
    availability_zone = var.availability_zone2

}
resource "aws_subnet" "deepthi-public1" {
    vpc_id = aws_vpc.deep-vpc.id
    cidr_block= var.public_subnet1_cidr_block
    availability_zone = var.availability_zone1
}
resource "aws_subnet" "deepthi-public2" {
    vpc_id = aws_vpc.deep-vpc.id
    cidr_block= var.public_subnet2_cidr_block
    availability_zone = var.availability_zone2
}
resource "aws_internet_gateway" "deepthi-igw" {
  vpc_id = aws_vpc.deep-vpc.id
}
resource "aws_eip" "deepthi-eip" {
   vpc   = true
 }
 resource "aws_nat_gateway" "deepthi-nat" {
   allocation_id = aws_eip.deepthi-eip.id
   subnet_id = aws_subnet.deepthi-public1.id
 }
resource "aws_route_table" "deepthi_RT1" {
  vpc_id = aws_vpc.deep-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.deepthi-igw.id
  }  
}
resource "aws_route_table" "deepthi_RT2" {
  vpc_id = aws_vpc.deep-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.deepthi-nat.id
  }  
}
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.deepthi-public1.id
    route_table_id = aws_route_table.deepthi_RT1.id
 }
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.deepthi-private1.id
    route_table_id = aws_route_table.deepthi_RT2.id
 }

 resource "aws_security_group" "deep-sg" {
  vpc_id = aws_vpc.deep-vpc.id
 
  ingress {
   protocol         = "tcp"
   from_port        = 80
   to_port          = 80
   cidr_blocks      = ["0.0.0.0/0"]
  }
 
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
  }
}
resource "aws_lb" "deep-LB" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.deep-sg.id]
  subnets            = [aws_subnet.deepthi-public1.id,aws_subnet.deepthi-public2.id]
  enable_deletion_protection = false
}
resource "aws_lb_listener" "deep-listener" {  
  load_balancer_arn =  aws_lb.deep-LB.arn
  port              =  "8080"  
  protocol          = "HTTP"

  default_action { 
  type = "forward"
  target_group_arn = aws_lb_target_group.deep_target_group.arn
  }
  }
  
resource "aws_lb_target_group" "deep_target_group"{
  name = "deep-target-group"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.deep-vpc.id
 }

 /* resource "aws_lb_target_group_attachment" "shiv_tg_attachment" {
  target_group_arn = aws_lb_target_group.shiv_target_group.arn
  target_id = aws_lb.shiv-lb.id
  port = "80"
 } */

resource "aws_ecr_repository" "deep-image" {
  name                 = "deep-image"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
 }
}

resource "aws_ecs_cluster" "deep-cluster" {
 name = "deep-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "deep_Taskdef" {
  family = "ServiceforFargate1"
  requires_compatibilities =  ["FARGATE"]
  cpu = "1024"
  memory =  "2048"
  network_mode =  "awsvpc"

   container_definitions = file("./ServiceforFargate.json")
runtime_platform {
 operating_system_family = "WINDOWS_SERVER_2019_FULL"
 cpu_architecture = "X86_64"
}
depends_on = [
  aws_ecs_cluster.deep-cluster
]

  #jsonencode([
    #{
      #name      = "first"
      #image     = "service-first"
      #cpu       = 10
      #memory    = 512
    #  essential = true
     # portMappings = [
      #  {
       #   containerPort = 8080
        #  hostPort      = 8080
        #}
     # ])#
    #},
   }
   

resource "aws_security_group" "deep-sg2" {
  vpc_id      = aws_vpc.deep-vpc.id

  ingress {
    description      = "TLS from VPC"
    protocol         = "tcp"
    from_port        = 8080
    to_port          = 8080
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = [aws_security_group.deep-sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  } 
}
resource "aws_ecs_service" "deep-ecs-service" {
  name = "deep-ecs-service"
  cluster              = aws_ecs_cluster.deep-cluster.id
  task_definition      = aws_ecs_task_definition.deep_Taskdef.id
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 2
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.deepthi-private1.id , aws_subnet.deepthi-private2.id ]
    assign_public_ip = true
    security_groups = [aws_security_group.deep-sg.id]
  }

load_balancer{
  target_group_arn = aws_lb_target_group.deep_target_group.arn
  container_name = "deepcontainer-fargate"
  container_port = 80
}
}
resource "aws_route53_zone" "deepthi" {
  name = "deepthi.ml"
}
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.deepthi.zone_id
  name    = "deepthi.ml"
  type    = "A"

  alias {
  name                   = aws_lb.deep-LB.dns_name
 zone_id                = aws_lb.deep-LB.zone_id
 evaluate_target_health = true
}
}


