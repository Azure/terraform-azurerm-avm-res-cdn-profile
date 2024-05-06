export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv) # or set <subscription_id>
export ARM_TENANT_ID=$(az account show --query tenantId --output tsv) # or set <tenant_id>
export ARM_CLIENT_ID="ba61119e-ecef-4176-ade2-53db25293d63"
export ARM_CLIENT_SECRET="d018Q~Qh.NGyPMRnA1ZphogiJo~JzxGspG_r6cG5"

docker run --rm -v $(pwd):/src -w /src -v $HOME/.azure:/root/.azure -e TF_IN_AUTOMATION -e AVM_MOD_PATH=/src -e AVM_EXAMPLE=/examples/afd_default -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make afd_default

