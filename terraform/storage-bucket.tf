provider "google" {
  version = "3.6.0"
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "storage-bucket" {
  name     = join("-", ["kubernetes-tf-state-bucket", var.environment])
  location = "EU"
}


output "storage-bucket_url" {
  value = google_storage_bucket.storage-bucket.url
}
