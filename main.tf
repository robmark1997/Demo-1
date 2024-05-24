
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.51.0"
    }
  }
}


resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "demo-sub" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "demo-sub"
  }
}

resource "aws_subnet" "demo-sub-2" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "demo-sub-2"
  }
}


resource "aws_security_group" "demo-sg" {
  name        = "all"
  vpc_id      = aws_vpc.demo.id
  
  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = aws_vpc.demo.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.demo-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}







data "aws_ami" "demo" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_instance" "web" {
 
  ami           = data.aws_ami.demo.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.demo-sub.id

  tags = {
    Name = "Demo-instance"
  }
}


resource "aws_instance" "web2" {
 
  ami           = data.aws_ami.demo.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.demo-sub-2.id

  tags = {
    Name = "Demo-instance"
  }
}


resource "aws_lb" "demo-lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            = [ aws_subnet.demo-sub.id, aws_subnet.demo-sub-2.id]

  enable_deletion_protection = true

  tags = {
    Name = "demo-lb"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.demo-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo-tg.arn
  }
}


resource "aws_lb_target_group" "demo-tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.demo.id
}


