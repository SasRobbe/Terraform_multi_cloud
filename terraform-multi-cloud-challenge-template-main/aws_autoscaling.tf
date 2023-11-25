# Create an AWS VPC (Virtual Private Cloud) with the specified CIDR block.
resource "aws_vpc" "mainrs" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet in the VPC with a specific CIDR block and map public IP addresses on launch.
resource "aws_subnet" "publicrs" {
  vpc_id                  = aws_vpc.mainrs.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true   # This is a public subnet
  availability_zone       = "us-east-1a"
}

# Create an additional public subnet with similar settings.
resource "aws_subnet" "publicrs2" {
  vpc_id                  = aws_vpc.mainrs.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true   # This is a public subnet
  availability_zone       = "us-east-1b"
}

# Create a private subnet in the VPC with a specific CIDR block and no mapping of public IP addresses on launch.
resource "aws_subnet" "privaters" {
  vpc_id                  = aws_vpc.mainrs.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false  # This is a private subnet
  availability_zone       = "us-east-1e"
}

# Create an Internet Gateway and associate it with the VPC.
resource "aws_internet_gateway" "gwrs" {
  vpc_id = aws_vpc.mainrs.id
}

# Create an Elastic IP (EIP) for NAT Gateway.
resource "aws_eip" "natrs" {
  domain = "vpc"
}

# Create a NAT Gateway and associate it with a public subnet and the EIP.
resource "aws_nat_gateway" "gwrs" {
  allocation_id = aws_eip.natrs.id
  subnet_id     = aws_subnet.publicrs.id
}

# Create a route table for the public subnet and add a default route to the Internet Gateway.
resource "aws_route_table" "publicrs" {
  vpc_id = aws_vpc.mainrs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gwrs.id
  }
}

# Associate the public subnet with the public route table.
resource "aws_route_table_association" "publicrs" {
  subnet_id      = aws_subnet.publicrs.id
  route_table_id = aws_route_table.publicrs.id
}

# Create a route table for the private subnet and add a default route to the NAT Gateway.
resource "aws_route_table" "privaters" {
  vpc_id = aws_vpc.mainrs.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gwrs.id
  }
}

# Create a route table for the additional public subnet and add a default route to the Internet Gateway.
resource "aws_route_table" "publicrs2" {
  vpc_id = aws_vpc.mainrs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gwrs.id
  }
}

# Associate the additional public subnet with the additional public route table.
resource "aws_route_table_association" "publicrs2" {
  subnet_id      = aws_subnet.publicrs2.id
  route_table_id = aws_route_table.publicrs2.id
}

# Associate the private subnet with the private route table.
resource "aws_route_table_association" "privaters" {
  subnet_id      = aws_subnet.privaters.id
  route_table_id = aws_route_table.privaters.id
}

# Retrieve the ID of the latest Amazon Linux 2 AMI for use in creating instances.
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a security group for the Auto Scaling Group (ASG).
resource "aws_security_group" "asg_sg" {
  name        = "asg_sg"
  description = "Allow inbound traffic from the Load Balancer"
  vpc_id      = aws_vpc.mainrs.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id] # Only allow traffic from the Load Balancer
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define a cloud-init configuration for instances.
# This configuration includes writing files and running a script during instance launch.
data "template_file" "init" {
  template = file("${path.module}/hangman_front/hangman.js")

  vars = {
    api_host = "${azurerm_container_app.capprobbesas.latest_revision_fqdn}"
  }
}

# Create the cloud-init configuration using the local variables.
locals {
  cloud_config_config = <<-END
    #cloud-config
    ${jsonencode({
      write_files = [
        {
          path        = "/var/www/html/index.html"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = filebase64("${path.module}/hangman_front/index.html")
        },
        {
          path        = "/var/www/html/hangman.js"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = base64encode(data.template_file.init.rendered)
        },
      ]
    })}
  END
}

# Create a cloud-init configuration data source using the cloud-init configuration.
data "cloudinit_config" "example" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    filename     = "cloud-config.txt"
    content      = local.cloud_config_config
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "start-httpd.sh"
    content  = <<-EOF
      #!/bin/bash
      sudo yum install -y httpd
      sudo systemctl start httpd
      sudo systemctl enable httpd
    EOF
  }
}

# Create an Auto Scaling Group (ASG) using the specified configuration.
module "asg" {
  source              = "terraform-aws-modules/autoscaling/aws"
  image_id            = data.aws_ami.amazon-linux-2.id
  instance_type       = "t2.micro"
  name                = "webservers-asg"
  target_group_arns   = module.lb.target_group_arns
  user_data           = base64encode(data.cloudinit_config.example.rendered)
  vpc_zone_identifier = [aws_subnet.privaters.id]
  health_check_type   = "EC2"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  security_groups     = [aws_security_group.asg_sg.id]
  depends_on          = [azurerm_container_app.capprobbesas, aws_vpc.mainrs, aws_subnet.publicrs, aws_subnet.publicrs2, aws_subnet.privaters, aws_internet_gateway.gwrs, aws_eip.natrs, aws_nat_gateway.gwrs,  aws_route_table.publicrs, aws_route_table_association.publicrs, aws_route_table.privaters, aws_route_table.publicrs2, aws_route_table_association.publicrs2, aws_route_table_association.privaters, module.lb]
}

# Create a security group for the Load Balancer (LB).
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow inbound traffic from the internet"
  vpc_id      = aws_vpc.mainrs.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from the internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Retrieve the ID of the main VPC using a data source.
data "aws_vpc" "mainrs" {
  id         = aws_vpc.mainrs.id
  depends_on = [aws_vpc.mainrs]
}

# Create a Load Balancer (LB) using the specified configuration.
module "lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name               = "webservers-lb"
  load_balancer_type = "application"
  vpc_id             = data.aws_vpc.mainrs.id
  subnets            = [aws_subnet.publicrs.id, aws_subnet.publicrs2.id, aws_subnet.privaters.id]
  security_groups    = [aws_security_group.lb_sg.id]

  http_tcp_listeners = [
    {
      port                  = 80
      protocol              = "HTTP"
      target_group_name     = "webservers-tg"
      target_group_port     = 80
      target_group_protocol = "HTTP"
    },
  ]

  target_groups = [
    {
      name             = "webservers-tg"
      backend_protocol = "HTTP"
      backend_port     = 80
    },
  ]
}