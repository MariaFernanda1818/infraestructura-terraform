// Define la versión mínima de Terraform y los proveedores necesarios
terraform {
  // Especifica que se necesita Terraform 1.5.0 o superior
  required_version = ">= 1.5.0"

  // Declara los proveedores que usaremos y sus versiones
  required_providers {
    aws = {
      source  = "hashicorp/aws"  // Origen oficial del proveedor AWS
      version = "~> 5.0"         // Compatibilidad con la serie 5.x
    }
    azurerm = {
      source  = "hashicorp/azurerm"  // Origen oficial del proveedor Azure
      version = "~> 3.0"             // Compatibilidad con la serie 3.x
    }
  }
}

// Configuración del proveedor AWS
provider "aws" {
  region = "us-east-1"  // Región donde se crearán los recursos AWS
}

// Configuración del proveedor Azure
provider "azurerm" {
  features {}  // Requerido para habilitar el proveedor (puede quedar vacío)
}
