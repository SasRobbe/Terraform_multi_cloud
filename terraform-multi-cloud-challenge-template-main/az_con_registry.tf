# Define an Azure Resource Group named "rgrobbesas" in the "East US" location.
resource "azurerm_resource_group" "rgrobbesas" {
  name     = "rgrobbesas"
  location = "East US"
}

# Create an Azure Container Registry (ACR) named "acrsasrobbe" in the same resource group and location as the resource group defined above.
resource "azurerm_container_registry" "acrsasrobbe" {
  name                     = "acrsasrobbe"
  resource_group_name      = azurerm_resource_group.rgrobbesas.name
  location                 = azurerm_resource_group.rgrobbesas.location
  sku                      = "Basic"
  admin_enabled            = true
}