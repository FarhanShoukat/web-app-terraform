resource "aws_security_group" "lb" {
  description = "Allow http to our load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment} Load Balancer SG"
  }
}

resource "aws_security_group" "autoscaling_group" {
  description = "Allow http to our hosts"
  vpc_id      = aws_vpc.main.id

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

  tags = {
    Name = "${var.environment} Autoscaling Group SG"
  }
}

resource "aws_iam_role" "ec2-s3-read-only" {
  name = "EC2-S3-read-only-access-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]

  tags = {
    Name = var.environment
  }
}

resource "aws_iam_instance_profile" "app_profile" {
  role = aws_iam_role.ec2-s3-read-only.name
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "as_conf" {
  name_prefix          = var.environment
  image_id             = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.app_profile.name
  security_groups      = [aws_security_group.autoscaling_group.id]
  # ebs_block_device {
  #   device_name = "/dev/sdk"
  #   volume_size = "10"
  # }

  user_data = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y apache2 unzip awscli
sudo systemctl start apache2.service    
aws s3 cp s3://${var.s3_bucket}/${var.archive_path} archive.zip
sudo rm /var/www/html/index.html
sudo unzip archive.zip -d /var/www/html
EOF
}

resource "aws_autoscaling_group" "web" {
  vpc_zone_identifier  = aws_subnet.private[*].id
  launch_configuration = aws_launch_configuration.as_conf.name
  max_size             = var.max_instances
  min_size             = var.min_instances
  target_group_arns    = [aws_lb_target_group.web.arn]
}

resource "aws_lb" "web_app_lb" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group" "web" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 8
    healthy_threshold   = 2
    port                = 80
    unhealthy_threshold = 5
  }
}