resource "aws_cloudwatch_log_group" "grafana" {
    name = "/aws/ecs/grafana"
    retention_in_days = 7
    tags = {
        Name = "grafana"
        Environment = "Desenvolvimento"
        Application = "Grafana-Fargate"
    }