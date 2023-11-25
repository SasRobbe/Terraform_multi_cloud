output "azurerm_container_app_newgame" {
  description = "api newgame"
  value = "${azurerm_container_app.capprobbesas.latest_revision_fqdn}/hangman/new"
}

output "azurerm_container_app_guess" {
  description = "api guess letter"
  value = "${azurerm_container_app.capprobbesas.latest_revision_fqdn}/hangman/guess/(letter)"
}

output "azurerm_container_app_solution" {
  description = "api give solution"
  value = "${azurerm_container_app.capprobbesas.latest_revision_fqdn}/hangman/solution"
}

output "break" {
  value = "-----------------------------------------------------"
}

# Output the URL of the frontend
output "frontend_url" {
  description = "The URL of the frontend"
  value       = "${module.lb.this_lb_dns_name}"
}
