// PRIVATE REGISTRY SETTINGS 

resource "aws_ecr_registry_scanning_configuration" "private_registry" {
  scan_type = "BASIC"
}
