# Azure OpenAI Response API — Stateless Cross-Instance Test (Azure AI Foundry)

## Overview

This project tests whether the **Azure OpenAI Response API** state (i.e. `response_id` and `previous_response_id`) is portable across **different Azure AI Foundry instances**. It answers the question:

> **If I create a response on Foundry Instance A, can I retrieve or chain that response from Foundry Instance B or C?**

Three **Azure AI Foundry** setups are deployed in **Sweden Central**, each consisting of:
- **AI Services account** (kind: `AIServices`) with a **GPT-4.1-mini** model deployment
- **AI Foundry Hub** (linked to Storage Account + Key Vault)
- **AI Foundry Project** (linked to the Hub)
- **AI Services connection** on the Hub

The Jupyter notebook runs a comprehensive test matrix covering both synchronous and background (`background=True`) modes.

## Architecture

```
┌──────────────────────────────┐  ┌──────────────────────────────┐  ┌──────────────────────────────┐
│  Azure AI Foundry 1          │  │  Azure AI Foundry 2          │  │  Azure AI Foundry 3          │
│  (Sweden Central)            │  │  (Sweden Central)            │  │  (Sweden Central)            │
│                              │  │                              │  │                              │
│  ┌────────────────────────┐  │  │  ┌────────────────────────┐  │  │  ┌────────────────────────┐  │
│  │ AI Services (AIServices) │  │  │  │ AI Services (AIServices) │  │  │  │ AI Services (AIServices) │  │
│  │ gpt-4.1-mini             │  │  │  │ gpt-4.1-mini             │  │  │  │ gpt-4.1-mini             │  │
│  └────────────────────────┘  │  │  └────────────────────────┘  │  │  └────────────────────────┘  │
│  ┌────────────────────────┐  │  │  ┌────────────────────────┐  │  │  ┌────────────────────────┐  │
│  │ Foundry Hub              │  │  │  │ Foundry Hub              │  │  │  │ Foundry Hub              │  │
│  │   └─ Foundry Project      │  │  │  │   └─ Foundry Project      │  │  │  │   └─ Foundry Project      │  │
│  │   └─ AI Svc Connection   │  │  │  │   └─ AI Svc Connection   │  │  │  │   └─ AI Svc Connection   │  │
│  └────────────────────────┘  │  │  └────────────────────────┘  │  │  └────────────────────────┘  │
│  Storage + Key Vault        │  │  Storage + Key Vault        │  │  Storage + Key Vault        │
└──────────────┬───────────────┘  └──────────────┬───────────────┘  └──────────────┬───────────────┘
               │                              │                              │
               └──────────────┬───────────────┘───────────────┘
                              │
                     ┌────────▼────────┐
                     │  Jupyter        │
                     │  Notebook       │
                     │  (Test Runner)  │
                     └─────────────────┘
```

## Test Matrix

| # | Test | Mode | Description |
|---|------|------|-------------|
| 1 | Baseline | Sync | Create on Instance 1, retrieve from Instance 1 |
| 2a | Cross-Instance Retrieve | Sync | Create on Instance 1, retrieve from Instance 2 |
| 2b | Cross-Instance Retrieve | Sync | Create on Instance 1, retrieve from Instance 3 |
| 3a | Cross-Instance Chaining | Sync | Create on Instance 1, chain (`previous_response_id`) from Instance 2 |
| 3b | Cross-Instance Chaining | Sync | Create on Instance 1, chain (`previous_response_id`) from Instance 3 |
| 4 | Background Baseline | Background | Create with `background=True` on Instance 1, poll & retrieve from Instance 1 |
| 5a | Background Cross-Instance Retrieve | Background | Create with `background=True` on Instance 1, retrieve from Instance 2 |
| 5b | Background Cross-Instance Retrieve | Background | Create with `background=True` on Instance 1, retrieve from Instance 3 |
| 6a | Background Cross-Instance Chaining | Background | Create with `background=True` on Instance 1, chain from Instance 2 |
| 6b | Background Cross-Instance Chaining | Background | Create with `background=True` on Instance 1, chain from Instance 3 |

## Prerequisites

- **Azure CLI** installed and authenticated (`az login`)
- **Azure subscription** with Owner or Contributor permissions to create:
  - Cognitive Services (AI Services) resources
  - Machine Learning Services (Foundry Hub/Project) resources  
  - Storage Accounts and Key Vaults
- **Python 3.10+**
- Sufficient quota for GPT-4.1-mini in Sweden Central

## Project Structure

```
response-api-state/
├── infra/
│   ├── main.bicep                      # Main Bicep template (subscription-scoped)
│   ├── main.parameters.json            # Deployment parameters
│   └── modules/
│       └── foundry-instance.bicep       # Azure AI Foundry instance module
│                                        # (AI Services + Hub + Project + Storage + KV)
├── test_response_api_stateless.ipynb    # Jupyter notebook with all tests
├── deploy.sh                           # Deployment script
├── env.example                         # Environment variable template
├── .env                                # Actual environment variables (git-ignored)
├── .gitignore
├── requirements.txt
└── README.md                           # This file
```

## Deployment

### 1. Deploy Infrastructure

