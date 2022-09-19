
resource "aws_efs_file_system" "grafana" {
  encrypted = true
  creation_token = "grafana"
  tags = {
    Name = "grafana"
  }
}
resource "aws_efs_mount_target" "ecs_service_storage" {
  count           = length(aws_subnet.public.*.id)

  file_system_id  = aws_efs_file_system.grafana.id
  subnet_id       = aws_subnet.public.*.id[count.index]
  security_groups = [aws_security_group.endpoints.id]
}
resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.grafana.id
  root_directory {
    path = "/grafana"
    creation_info {
      owner_gid = 1
      owner_uid = 472
      permissions = 0755
    }
  }
  posix_user {
      uid = 472
      gid = 1
  }

  tags = {
      Name        = "grafana"
      Environment = "Desenvolvimento"
  }   
}