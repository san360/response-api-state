#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# deploy.sh — Deploy 3 Azure AI Foundry instances and populate .env
###############################################################################

TEMPLATE="infra/main.bicep"
PARAMS="infra/main.parameters.json"
DEPLOYMENT_NAME="response-api-stateless"
RESOURCE_GROUP="rg-response-api-stateless-test"

echo "============================================================"
echo "  Deploying Azure AI Foundry Instances for Stateless API Test"
echo "============================================================"

# Check prerequisites
command -v az >/dev/null 2>&1 || { echo "Error: Azure CLI (az) is not installed."; exit 1; }

# Ensure logged in
az account show >/dev/null 2>&1 || { echo "Not logged in. Running 'az login'..."; az login; }

echo ""
echo "Subscription: $(az account show --query name -o tsv)"
echo "Template    : $TEMPLATE"
echo ""

# Deploy at subscription level
echo "Starting Bicep deployment..."
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location swedencentral \
  --template-file "$TEMPLATE" \
  --parameters "$PARAMS" \
  --output table

echo ""
echo "Deployment complete. Retrieving resource details..."

# Get resource names from deployment outputs
INSTANCE1_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance1AiServicesName.value" -o tsv)
INSTANCE2_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance2AiServicesName.value" -o tsv)
INSTANCE3_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance3AiServicesName.value" -o tsv)

INSTANCE1_ENDPOINT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance1Endpoint.value" -o tsv)
INSTANCE2_ENDPOINT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance2Endpoint.value" -o tsv)
INSTANCE3_ENDPOINT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance3Endpoint.value" -o tsv)

INSTANCE1_HUB=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance1HubName.value" -o tsv)
INSTANCE2_HUB=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance2HubName.value" -o tsv)
INSTANCE3_HUB=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance3HubName.value" -o tsv)

INSTANCE1_PROJECT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance1ProjectName.value" -o tsv)
INSTANCE2_PROJECT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance2ProjectName.value" -o tsv)
INSTANCE3_PROJECT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.instance3ProjectName.value" -o tsv)

# Get API keys from AI Services accounts
KEY1=$(az cognitiveservices account keys list -n "$INSTANCE1_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
KEY2=$(az cognitiveservices account keys list -n "$INSTANCE2_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
KEY3=$(az cognitiveservices account keys list -n "$INSTANCE3_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)

# Write .env file
cat > .env <<EOF
# Azure AI Foundry Instance 1
AZURE_OPENAI_ENDPOINT_1=${INSTANCE1_ENDPOINT}
AZURE_OPENAI_API_KEY_1=${KEY1}

# Azure AI Foundry Instance 2
AZURE_OPENAI_ENDPOINT_2=${INSTANCE2_ENDPOINT}
AZURE_OPENAI_API_KEY_2=${KEY2}

# Azure AI Foundry Instance 3
AZURE_OPENAI_ENDPOINT_3=${INSTANCE3_ENDPOINT}
AZURE_OPENAI_API_KEY_3=${KEY3}

# Model deployment name (same across all instances)
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4-1-mini
EOF

echo ""
echo "============================================================"
echo "  .env file has been populated with endpoints and keys"
echo "============================================================"
echo ""
echo "Foundry Instance 1:"
echo "  AI Services : $INSTANCE1_NAME  →  $INSTANCE1_ENDPOINT"
echo "  Hub         : $INSTANCE1_HUB"
echo "  Project     : $INSTANCE1_PROJECT"
echo ""
echo "Foundry Instance 2:"
echo "  AI Services : $INSTANCE2_NAME  →  $INSTANCE2_ENDPOINT"
echo "  Hub         : $INSTANCE2_HUB"
echo "  Project     : $INSTANCE2_PROJECT"
echo ""
echo "Foundry Instance 3:"
echo "  AI Services : $INSTANCE3_NAME  →  $INSTANCE3_ENDPOINT"
echo "  Hub         : $INSTANCE3_HUB"
echo "  Project     : $INSTANCE3_PROJECT"
echo ""
echo "Next steps:"
echo "  1. pip install -r requirements.txt"
echo "  2. Open test_response_api_stateless.ipynb and run all cells"
echo ""
