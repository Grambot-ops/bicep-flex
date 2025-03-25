# Bicep-Flex: Flask CRUD App Deployment on Azure

This project demonstrates deploying a simple Flask-based CRUD (Create, Read, Update, Delete) application to Azure using Bicep infrastructure-as-code. The architecture includes an Azure Container Registry (ACR) to store the Docker image, an Azure Container Instance (ACI) to run the application, and an Azure Load Balancer to provide public access. The application is placed within a private subnet, and the load balancer is in a public subnet for security.

## Project Overview

This project showcases the following concepts:

- **Infrastructure as Code (IaC):** Using Bicep to define and deploy the entire infrastructure.
- **Containerization:** Using Docker to package the Flask application and its dependencies.
- **Container Registry:** Using Azure Container Registry (ACR) to store and manage the Docker image.
- **Container Orchestration (lightweight):** Using Azure Container Instances (ACI) for a simple container deployment.
- **Networking:** Creating a Virtual Network (VNet) with separate public and private subnets.
- **Security:** Using Network Security Groups (NSGs) to control network traffic.
- **Load Balancing:** Using Azure Load Balancer to distribute traffic to the container instance.
- **Monitoring:** Integrating with Azure Log Analytics for container logs.
- **Pull-Only Access to ACR**: Creates a token for ACR so it could access pull only

## Architecture Diagram


![Image](https://github.com/user-attachments/assets/be16a092-d4db-4380-a179-1a9ab114ac3d)

![Image](https://github.com/user-attachments/assets/bf052f0b-dd03-43ac-a204-bfba652ca54e)

**Components:**

- **Azure Container Registry (ACR):** A private registry to store the Docker image of the Flask application.
- **Azure Container Instance (ACI):** Runs the containerized Flask application. It's placed in the _private_ subnet for improved security. ACI is suitable for this simple, single-container application.
- **Azure Load Balancer:** Provides a public endpoint for accessing the application. It forwards traffic to the ACI instance running in the private subnet.
- **Virtual Network (VNet):** A logically isolated network in Azure. This project uses a VNet with two subnets:
  - **Public Subnet:** Contains the Azure Load Balancer, which has a public IP address.
  - **Private Subnet:** Contains the Azure Container Instance. ACI instances in this subnet do not have public IP addresses directly exposed.
- **Network Security Groups (NSGs):** Act as virtual firewalls to control inbound and outbound network traffic to the subnets. Separate NSGs are used for the public and private subnets.
- **Log Analytics Workspace**: Centralized location for gathering and querying the logs of our application.

## Prerequisites

- An active Azure subscription (e.g., "Azure for Students"). You can sign up for a free account if you don't have one.
- Azure CLI installed and configured. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Docker Desktop installed and running. [Install Docker Desktop](https://www.docker.com/products/docker-desktop)
- Git installed. [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- Basic knowledge about Bicep, ACR, ACI, and containerization.

## Deployment Steps

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/Grambot-ops/bicep-flex
    cd bicep-flex
    ```

2.  **Login to Azure:**

    ```bash
    az login
    az account set --subscription "Azure for Students"  # Or your subscription name
    ```

3.  **Create a Resource Group:**

    ```bash
    az group create -l "Sweden Central" -n r0984339-rg
    ```

4.  **Deploy the Azure Container Registry (ACR):**

    ```bash
    az deployment group create --resource-group r0984339-rg --template-file acr.bicep
    ```

    This script creates:

    - The Azure Container Registry.
    - A token with read-only (pull) permissions.

5.  **Login to ACR:**

    ```bash
    az acr login --name r0984339acr
    ```

6.  **Build and Push the Docker Image:**

    - This step builds the container, tags and pushes it to our registry

    ```bash
    # Build the Docker image
    docker build -t r0984339-crud-app .

    # Tag the image for ACR
    docker tag r0984339-crud-app r0984339acr.azurecr.io/crud-app:latest

    # Push the image to ACR
    docker push r0984339acr.azurecr.io/crud-app:latest
    ```

7.  **Deploy the Main Infrastructure (ACI, VNet, Load Balancer):**

    ```bash
    az deployment group create --resource-group r0984339-rg --template-file main.bicep
    ```

    This script deploys the ACI, Load Balancer, VNet, and NSGs. It references the existing ACR created in the previous step. It takes care of getting ACR credentials automatically to use in the ACI deployment.

8.  **Get the Public IP Address:**

    ```bash
    az network public-ip show --resource-group r0984339-rg --name r0984339-lb-publicip --query ipAddress --output tsv
    ```

    This command retrieves the public IP address of the load balancer. Open this IP address in your web browser to access the Flask application.

## Testing the Application

Once the deployment is complete, open a web browser and navigate to the public IP address of the load balancer (obtained in step 8). You should see the Flask application's main page. You can then test the CRUD operations.

## Troubleshooting

- **ACI Container State:** Check the state of the container instance:

  ```bash
  az container show --name r0984339aci -g r0984339-rg --query "containers[0].instanceView.currentState.state"
  ```

- **ACI Container Logs:** View the logs from the container:

  ```bash
  az container logs --name r0984339aci -g r0984339-rg
  ```

- **Load Balancer Probe Status:** Check the health probe status:

  ```bash
  az network lb probe list --lb-name r0984339-lb -g r0984339-rg -o table
  ```

- **Load Balancer Backend Pool** Check Load Balancer address-pool.

  ```bash
  az network lb address-pool show --lb-name r0984339-lb -g r0984339-rg --name backendPool_PrivateAdd
  ```

- **Application Startup Issues:** The Dockerfile includes database initialization steps (`flask db init`, `migrate`, `upgrade`). If the application doesn't start correctly, check the container logs for errors related to database setup. The `livenessProbe` in the `main.bicep` file is configured to check the root path (`/`) of your Flask application. Make sure this path returns a successful HTTP status code (e.g., 200 OK) when the application is running correctly. The initial delay for the liveness probe is set to 60 seconds to give the Flask app time to initialize.

- **Networking Issues:** Double-check the NSG rules to ensure that traffic is allowed from the load balancer's public subnet to the ACI's private subnet on port 80. Also ensure ACI can access ACR (Outbound on port 443 to the `AzureContainerRegistry` service tag).

- **Azure Resource Explorer:** Use this tool in the Azure Portal (search "Resource Explorer") for more detailed information on the state and Properties of the components if something is misconfigured.

## Cleanup

To remove all the deployed resources, delete the resource group:

```bash
az group delete --name r0984339-rg --yes --no-wait
```
