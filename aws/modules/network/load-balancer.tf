resource "aws_lb_target_group" "eks-node-tg" {
  name     = format("%s-tg", var.cluster_name)
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.cluster_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb" "eks-lb" {
  name               = format("%s-load-balancer", var.cluster_name)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group.id]
  subnets            = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1c.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.eks-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks-node-tg.arn
  }
}

resource "kubernetes_ingress" "node-ingress" {
  metadata {
    name      = format("%s-node-ingress", var.cluster_name)
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{
        HTTP = 80
        HTTPS = 443
      }])
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "example-service"
            service_port = 3000
          }
        }
      }
    }
  }
}

output "elb_dns_name" {
  value       = aws_lb.eks-lb.dns_name
  description = "O endereço DNS do ELB para acessar o serviço."
}