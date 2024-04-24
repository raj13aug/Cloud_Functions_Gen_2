variable "name" {
  description = "Name of a Google Cloud Project"
  default     = "cloudroot7-demo"
}

variable "id" {
  description = "ID of a Google Cloud Project. Can be omitted and will be generated automatically"
  default     = "mytesting-400910"
}

variable "project_id" {
  type        = string
  description = "project id"
  default     = "mytesting-400910"
}

variable "region" {
  type        = string
  description = "Region of policy "
  default     = "us-central1"
}

# variable "service_account_email" {
#   type    = string
#   default = "gen2-sa@mytesting-400910.iam.gserviceaccount.com"

# }