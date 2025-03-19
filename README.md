# bicep-flex

Deploying a simple crud app to aws using azure.

download the repository and add the run these commands

# login:

az login
az account set --subscription "Azure for Students" # Ensure you're using the free student subscription

# Create resource Group

az group create -l "Sweden Central" -n r0984339-rg

# Deploy it

az deployment group create --resource-group r0984339-rg --template-file acr.bicep

# Log in to ACR

az acr login --name r0984339acr

# Docker build

Docker build -t r0984399-crud-app .

# Tag the image

docker tag r0984339-crud-app r0984339acr.azurecr.io/crud-app:latest

# Push the image

docker push r0984339acr.azurecr.io/crud-app:latest

# deploy the bicep template

az deployment group create --resource-group r0984339-rg --template-file main.bicep
