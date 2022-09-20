locals {
  grafana_container_def = [
    {
      name        = "grafana"
      image       = var.aws_ecr_repository
      networkMode = "awsvpc"
      cpu         = var.fargate_cpu
      memory      = var.fargate_memory
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.grafana.name
          awslogs-stream-prefix = "containers",
          awslogs-region        = "us-east-1"
        }
      }
      mountPoints = [
        {
          containerPath = "/var/lib/grafana"
          sourceVolume  = "grafana"
        }
      ]
      environment = [
        {
          name  = "GRAFANA_PATHS_PROVISIONING"
          value = "/var/lib/grafana/provisioning"
        }
      ]
    }
  ]
}

resource "aws_ecs_cluster" "fargate" {
  name = local.cluster_name
  tags = {
    Name = "Fargate"
    Name = "grafana"
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  execution_role_arn       = aws_iam_role.grafana_execution_role.arn
  container_definitions    = jsonencode(local.grafana_container_def)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.grafana_task_role.arn

  volume {
    name = "grafana"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.grafana.id
      root_directory     = "/grafana"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.grafana.id
      }

    }
  }

  cpu    = 1024
  memory = 2048
}

resource "aws_ecs_service" "grafana" {
  name             = "grafana"
  cluster          = aws_ecs_cluster.fargate.id
  task_definition  = aws_ecs_task_definition.grafana.arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "EC2"
  depends_on       = [aws_iam_role.grafana_execution_role]

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }
  network_configuration {
    subnets          = aws_subnet.public.*.id
    assign_public_ip = false
    security_groups  = [aws_security_group.grafana.id]
  }
}