################################################################################
# ECS
################################################################################

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.name
  requires_compatibilities = [var.launch_type]
  network_mode             = "bridge"
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = local.container_definitions
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  tags                     = var.tags

  dynamic "volume" {
    for_each = var.efs_volumes

    content {
      name = volume.value.name

      efs_volume_configuration {
        file_system_id     = volume.value.fs_id
        transit_encryption = "ENABLED"

        authorization_config {
          access_point_id = volume.value.access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }
}

resource "aws_ecs_service" "service" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.task_definition.arn
  launch_type     = var.launch_type
  desired_count   = var.desired_count
  tags            = var.tags

  dynamic "load_balancer" {
    for_each = var.lb_rule_subdomain || var.lb_rule_path ? [1] : []

    content {
      target_group_arn = aws_lb_target_group.target_group[0].arn
      container_name   = var.name
      container_port   = var.port
    }
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }
  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
    ignore_changes        = [desired_count, task_definition]
  }
  deployment_controller {
    type = "ECS"
  }
}


################################################################################
# Load balancer
################################################################################

resource "aws_lb_target_group" "target_group" {
  count = var.lb_rule_subdomain || var.lb_rule_path ? 1 : 0

  name        = "${var.env}-${var.name}-lb-tg"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    interval            = 300
    healthy_threshold   = 5
    unhealthy_threshold = 2
    path                = var.health_check_path
    matcher             = var.health_check_matcher
  }
}

resource "aws_lb_listener_rule" "lb_rule" {
  count = var.lb_rule_subdomain ? 1 : 0

  listener_arn = var.lb_listener_arn
  priority     = var.lb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

  condition {
    host_header {
      values = concat(var.domain_names, var.additional_domain_names)
    }
  }
}

resource "aws_lb_listener_rule" "lb_path_rule" {
  count = var.lb_rule_path ? 1 : 0

  listener_arn = var.lb_listener_arn
  priority     = var.lb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

  condition {
    path_pattern {
      values = var.assign_path
    }
  }

  condition {
    host_header {
      values = var.domain_names
    }
  }
}


################################################################################
# CloudWatch
################################################################################

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.env}-${var.name}"
  retention_in_days = var.cloudwatch_logs_retention_period

  tags = var.tags
}

################################################################################
# AutoScaling
################################################################################

resource "aws_appautoscaling_target" "dev_to_target" {
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "dev_to_memory" {
  name               = "dev-to-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dev_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dev_to_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dev_to_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "dev_to_cpu" {
  name               = "dev-to-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dev_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dev_to_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dev_to_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_scale_down_policy" {
  name               = "ecs-scale-down-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.dev_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dev_to_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dev_to_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 70
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = 0
    }
  }
}