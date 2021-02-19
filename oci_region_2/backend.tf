terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "phx-terraform.tfstate"
    region                      = "us-ashburn-1"
    endpoint                    = "https://idmnt6wveums.compat.objectstorage.us-ashburn-1.oraclecloud.com"
    shared_credentials_file     = "~/cloud-dev/oci-s3.credentials"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
