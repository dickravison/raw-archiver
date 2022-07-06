variable "region" {
  type        = string
  description = "AWS region to deploy the application in"
}

variable "project_name" {
  type        = string
  description = "Name of the project for this application"
}

variable "layer_name" {
  type        = string
  description = "Name of existing lambda layer to use for application dependencies"
}

variable "state_machine_name" {
  type        = string
  description = "Name to give to the state machine"
}