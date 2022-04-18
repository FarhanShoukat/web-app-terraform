output "vpc_id" {
  value = aws_vpc.main.id
}

output "load_balancer_dns_name" {
  value = "http://${aws_lb.web_app_lb.dns_name}"
}