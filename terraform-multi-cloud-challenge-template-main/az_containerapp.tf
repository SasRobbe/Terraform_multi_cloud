# Define an Azure Container App Environment named "caEnvRobbeSas" associated with the resource group defined earlier.
resource "azurerm_container_app_environment" "caEnvRobbeSas" {
  name               = "Example-Environment"
  location           = azurerm_resource_group.rgrobbesas.location  # Use the same location as the resource group.
  resource_group_name = azurerm_resource_group.rgrobbesas.name    # Link to the resource group created earlier.
}

# Retrieve information about the Azure Container Registry (ACR) named "acrsasrobbe."
data "azurerm_container_registry" "acrsasrobbe" {
  name                = "acrsasrobbe"
  resource_group_name = "rgrobbesas"  # Specify the resource group name directly.
  depends_on          = [azurerm_container_registry.acrsasrobbe]  # Ensure the ACR is created before proceeding.
}

# Create an Azure Container App named "capprobbesas" within the same resource group.
resource "azurerm_container_app" "capprobbesas" {
  name                              = "capprobbesas"
  resource_group_name               = azurerm_resource_group.rgrobbesas.name  # Use the same resource group.
  container_app_environment_id      = azurerm_container_app_environment.caEnvRobbeSas.id  # Link to the Container App Environment.
  revision_mode                     = "Single"  # Set the revision mode to "Single."

  # Define a secret for the Container App with the name "password" and retrieve the ACR admin password.
  secret {
    name  = "password"
    value = data.azurerm_container_registry.acrsasrobbe.admin_password
  }

  # Configure the ACR registry information for the Container App.
  registry {
    server               = data.azurerm_container_registry.acrsasrobbe.login_server
    username             = data.azurerm_container_registry.acrsasrobbe.admin_username
    password_secret_name = "password"  # Use the "password" secret for authentication.
  }

  # Define ingress settings for the Container App, enabling external access on port 8080.
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080

    # Configure traffic weight with 100% to the latest revision.
    traffic_weight {
      percentage       = 100
      latest_revision  = true
    }
  }

  # Define the template for the Container App, specifying the container image, CPU, and memory.
  template {
    container {
      name  = "capprobbesas"
      image = "${data.azurerm_container_registry.acrsasrobbe.login_server}/hangmanrs:latest"
      cpu   = "0.25"
      memory = "0.5Gi"
    }
  }

  # Specify a dependency on a "null_resource.docker_build", this assures the container image will be build and pushed first.
  depends_on = [docker_image.hangmanrs, null_resource.docker_build]
}
