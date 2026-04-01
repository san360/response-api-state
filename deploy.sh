#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# deploy.sh — Deploy 3 Azure AI Services instances and populate .env
###############################################################################

TEMPLATE="infra/main.bicep"
PARAMS="infra/main.parameters.json"
DEPLOYMENT_NAME="response-api-stateless"
RESOURCE_GROUP="rg-response-api-stateless-test"

echo "============================================================"
echo "  Deploying Azure AI Services Instances for Stateless API Test"
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

# NOTE: These endpoints are the OpenAI-specific endpoints (*.openai.azure.com)
# required by the Response API. NOT the general *.cognitiveservices.azure.com.

# Get API keys from AI Services accounts
KEY1=$(az cognitiveservices account keys list -n "$INSTANCE1_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
KEY2=$(az cognitiveservices account keys list -n "$INSTANCE2_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
KEY3=$(az cognitiveservices account keys list -n "$INSTANCE3_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)

# Get Azure OpenAI instance details from deployment outputs
OAI1_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.openai1Name.value" -o tsv)
OAI2_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.openai2Name.value" -o tsv)
OAI3_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.openai3Name.value" -o tsv)

OAI1_ENDPOINT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.openai1Endpoint.value" -o tsv)
OAI2_ENDPOINT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.openai2Endpoint.value" -o tsv)
OAI3_ENDPOINT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.openai3Endpoint.value" -o tsv)

# Get API keys from Azure OpenAI accounts
OAI_KEY1=$(az cognitiveservices account keys list -n "$OAI1_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
OAI_KEY2=$(az cognitiveservices account keys list -n "$OAI2_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
OAI_KEY3=$(az cognitiveservices account keys list -n "$OAI3_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)

# Write .env file
cat > .env <<EOF
# ── Azure AI Services (Foundry) Instances ──

# Azure AI Services Instance 1
AZURE_OPENAI_ENDPOINT_1=${INSTANCE1_ENDPOINT}
AZURE_OPENAI_API_KEY_1=${KEY1}

# Azure AI Services Instance 2
AZURE_OPENAI_ENDPOINT_2=${INSTANCE2_ENDPOINT}
AZURE_OPENAI_API_KEY_2=${KEY2}

# Azure AI Services Instance 3
AZURE_OPENAI_ENDPOINT_3=${INSTANCE3_ENDPOINT}
AZURE_OPENAI_API_KEY_3=${KEY3}

# ── Azure OpenAI (kind: OpenAI) Instances ──

# Azure OpenAI Instance 1
AZURE_OAI_ENDPOINT_1=${OAI1_ENDPOINT}
AZURE_OAI_API_KEY_1=${OAI_KEY1}

# Azure OpenAI Instance 2
AZURE_OAI_ENDPOINT_2=${OAI2_ENDPOINT}
AZURE_OAI_API_KEY_2=${OAI_KEY2}

# Azure OpenAI Instance 3
AZURE_OAI_ENDPOINT_3=${OAI3_ENDPOINT}
AZURE_OAI_API_KEY_3=${OAI_KEY3}

# Model deployment names (same across all instances)
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4-1-mini
AZURE_OPENAI_DEPLOYMENT_NAME_2=gpt-5-mini
EOF

echo ""
echo "============================================================"
echo "  .env file has been populated with endpoints and keys"
echo "============================================================"
echo ""
echo "── AI Services (Foundry) Instances ──"
echo "Instance 1: $INSTANCE1_NAME  →  $INSTANCE1_ENDPOINT"
echo "Instance 2: $INSTANCE2_NAME  →  $INSTANCE2_ENDPOINT"
echo "Instance 3: $INSTANCE3_NAME  →  $INSTANCE3_ENDPOINT"
echo ""
echo "── Azure OpenAI Instances ──"
echo "OpenAI 1:   $OAI1_NAME  →  $OAI1_ENDPOINT"
echo "OpenAI 2:   $OAI2_NAME  →  $OAI2_ENDPOINT"
echo "OpenAI 3:   $OAI3_NAME  →  $OAI3_ENDPOINT"
echo ""
echo "Next steps:"
echo "  1. pip install -r requirements.txt"
echo "  2. Open test_response_api_stateless.ipynb and run all cells"
echo ""
