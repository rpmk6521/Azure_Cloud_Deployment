winget install HashiCorp.Terraform

terraform -version

winget install Microsoft.AzureCLI

az authentication to azure cloud 
 You can set these environment variables to bypass the need for the az command: 

ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_SUBSCRIPTION_ID
ARM_TENANT_ID
az login --tenant 621daa10-ac93-4381-aeec-7d7491b91670
gmail: techonichiveaisolutions@gmail.com
pwd  : Pala###@2027
az account list --output table
az cognitiveservices model list --location eastus --query "[?model.name=='whisper'].{Name:model.name, SKU:model.skus}"

purge azureopenai service 
# Run this command in Azure PowerShell
Remove-AzResource -ResourceId "/subscriptions/{subId}/providers/Microsoft.CognitiveServices/locations/{location}/resourceGroups/{rgName}/deletedAccounts/{accountName}" -ApiVersion "2021-04-30"


# Run this command in Azure CLI
az resource delete --ids "/subscriptions/{subId}/providers/Microsoft.CognitiveServices/locations/{location}/resourceGroups/{rgName}/deletedAccounts/{accountName}"
