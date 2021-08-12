resource "aws_db_subnet_group" "nc-demo-rds" {
  name       = "nc-demo-rds"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "nc-demo"
  }
}

resource "aws_security_group" "rds" {
  name   = "education_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nc-demo-rds"
  }
}

resource "aws_db_parameter_group" "nc-demo" {
  name   = "nc-demo"
  family = "mysql5.7"

//  parameter {
//    name  = "log_connections"
//    value = "1"
//  }
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance

resource "aws_db_instance" "nc-demo" {
  identifier             = "nc-demo"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  max_allocated_storage  = 0
  engine                 = "mysql"
  engine_version         = "5.7"
  name                   = "notejam"
  username               = "notejam"
//  password               = var.db_password
  password               = "notejamnotejam"
  db_subnet_group_name   = aws_db_subnet_group.nc-demo-rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.nc-demo.name
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  // to fulfill the monitoring reqs
//  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  // 0-35 days
//  backup_retention_period = 0

  // Most users are active during business hours. During big
  // events and conferences the traffic could be 4 times more than typically.
//  backup_window
}