Run the deployment script:

```bash
chmod +x deploy.sh
./deploy.sh
```

Or deploy manually:

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Deploy at subscription level
az deployment sub create \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### 2. Retrieve Keys & Update `.env`

After deployment, the script outputs the endpoint names. Retrieve the API keys:

```bash
RESOURCE_GROUP="rg-response-api-stateless-test"

# Get AI Services names from deployment output
INSTANCE1_NAME=$(az deployment sub show --name response-api-stateless --query "properties.outputs.instance1AiServicesName.value" -o tsv)
INSTANCE2_NAME=$(az deployment sub show --name response-api-stateless --query "properties.outputs.instance2AiServicesName.value" -o tsv)
INSTANCE3_NAME=$(az deployment sub show --name response-api-stateless --query "properties.outputs.instance3AiServicesName.value" -o tsv)

# Retrieve API keys
KEY1=$(az cognitiveservices account keys list -n "$INSTANCE1_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
KEY2=$(az cognitiveservices account keys list -n "$INSTANCE2_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)
KEY3=$(az cognitiveservices account keys list -n "$INSTANCE3_NAME" -g "$RESOURCE_GROUP" --query "key1" -o tsv)

echo "Keys retrieved. Update your .env file."
```

Update the `.env` file with the endpoints and keys.

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 4. Run the Notebook

Open `test_response_api_stateless.ipynb` in VS Code or JupyterLab and run all cells.

## Key API Features Tested

### Response API — `previous_response_id`

The Response API allows chaining conversations by passing a `previous_response_id`:

```python
response = client.responses.create(
    model="gpt-4-1-mini",
    input="What is the capital of France?"
)

# Chain using the response ID
second = client.responses.create(
    model="gpt-4-1-mini",
    previous_response_id=response.id,
    input=[{"role": "user", "content": "What is the population?"}]
)
```

### Background Mode

Background mode runs requests asynchronously — useful for long-running tasks:

```python
response = client.responses.create(
    model="gpt-4-1-mini",
    input="Explain quantum physics",
    background=True  # Returns immediately with queued status
)

# Poll until complete
while response.status in ("queued", "in_progress"):
    time.sleep(2)
    response = client.responses.retrieve(response.id)
```

> **Note:** Background mode requires `store=True` (the default). Stateless (`store=False`) requests cannot use background mode.

### Retrieve a Response

```python
response = client.responses.retrieve("resp_abc123...")
```

## Important: Endpoint Clarification

The **Response API** requires the **OpenAI-specific endpoint** of the AI Services account:

```
https://{customSubDomainName}.openai.azure.com/openai/v1/
```

This is **NOT** the Foundry project endpoint and **NOT** the general Cognitive Services endpoint (`*.cognitiveservices.azure.com`). Even though the infrastructure uses Azure AI Foundry (Hub + Project), the actual model inference and Response API calls go through the OpenAI endpoint of the underlying AI Services account.

The Foundry Hub and Project are **organizational/governance constructs** — they manage access, connections, and project isolation. The model deployment lives on the AI Services account, and the Response API uses that account's OpenAI endpoint directly.

## Expected Results

Based on Azure's architecture, each Azure AI Foundry instance maintains **its own response storage** via its underlying AI Services account. Therefore:

- **Test 1** (same-instance baseline) → **PASS**
- **Tests 2–3** (cross-instance retrieve/chain) → **Expected to FAIL** (response not found on different resource)
- **Test 4** (background baseline) → **PASS**
- **Tests 5–6** (background cross-instance) → **Expected to FAIL** (same reason)

If all tests pass, it would indicate that Azure shares response state across AI Services accounts in the same region — which would be a significant finding.

## Resources Deployed Per Instance

Each of the 3 Foundry instances creates:

| Resource | Type | Purpose |
|----------|------|--------|
| AI Services | `Microsoft.CognitiveServices/accounts` (kind: `AIServices`) | Hosts the GPT-4.1-mini model deployment; provides the OpenAI endpoint (`*.openai.azure.com`) |
| Model Deployment | `Microsoft.CognitiveServices/accounts/deployments` | GPT-4.1-mini with GlobalStandard SKU |
| Foundry Hub | `Microsoft.MachineLearningServices/workspaces` (kind: `hub`) | Organizational container for AI projects |
| Foundry Project | `Microsoft.MachineLearningServices/workspaces` (kind: `project`) | Scoped workspace within the hub |
| AI Services Connection | `Microsoft.MachineLearningServices/workspaces/connections` | Links the Hub to the AI Services account |
| Storage Account | `Microsoft.Storage/storageAccounts` | Required dependency for the Hub |
| Key Vault | `Microsoft.KeyVault/vaults` | Required dependency for the Hub |

## Cleanup

To delete all deployed resources:

```bash
az group delete --name rg-response-api-stateless-test --yes --no-wait
```

## References

- [Azure OpenAI Responses API Documentation](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/responses)
- [Azure AI Foundry Hub — Bicep Template](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/create-azure-ai-hub-template)
- [Azure OpenAI REST API Reference](https://learn.microsoft.com/en-us/azure/foundry/openai/latest)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
