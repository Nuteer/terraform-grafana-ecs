data "aws_availability_zones" "available" {
}
data "aws_route53_zone" "primary" {
  name         = var.route_53_zone
  private_zone = false
}
data "aws_acm_certificate" "grafana" {
  domain      = var.certificate_domain
  types       = ["AWS_OWNED"]
  most_recent = true
}
data "aws_route_table" "main" {
  vpc_id = aws_vpc.fargate.id
}
data "aws_subnet_ids" "public" {
  vpc_id = aws_vpc.fargate.id
  filter {
    name   = "tag:Name"
    values = ["public-*"]
  }
}

resource "aws_lb" "grafana" {
  name                       = "grafana-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.grafana_service.id]
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = false

  tags = {
    Name        = "Grafana"
    Environment = "Desenvolvimento"
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "grafana-lb-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.fargate.id
  health_check {
    healthy_threshold   = "3"
    interval            = "90"
    protocol            = "HTTP"
    matcher             = "200-299"
    timeout             = "20"
    path                = "/api/health"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "grafana443" {
  load_balancer_arn = aws_lb.grafana.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.grafana.arn

  default_action {
    target_group_arn = aws_lb_target_group.grafana.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "grafana80" {
  load_balancer_arn = aws_lb.grafana.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.certificate_domain
  type    = "A"

  alias {
    name                   = aws_lb.grafana.dns_name
    zone_id                = aws_lb.grafana.zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "grafana" {
  name        = "grafana"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.fargate.id

  ingress {
    description     = "From LB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.grafana_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Grafana" }
}

resource "aws_security_group" "grafana_service" {
  name        = "grafana_service"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.fargate.id

  ingress {
    description = "Web Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_public_cidr]
  }
  ingress {
    description = "TLS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_public_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Grafana-Service"
  }
}

resource "aws_security_group" "endpoints" {
  name        = "vpc-endpoints"
  description = "Allow service traffic to endpoints"
  vpc_id      = aws_vpc.fargate.id

  ingress {
    description = "SSL Access"
    from_port   = 0
    to_port     = 65500
    protocol    = "tcp"
    security_groups = [
      aws_security_group.grafana_service.id,
      aws_security_group.grafana.id
    ]
  }
  ingress {
    description = "NFS Access"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [
      aws_security_group.grafana_service.id,
      aws_security_group.grafana.id
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoints"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.fargate.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.aws_route_table.main.id]

  tags = {
    Name        = "s3-endpoint"
    Environment = "Desenvolvimento"
  }
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = aws_vpc.fargate.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  subnet_ids          = aws_subnet.public.*.id
  private_dns_enabled = true
  tags = {
    Name        = "ecr-dkr-endpoint"
    Environment = "Desenvolvimento"
  }
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id              = aws_vpc.fargate.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  subnet_ids          = aws_subnet.public.*.id
  private_dns_enabled = true
  tags = {
    Name        = "ecr-api-endpoint"
    Environment = "Desenvolvimento"
  }
}

resource "aws_vpc_endpoint" "efs" {
  vpc_id              = aws_vpc.fargate.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  subnet_ids          = aws_subnet.public.*.id
  tags = {
    Name        = "efs-endpoint"
    Environment = "Desenvolvimento"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.fargate.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  subnet_ids          = aws_subnet.public.*.id

  tags = {
    Name        = "logs-endpoint"
    Environment = "Desenvolvimento"
  }
}

resource "aws_vpc_endpoint" "cw" {
  vpc_id              = aws_vpc.fargate.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  subnet_ids          = aws_subnet.public.*.id
  tags = {
    Name        = "cw-endpoint"
    Environment = "Desenvolvimento"
  }
}