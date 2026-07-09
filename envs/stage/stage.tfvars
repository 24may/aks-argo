# stage environment values - adjust as needed before first apply
environment         = "stage"
resource_group_name = "rg-aks-andrii-stage"
location            = "polandcentral"
kubernetes_version  = "1.34.8"

# mysql_root_password is sensitive and intentionally NOT set here.
# Provide it via:
#   export TF_VAR_mysql_root_password="YourStrongPassword"
# or a gitignored *.auto.tfvars file placed alongside this one.
