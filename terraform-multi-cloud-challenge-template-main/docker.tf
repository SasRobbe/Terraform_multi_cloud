resource "docker_image" "hangmanrs" {
  name         = "hangmanrs:latest"
  build {
    context = "."
  }
}

resource "null_resource" "docker_build" {
  triggers = {
    image_id = docker_image.hangmanrs.id
  }

  provisioner "local-exec" {
    command = "docker tag ${docker_image.hangmanrs.name} ${azurerm_container_registry.acrsasrobbe.login_server}/hangmanrs:latest"
  }

  provisioner "local-exec" {
    command = "az acr login --name ${azurerm_container_registry.acrsasrobbe.name}"
  }

  provisioner "local-exec" {
    command = "docker push ${azurerm_container_registry.acrsasrobbe.login_server}/hangmanrs:latest"
  }
}