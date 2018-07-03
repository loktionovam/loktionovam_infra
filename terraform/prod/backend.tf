terraform {
  backend "gcs" {
    bucket = "infra-tf-state-prod"
    prefix = "terraform/state"
  }
}
