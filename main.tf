locals {
    vpc_id = "vpc-0ee3cdb198383aa5b"
    subnet_id = "subnet-0bcc3e3e2067fb21b"
    ssh_user = "ubuntu"
    key_name = "aws-lab2"
    private_key_path = "/home/ubuntu/aws-lab2.pem"
}




provider "aws" {
    region = "us-east-1"
    
}



variable "alb_name" {

    default = "my-alb"
}



resource "aws_instance" "appserver" {
    ami = "ami-084568db4383264d4"
    instance_type = "t3.small"
    subnet_id = local.subnet_id
    associate_public_ip_address = true
    vpc_security_group_ids = ["sg-024bee3fa70ce7a82"]
    key_name = local.key_name
    
    tags = {
    Name = "appserver"
    }

    provisioner "remote-exec"{
        inline = ["echo 'wait until the ssh is ready'"]
        connection{
            type = "ssh"
            user = local.ssh_user
            private_key = file(local.private_key_path)
            host = aws_instance.appserver.public_ip
        }
    }


    provisioner "local-exec"{
        command = "ansible-playbook -i ${ aws_instance.appserver.public_ip}, --private-key ${local.private_key_path} appserver.yml"
    }



    provisioner "local-exec" {
        command = <<EOT
          ansible-playbook -i "172.31.21.157," \
           --private-key "${local.private_key_path}" \
           update_Prometheus.yml \
           -e "target_ip=${self.private_ip}"
        EOT
}

}





# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_name}-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# ALB
resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0bcc3e3e2067fb21b", "subnet-04d3aa79468b820ac"]
}




#Target Group
resource "aws_lb_target_group" "tg" {
  name     = "${var.alb_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}




#attach target Group
resource "aws_lb_target_group_attachment" "attach_web" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.appserver.id
  port             = 8080
}




#Listener for lb 
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}