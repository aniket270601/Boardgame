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




resource "aws_instance" "appserver" {
    ami = "ami-0dee22c13ea7a9a67"
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
}


