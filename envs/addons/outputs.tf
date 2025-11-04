# envs/addons/outputs.tf

# Bubble up module outputs so `terraform output` works at envs/addons
output "grafana_admin_user" {
  value       = module.monitoring.grafana_admin_user
  description = "Grafana admin user"
}

output "grafana_admin_password" {
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
  description = "Grafana admin password"
}
