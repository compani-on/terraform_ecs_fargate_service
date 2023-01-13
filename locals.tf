locals {
  assign_domain_name = var.domain_name != null
  assign_path        = var.assign_path != null

  container_definitions = templatefile(
    "${path.module}/templates/container-definitions.json",
    {
      image_name       = var.image
      container_name   = var.name
      container_memory = var.memory
      container_cpu    = var.cpu
      port             = var.port
      environment      = [
        for name, value in var.environment : {
          name  = name
          value = value
        }
      ]
      secrets = [
        for name, value in var.secure_environment : {
          name      = name
          valueFrom = value
        }
      ]
      mount_points = [
        for volume in var.efs_volumes : {
          containerPath = volume.path,
          sourceVolume  = volume.name,
        }
      ]


      # Logging configuration
      cloudwatch_log_group         = aws_cloudwatch_log_group.log_group.name
      cloudwatch_log_stream_prefix = aws_cloudwatch_log_group.log_group.name
      cloudwatch_log_region        = var.region
    }
  )
}
