# 1. AS CANCELAS (Security Group)
resource "aws_security_group" "this" {
  name        = "sg-${var.city_name}"
  description = "Cancelas de segurança da ferrovia ${var.city_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "SG-${var.city_name}" })
}

# 2. REGRAS DINÂMICAS (Libera portas variáveis)
resource "aws_security_group_rule" "ingress" {
  count             = length(var.allowed_ports)
  type              = "ingress"
  from_port         = var.allowed_ports[count.index]
  to_port           = var.allowed_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

# 3. AS CHAVES DO PORTÃO (IAM Role)
resource "aws_iam_role" "this" {
  name = "role-${var.city_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.tags
}