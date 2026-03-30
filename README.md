# Azure OpenAI Response API — Stateless Cross-Instance Test

## Overview

This project tests whether the **Azure OpenAI Response API** state (i.e. `response_id` and `previous_response_id`) is portable across **different Azure OpenAI (Foundry) instances**. It answers the question:

> **If I create a response on Foundry Instance A, can I retrieve or chain that response from Foundry Instance B or C?**

Three Azure OpenAI resources are deployed in **Sweden Central**, each with a **GPT-4.1-mini** model. The Jupyter notebook runs a comprehensive test matrix covering both synchronous and background (`background=True`) modes.

## Architecture

```
┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│  Azure OpenAI        │     │  Azure OpenAI        │     │  Azure OpenAI        │
│  Instance 1          │     │  Instance 2          │     │  Instance 3          │
│  (Sweden Central)    │     │  (Sweden Central)    │     │  (Sweden Central)    │
│                      │     │                      │     │                      │
│  gpt-4.1-mini        │     │  gpt-4.1-mini        │     │  gpt-4.1-mini        │
└──────────┬───────────┘     └──────────┬───────────┘     └──────────┬───────────┘
           │                            │                            │
           └────────────────┬───────────┘────────────────────────────┘
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
- **Azure subscription** with permissions to create Cognitive Services resources
- **Python 3.10+**
- Sufficient quota for GPT-4.1-mini in Sweden Central

## Project Structure

```
response-api-state/
├── infra/
│   ├── main.bicep                  # Main Bicep template (subscription-scoped)
│   ├── main.parameters.json        # Deployment parameters
│   └── modules/
│       └── openai.bicep            # Azure OpenAI resource module
├── test_response_api_stateless.ipynb  # Jupyter notebook with all tests
├── deploy.sh                       # Deployment script
├── env.example                     # Environment variable template
├── .env                            # Actual environment variables (git-ignored)
├── .gitignore
├── requirements.txt
└── README.md                       # This file
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

# Get resource names from deployment output
INSTANCE1_NAME=$(az deployment sub show --name main --query "properties.outputs.instance1Name.value" -o tsv)
INSTANCE2_NAME=$(az deployment sub show --name main --query "properties.outputs.instance2Name.value" -o tsv)
INSTANCE3_NAME=$(az deployment sub show --name main --query "properties.outputs.instance3Name.value" -o tsv)

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

## Expected Results

Based on Azure's architecture, each Azure OpenAI resource maintains **its own response storage**. Therefore:

- **Test 1** (same-instance baseline) → **PASS**
- **Tests 2–3** (cross-instance retrieve/chain) → **Expected to FAIL** (response not found on different resource)
- **Test 4** (background baseline) → **PASS**
- **Tests 5–6** (background cross-instance) → **Expected to FAIL** (same reason)

If all tests pass, it would indicate that Azure shares response state across resources in the same region — which would be a significant finding.

## Cleanup

To delete all deployed resources:

```bash
az group delete --name rg-response-api-stateless-test --yes --no-wait
```

## References

- [Azure OpenAI Responses API Documentation](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/responses)
- [Azure OpenAI REST API Reference](https://learn.microsoft.com/en-us/azure/foundry/openai/latest)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
