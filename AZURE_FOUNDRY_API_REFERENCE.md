# Azure AI Foundry — Comprehensive API Reference & Statefulness Analysis

> **Source**: Analysis of the APIM gateway OpenAPI spec (`ais-fnd1-6ohufxbigpdyo.openapi.yaml`) cross-referenced with
> [Azure OpenAI in Microsoft Foundry Models REST API (GA)](https://learn.microsoft.com/en-us/azure/foundry/openai/reference) and
> [Preview reference](https://learn.microsoft.com/en-us/azure/foundry/openai/reference-preview).
>
> **Base URL (APIM)**: `https://apim-lab-sdc-001.azure-api.net/ai/openai/v1`
>
> **Date**: March 2026

---

## Table of Contents

1. [Key Concepts — Stateless vs Stateful](#key-concepts--stateless-vs-stateful)
2. [Summary Matrix](#summary-matrix)
3. [Detailed API Groups](#detailed-api-groups)
   - [Chat Completions](#1-chat-completions)
   - [Completions (Legacy)](#2-completions-legacy)
   - [Embeddings](#3-embeddings)
   - [Responses API](#4-responses-api)
   - [Models](#5-models)
   - [Files](#6-files)
   - [Containers](#7-containers)
   - [Vector Stores](#8-vector-stores)
   - [Fine-Tuning Jobs](#9-fine-tuning-jobs)
   - [Evals](#10-evals)
   - [Audio — Transcription, Translation, Speech](#11-audio--transcription-translation-speech)
   - [Image Generation](#12-image-generation)
   - [Assistants (Deprecated)](#13-assistants-deprecated)
   - [Threads, Messages & Runs (Deprecated)](#14-threads-messages--runs-deprecated)
   - [Realtime Sessions](#15-realtime-sessions)
4. [APIs Missing from the APIM Gateway Spec](#apis-missing-from-the-apim-gateway-spec)
5. [Cross-Instance Portability Guide](#cross-instance-portability-guide)
6. [References](#references)

---

## Key Concepts — Stateless vs Stateful

| Classification | Definition | Cross-Instance Behavior |
|---|---|---|
| **Stateless** | The operation computes a result on-the-fly without creating or reading any server-side resource. No resource ID is returned or required. | **Works across any Foundry instance** — you can freely load-balance, failover, or round-robin these calls between instances. |
| **Stateful (Write)** | The operation **creates or modifies** a server-side resource (file, vector store, eval, etc.) and returns a resource ID bound to that specific instance. | **Instance-bound** — the returned resource ID exists only on the instance that created it. Using it on another instance returns `404 Not Found`. |
| **Stateful (Read/Delete)** | The operation **reads or deletes** a resource by its ID. | **Instance-bound** — the resource ID must belong to the same instance. Cross-instance lookups fail with `404`. |
| **Conditionally Stateful** | Behavior depends on a request parameter (e.g., `store: true/false`). | Stateless when storage is disabled; stateful when enabled. |

---

## Summary Matrix

> **Legend**: ✅ = In APIM Spec | ❌ = Missing from APIM Spec (available in Azure Foundry public API)

| # | API Group | Endpoint Pattern | Method | Operation | State | In APIM Spec |
|---|---|---|---|---|---|---|
| | **CHAT COMPLETIONS** | | | | | |
| 1 | Chat Completions | `/chat/completions` | POST | Create chat completion | **Stateless** | ✅ |
| | **COMPLETIONS (LEGACY)** | | | | | |
| 2 | Completions | `/deployments/{id}/completions` | POST | Create completion | **Stateless** | ❌ |
| | **EMBEDDINGS** | | | | | |
| 3 | Embeddings | `/embeddings` | POST | Create embedding | **Stateless** | ✅ |
| | **RESPONSES API** | | | | | |
| 4 | Responses | `/responses` | POST | Create response | **Conditional** ¹ | ✅ |
| 5 | Responses | `/responses/{response_id}` | GET | Retrieve response | **Stateful (Read)** | ✅ |
| 6 | Responses | `/responses/{response_id}` | DELETE | Delete response | **Stateful (Delete)** | ✅ |
| 7 | Responses | `/responses/{response_id}/input_items` | GET | List input items | **Stateful (Read)** | ✅ |
| | **MODELS** | | | | | |
| 8 | Models | `/models` | GET | List models | **Stateless** ² | ✅ |
| 9 | Models | `/models/{model}` | GET | Retrieve model | **Stateless** ² | ✅ |
| | **FILES** | | | | | |
| 10 | Files | `/files` | POST | Upload file | **Stateful (Write)** | ✅ |
| 11 | Files | `/files` | GET | List files | **Stateful (Read)** | ✅ |
| 12 | Files | `/files/{file_id}` | GET | Retrieve file metadata | **Stateful (Read)** | ✅ |
| 13 | Files | `/files/{file_id}` | DELETE | Delete file | **Stateful (Delete)** | ✅ |
| 14 | Files | `/files/{file_id}/content` | GET | Download file content | **Stateful (Read)** | ✅ |
| | **CONTAINERS** | | | | | |
| 15 | Containers | `/containers` | GET | List containers | **Stateful (Read)** | ✅ |
| 16 | Containers | `/containers` | POST | Create container | **Stateful (Write)** | ✅ |
| 17 | Containers | `/containers/{container_id}` | GET | Retrieve container | **Stateful (Read)** | ✅ |
| 18 | Containers | `/containers/{container_id}` | DELETE | Delete container | **Stateful (Delete)** | ✅ |
| 19 | Containers | `/containers/{container_id}/files` | POST | Create container file | **Stateful (Write)** | ✅ |
| 20 | Containers | `/containers/{container_id}/files` | GET | List container files | **Stateful (Read)** | ✅ |
| 21 | Containers | `/containers/{container_id}/files/{file_id}` | GET | Retrieve container file | **Stateful (Read)** | ✅ |
| 22 | Containers | `/containers/{container_id}/files/{file_id}` | DELETE | Delete container file | **Stateful (Delete)** | ✅ |
| 23 | Containers | `/containers/{container_id}/files/{file_id}/content` | GET | Retrieve container file content | **Stateful (Read)** | ✅ |
| | **VECTOR STORES** | | | | | |
| 24 | Vector Stores | `/vector_stores` | GET | List vector stores | **Stateful (Read)** | ✅ |
| 25 | Vector Stores | `/vector_stores` | POST | Create vector store | **Stateful (Write)** | ✅ |
| 26 | Vector Stores | `/vector_stores/{vector_store_id}` | GET | Retrieve vector store | **Stateful (Read)** | ✅ |
| 27 | Vector Stores | `/vector_stores/{vector_store_id}` | POST | Modify vector store | **Stateful (Write)** | ✅ |
| 28 | Vector Stores | `/vector_stores/{vector_store_id}` | DELETE | Delete vector store | **Stateful (Delete)** | ✅ |
| 29 | Vector Stores | `/vector_stores/{vs_id}/files` | GET | List vector store files | **Stateful (Read)** | ✅ |
| 30 | Vector Stores | `/vector_stores/{vs_id}/files` | POST | Create vector store file | **Stateful (Write)** | ✅ |
| 31 | Vector Stores | `/vector_stores/{vs_id}/files/{file_id}` | GET | Retrieve vector store file | **Stateful (Read)** | ✅ |
| 32 | Vector Stores | `/vector_stores/{vs_id}/files/{file_id}` | POST | Update vector store file attributes | **Stateful (Write)** | ✅ |
| 33 | Vector Stores | `/vector_stores/{vs_id}/files/{file_id}` | DELETE | Delete vector store file | **Stateful (Delete)** | ✅ |
| 34 | Vector Stores | `/vector_stores/{vs_id}/file_batches` | POST | Create file batch | **Stateful (Write)** | ✅ |
| 35 | Vector Stores | `/vector_stores/{vs_id}/file_batches/{batch_id}` | GET | Retrieve file batch | **Stateful (Read)** | ✅ |
| 36 | Vector Stores | `/vector_stores/{vs_id}/file_batches/{batch_id}/cancel` | POST | Cancel file batch | **Stateful (Write)** | ✅ |
| 37 | Vector Stores | `/vector_stores/{vs_id}/file_batches/{batch_id}/files` | GET | List files in batch | **Stateful (Read)** | ✅ |
| | **FINE-TUNING** | | | | | |
| 38 | Fine-Tuning | `/fine_tuning/jobs` | POST | Create fine-tuning job | **Stateful (Write)** | ✅ |
| 39 | Fine-Tuning | `/fine_tuning/jobs` | GET | List fine-tuning jobs | **Stateful (Read)** | ✅ |
| 40 | Fine-Tuning | `/fine_tuning/jobs/{job_id}` | GET | Retrieve fine-tuning job | **Stateful (Read)** | ✅ |
| 41 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/cancel` | POST | Cancel fine-tuning job | **Stateful (Write)** | ✅ |
| 42 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/checkpoints` | GET | List checkpoints | **Stateful (Read)** | ✅ |
| 43 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/checkpoints/{cp_id}/copy` | POST | Copy checkpoint | **Stateful (Write)** | ✅ |
| 44 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/checkpoints/{cp_id}/copy` | GET | Get checkpoint copy status | **Stateful (Read)** | ✅ |
| 45 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/events` | GET | List events | **Stateful (Read)** | ✅ |
| 46 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/pause` | POST | Pause fine-tuning job | **Stateful (Write)** | ✅ |
| 47 | Fine-Tuning | `/fine_tuning/jobs/{job_id}/resume` | POST | Resume fine-tuning job | **Stateful (Write)** | ✅ |
| 48 | Fine-Tuning | `/fine_tuning/alpha/graders/run` | POST | Run grader | **Stateless** | ✅ |
| 49 | Fine-Tuning | `/fine_tuning/alpha/graders/validate` | POST | Validate grader | **Stateless** | ✅ |
| | **EVALS** | | | | | |
| 50 | Evals | `/evals` | GET | List evaluations | **Stateful (Read)** | ✅ |
| 51 | Evals | `/evals` | POST | Create evaluation | **Stateful (Write)** | ✅ |
| 52 | Evals | `/evals/{eval_id}` | GET | Retrieve evaluation | **Stateful (Read)** | ✅ |
| 53 | Evals | `/evals/{eval_id}` | POST | Update evaluation | **Stateful (Write)** | ✅ |
| 54 | Evals | `/evals/{eval_id}` | DELETE | Delete evaluation | **Stateful (Delete)** | ✅ |
| 55 | Evals | `/evals/{eval_id}/runs` | GET | List eval runs | **Stateful (Read)** | ✅ |
| 56 | Evals | `/evals/{eval_id}/runs` | POST | Create eval run | **Stateful (Write)** | ✅ |
| 57 | Evals | `/evals/{eval_id}/runs/{run_id}` | GET | Retrieve eval run | **Stateful (Read)** | ✅ |
| 58 | Evals | `/evals/{eval_id}/runs/{run_id}` | POST | Cancel eval run | **Stateful (Write)** | ✅ |
| 59 | Evals | `/evals/{eval_id}/runs/{run_id}` | DELETE | Delete eval run | **Stateful (Delete)** | ✅ |
| 60 | Evals | `/evals/{eval_id}/runs/{run_id}/output_items` | GET | List eval run output items | **Stateful (Read)** | ✅ |
| 61 | Evals | `/evals/{eval_id}/runs/{run_id}/output_items/{id}` | GET | Retrieve eval run output item | **Stateful (Read)** | ✅ |
| | **AUDIO** | | | | | |
| 62 | Audio | `/deployments/{id}/audio/transcriptions` | POST | Transcribe audio | **Stateless** | ❌ |
| 63 | Audio | `/deployments/{id}/audio/translations` | POST | Translate audio | **Stateless** | ❌ |
| 64 | Audio | `/deployments/{id}/audio/speech` | POST | Text-to-speech | **Stateless** | ❌ |
| | **IMAGES** | | | | | |
| 65 | Images | `/deployments/{id}/images/generations` | POST | Generate images | **Stateless** | ❌ |
| 66 | Images | `/deployments/{id}/images/edits` | POST | Edit images | **Stateless** | ❌ |
| | **ASSISTANTS (DEPRECATED)** | | | | | |
| 67 | Assistants | `/assistants` | GET | List assistants | **Stateful (Read)** | ❌ |
| 68 | Assistants | `/assistants` | POST | Create assistant | **Stateful (Write)** | ❌ |
| 69 | Assistants | `/assistants/{assistant_id}` | GET | Retrieve assistant | **Stateful (Read)** | ❌ |
| 70 | Assistants | `/assistants/{assistant_id}` | POST | Modify assistant | **Stateful (Write)** | ❌ |
| 71 | Assistants | `/assistants/{assistant_id}` | DELETE | Delete assistant | **Stateful (Delete)** | ❌ |
| | **THREADS / MESSAGES / RUNS (DEPRECATED)** | | | | | |
| 72 | Threads | `/threads` | POST | Create thread | **Stateful (Write)** | ❌ |
| 73 | Threads | `/threads/{thread_id}` | GET | Retrieve thread | **Stateful (Read)** | ❌ |
| 74 | Threads | `/threads/{thread_id}` | POST | Modify thread | **Stateful (Write)** | ❌ |
| 75 | Threads | `/threads/{thread_id}` | DELETE | Delete thread | **Stateful (Delete)** | ❌ |
| 76 | Messages | `/threads/{thread_id}/messages` | GET | List messages | **Stateful (Read)** | ❌ |
| 77 | Messages | `/threads/{thread_id}/messages` | POST | Create message | **Stateful (Write)** | ❌ |
| 78 | Messages | `/threads/{thread_id}/messages/{msg_id}` | GET | Retrieve message | **Stateful (Read)** | ❌ |
| 79 | Runs | `/threads/{thread_id}/runs` | GET | List runs | **Stateful (Read)** | ❌ |
| 80 | Runs | `/threads/{thread_id}/runs` | POST | Create run | **Stateful (Write)** | ❌ |
| 81 | Runs | `/threads/{thread_id}/runs/{run_id}` | GET | Retrieve run | **Stateful (Read)** | ❌ |
| 82 | Runs | `/threads/{thread_id}/runs/{run_id}` | POST | Modify run | **Stateful (Write)** | ❌ |
| 83 | Runs | `/threads/{thread_id}/runs/{run_id}/submit_tool_outputs` | POST | Submit tool outputs | **Stateful (Write)** | ❌ |
| 84 | Runs | `/threads/{thread_id}/runs/{run_id}/cancel` | POST | Cancel run | **Stateful (Write)** | ❌ |
| 85 | Run Steps | `/threads/{thread_id}/runs/{run_id}/steps` | GET | List run steps | **Stateful (Read)** | ❌ |
| 86 | Run Steps | `/threads/{thread_id}/runs/{run_id}/steps/{step_id}` | GET | Retrieve run step | **Stateful (Read)** | ❌ |
| 87 | Threads | `/threads/runs` | POST | Create thread and run | **Stateful (Write)** | ❌ |
| | **REALTIME SESSIONS** | | | | | |
| 88 | Realtime | `/realtime/sessions` | POST | Create realtime session | **Stateful (Write)** | ❌ |
| 89 | Realtime | `/realtime/transcription_sessions` | POST | Create transcription session | **Stateful (Write)** | ❌ |
| | **VECTOR STORE SEARCH** | | | | | |
| 90 | Vector Stores | `/vector_stores/{vs_id}/search` | POST | Search vector store | **Stateful (Read)** | ❌ |

**Notes:**
1. ¹ `POST /responses` defaults to `store: true`, making it **stateful**. Set `store: false` to make it **stateless**.
2. ² Model lists are technically per-instance configuration, but the data is determined by deployments/region and is not user-mutable. Safe for cross-instance reads if both instances have the same model deployments.

---

## Detailed API Groups

### 1. Chat Completions

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/chat/completions` | **POST** | `createChatCompletion` | **Stateless** | ✅ Yes |

**Description**: Creates a model response for the given chat conversation. Sends messages and receives a completion. Supports streaming via `stream: true`.

**Cross-Instance Behavior**: Fully portable. You can send the same request to any Foundry instance (with the same model deployed) and get equivalent results. No server-side state is created.

**Azure-Specific Features**:
- `data_sources` parameter for Azure Search / Cosmos DB / Elasticsearch / Pinecone integration (On Your Data)
- Content filtering results in the response
- Supports `store: true` parameter (preview) which, when enabled, saves the conversation server-side

---

### 2. Completions (Legacy)

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/deployments/{deployment-id}/completions` | **POST** | `createCompletion` | **Stateless** | ✅ Yes |

**Description**: Legacy text completion endpoint. Creates a completion for the provided prompt. Uses the older `deployments/{id}` URL pattern.

**Cross-Instance Behavior**: Fully portable.

> ⚠️ **Not exposed in the APIM gateway spec**. Available directly on Azure OpenAI resource endpoints.

---

### 3. Embeddings

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/embeddings` | **POST** | `createEmbedding` | **Stateless** | ✅ Yes |

**Description**: Creates embedding vectors for input text. Useful for semantic search, similarity, and RAG patterns.

**Cross-Instance Behavior**: Fully portable. Same input produces same vectors (for the same model).

---

### 4. Responses API

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/responses` | **POST** | `createResponse` | **Conditional** | ⚠️ Depends on `store` |
| `/responses/{response_id}` | **GET** | `getResponse` | **Stateful (Read)** | ❌ No |
| `/responses/{response_id}` | **DELETE** | `deleteResponse` | **Stateful (Delete)** | ❌ No |
| `/responses/{response_id}/input_items` | **GET** | `listInputItems` | **Stateful (Read)** | ❌ No |

**Description**: The Responses API is OpenAI's newer replacement for Chat Completions, with built-in tool use (`file_search`, `code_interpreter`, `computer_use`), multi-turn via `previous_response_id`, and structured outputs.

**Critical Statefulness Detail**:
- `POST /responses` **defaults to `store: true`**. When stored, the `response_id` is bound to that specific Foundry instance.
- Setting `store: false` makes the POST stateless — no response is saved, and the `response_id` cannot be retrieved later.
- `previous_response_id` creates an **implicit state chain**: the model loads the prior conversation from storage, requiring session affinity to the same instance.

**Cross-Instance Behavior**:
- With `store: false` and no `previous_response_id`: ✅ Fully portable
- With `store: true` or `previous_response_id`: ❌ Instance-bound. Using a `response_id` from Instance A on Instance B returns `404 Not Found`.

---

### 5. Models

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/models` | **GET** | `listModels` | **Stateless** | ✅ Yes ² |
| `/models/{model}` | **GET** | `retrieveModel` | **Stateless** | ✅ Yes ² |

**Description**: Lists and retrieves metadata about available models.

**Cross-Instance Behavior**: Returns deployment/capability information for the specific instance. Safe to call on any instance but results reflect that instance's model deployments.

---

### 6. Files

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/files` | **POST** | `createFile` | **Stateful (Write)** | ❌ No |
| `/files` | **GET** | `listFiles` | **Stateful (Read)** | ❌ No |
| `/files/{file_id}` | **GET** | `retrieveFile` | **Stateful (Read)** | ❌ No |
| `/files/{file_id}` | **DELETE** | `deleteFile` | **Stateful (Delete)** | ❌ No |
| `/files/{file_id}/content` | **GET** | `downloadFile` | **Stateful (Read)** | ❌ No |

**Description**: Upload, list, retrieve, and download files used across other APIs (fine-tuning datasets, vector store documents, eval data, etc.).

**Cross-Instance Behavior**: File IDs are scoped to the Foundry instance that created them. A `file_id` from Instance A will return `404` on Instance B. You must re-upload files on each instance where they're needed.

---

### 7. Containers

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/containers` | **GET** | `ListContainers` | **Stateful (Read)** | ❌ No |
| `/containers` | **POST** | `CreateContainer` | **Stateful (Write)** | ❌ No |
| `/containers/{container_id}` | **GET** | `RetrieveContainer` | **Stateful (Read)** | ❌ No |
| `/containers/{container_id}` | **DELETE** | `DeleteContainer` | **Stateful (Delete)** | ❌ No |
| `/containers/{container_id}/files` | **POST** | `CreateContainerFile` | **Stateful (Write)** | ❌ No |
| `/containers/{container_id}/files` | **GET** | `ListContainerFiles` | **Stateful (Read)** | ❌ No |
| `/containers/{container_id}/files/{file_id}` | **GET** | `RetrieveContainerFile` | **Stateful (Read)** | ❌ No |
| `/containers/{container_id}/files/{file_id}` | **DELETE** | `DeleteContainerFile` | **Stateful (Delete)** | ❌ No |
| `/containers/{container_id}/files/{file_id}/content` | **GET** | `RetrieveContainerFileContent` | **Stateful (Read)** | ❌ No |

**Description**: Containers group files together with optional expiration policies. They reference file IDs and are fully instance-bound.

**Cross-Instance Behavior**: All container IDs and file IDs are instance-scoped. No portability.

---

### 8. Vector Stores

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/vector_stores` | **GET** | `listVectorStores` | **Stateful (Read)** | ❌ No |
| `/vector_stores` | **POST** | `createVectorStore` | **Stateful (Write)** | ❌ No |
| `/vector_stores/{vs_id}` | **GET** | `getVectorStore` | **Stateful (Read)** | ❌ No |
| `/vector_stores/{vs_id}` | **POST** | `modifyVectorStore` | **Stateful (Write)** | ❌ No |
| `/vector_stores/{vs_id}` | **DELETE** | `deleteVectorStore` | **Stateful (Delete)** | ❌ No |
| `/vector_stores/{vs_id}/files` | **GET** | `listVectorStoreFiles` | **Stateful (Read)** | ❌ No |
| `/vector_stores/{vs_id}/files` | **POST** | `createVectorStoreFile` | **Stateful (Write)** | ❌ No |
| `/vector_stores/{vs_id}/files/{file_id}` | **GET** | `getVectorStoreFile` | **Stateful (Read)** | ❌ No |
| `/vector_stores/{vs_id}/files/{file_id}` | **POST** | `updateVectorStoreFileAttributes` | **Stateful (Write)** | ❌ No |
| `/vector_stores/{vs_id}/files/{file_id}` | **DELETE** | `deleteVectorStoreFile` | **Stateful (Delete)** | ❌ No |
| `/vector_stores/{vs_id}/file_batches` | **POST** | `createVectorStoreFileBatch` | **Stateful (Write)** | ❌ No |
| `/vector_stores/{vs_id}/file_batches/{batch_id}` | **GET** | `getVectorStoreFileBatch` | **Stateful (Read)** | ❌ No |
| `/vector_stores/{vs_id}/file_batches/{batch_id}/cancel` | **POST** | `cancelVectorStoreFileBatch` | **Stateful (Write)** | ❌ No |
| `/vector_stores/{vs_id}/file_batches/{batch_id}/files` | **GET** | `listFilesInVectorStoreBatch` | **Stateful (Read)** | ❌ No |
| `/vector_stores/{vs_id}/search` | **POST** | `searchVectorStore` | **Stateful (Read)** | ❌ No |

**Description**: Managed vector storage for file search. Upload files, chunk and embed them automatically, then search semantically. Used by the `file_search` tool in Responses/Assistants APIs.

**Cross-Instance Behavior**: Vector store IDs and all child resources are instance-bound. The search endpoint reads from instance-local indexed data. You must recreate vector stores on each instance.

> ⚠️ `POST /vector_stores/{vs_id}/search` is available in the preview API but **not in the APIM gateway spec**.

---

### 9. Fine-Tuning Jobs

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/fine_tuning/jobs` | **POST** | `createFineTuningJob` | **Stateful (Write)** | ❌ No |
| `/fine_tuning/jobs` | **GET** | `listPaginatedFineTuningJobs` | **Stateful (Read)** | ❌ No |
| `/fine_tuning/jobs/{job_id}` | **GET** | `retrieveFineTuningJob` | **Stateful (Read)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/cancel` | **POST** | `cancelFineTuningJob` | **Stateful (Write)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/checkpoints` | **GET** | `listFineTuningJobCheckpoints` | **Stateful (Read)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/checkpoints/{cp_id}/copy` | **POST** | `FineTuning_CopyCheckpoint` | **Stateful (Write)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/checkpoints/{cp_id}/copy` | **GET** | `FineTuning_GetCheckpoint` | **Stateful (Read)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/events` | **GET** | `listFineTuningEvents` | **Stateful (Read)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/pause` | **POST** | `pauseFineTuningJob` | **Stateful (Write)** | ❌ No |
| `/fine_tuning/jobs/{job_id}/resume` | **POST** | `resumeFineTuningJob` | **Stateful (Write)** | ❌ No |
| `/fine_tuning/alpha/graders/run` | **POST** | `runGrader` | **Stateless** | ✅ Yes |
| `/fine_tuning/alpha/graders/validate` | **POST** | `validateGrader` | **Stateless** | ✅ Yes |

**Description**: Create, manage, and monitor fine-tuning jobs. Training data files must be uploaded first via the Files API. The grader run/validate endpoints are utility functions that don't create server-side state.

**Cross-Instance Behavior**: Job IDs, checkpoint IDs, and referenced file IDs are all instance-bound. The `copy` endpoint can replicate a checkpoint to a different account/region.

---

### 10. Evals

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/evals` | **GET** | `listEvals` | **Stateful (Read)** | ❌ No |
| `/evals` | **POST** | `createEval` | **Stateful (Write)** | ❌ No |
| `/evals/{eval_id}` | **GET** | `getEval` | **Stateful (Read)** | ❌ No |
| `/evals/{eval_id}` | **POST** | `updateEval` | **Stateful (Write)** | ❌ No |
| `/evals/{eval_id}` | **DELETE** | `deleteEval` | **Stateful (Delete)** | ❌ No |
| `/evals/{eval_id}/runs` | **GET** | `getEvalRuns` | **Stateful (Read)** | ❌ No |
| `/evals/{eval_id}/runs` | **POST** | `createEvalRun` | **Stateful (Write)** | ❌ No |
| `/evals/{eval_id}/runs/{run_id}` | **GET** | `getEvalRun` | **Stateful (Read)** | ❌ No |
| `/evals/{eval_id}/runs/{run_id}` | **POST** | `cancelEvalRun` | **Stateful (Write)** | ❌ No |
| `/evals/{eval_id}/runs/{run_id}` | **DELETE** | `deleteEvalRun` | **Stateful (Delete)** | ❌ No |
| `/evals/{eval_id}/runs/{run_id}/output_items` | **GET** | `getEvalRunOutputItems` | **Stateful (Read)** | ❌ No |
| `/evals/{eval_id}/runs/{run_id}/output_items/{id}` | **GET** | `getEvalRunOutputItem` | **Stateful (Read)** | ❌ No |

**Description**: Create model evaluations with testing criteria and datasources. Run them to grade model performance. Requires the `aoai-evals: preview` header.

**Cross-Instance Behavior**: All eval IDs, run IDs, and output item IDs are instance-bound.

> ⚠️ **Preview feature** — requires the `aoai-evals: preview` header.

---

### 11. Audio — Transcription, Translation, Speech

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/deployments/{id}/audio/transcriptions` | **POST** | `createTranscription` | **Stateless** | ✅ Yes |
| `/deployments/{id}/audio/translations` | **POST** | `createTranslation` | **Stateless** | ✅ Yes |
| `/deployments/{id}/audio/speech` | **POST** | `createSpeech` | **Stateless** | ✅ Yes |

**Description**:
- **Transcriptions**: Convert audio to text in the original language (Whisper model)
- **Translations**: Convert audio to English text
- **Speech**: Text-to-speech synthesis (alloy, echo, fable, onyx, nova, shimmer voices)

**Cross-Instance Behavior**: Fully portable. No server-side state. Audio data is processed and returned in real-time.

> ⚠️ **Not exposed in the APIM gateway spec**. These use the `deployments/{id}` URL pattern available directly on Azure OpenAI resources. Speech (TTS) is preview-only in GA reference.

---

### 12. Image Generation

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/deployments/{id}/images/generations` | **POST** | `createImageGeneration` | **Stateless** | ✅ Yes |
| `/deployments/{id}/images/edits` | **POST** | `createImageEdit` | **Stateless** | ✅ Yes |

**Description**: Generate images from text prompts (DALL-E, gpt-image-1) or edit existing images with masks and prompts.

**Cross-Instance Behavior**: Fully portable. No server-side state.

> ⚠️ **Not exposed in the APIM gateway spec**. Available directly on Azure OpenAI resources.

---

### 13. Assistants (Deprecated)

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/assistants` | **GET** | `listAssistants` | **Stateful (Read)** | ❌ No |
| `/assistants` | **POST** | `createAssistant` | **Stateful (Write)** | ❌ No |
| `/assistants/{assistant_id}` | **GET** | `getAssistant` | **Stateful (Read)** | ❌ No |
| `/assistants/{assistant_id}` | **POST** | `modifyAssistant` | **Stateful (Write)** | ❌ No |
| `/assistants/{assistant_id}` | **DELETE** | `deleteAssistant` | **Stateful (Delete)** | ❌ No |

> ⚠️ **DEPRECATED** — The Assistants API will be retired on **August 26, 2026**. Migrate to [Microsoft Foundry Agents](https://learn.microsoft.com/en-us/azure/foundry/agents/overview).

> ⚠️ **Not exposed in the APIM gateway spec**.

---

### 14. Threads, Messages & Runs (Deprecated)

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/threads` | **POST** | `createThread` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}` | **GET** | `getThread` | **Stateful (Read)** | ❌ No |
| `/threads/{thread_id}` | **POST** | `modifyThread` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}` | **DELETE** | `deleteThread` | **Stateful (Delete)** | ❌ No |
| `/threads/{thread_id}/messages` | **GET** | `listMessages` | **Stateful (Read)** | ❌ No |
| `/threads/{thread_id}/messages` | **POST** | `createMessage` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}/messages/{msg_id}` | **GET** | `getMessage` | **Stateful (Read)** | ❌ No |
| `/threads/runs` | **POST** | `createThreadAndRun` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}/runs` | **GET** | `listRuns` | **Stateful (Read)** | ❌ No |
| `/threads/{thread_id}/runs` | **POST** | `createRun` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}/runs/{run_id}` | **GET** | `getRun` | **Stateful (Read)** | ❌ No |
| `/threads/{thread_id}/runs/{run_id}` | **POST** | `modifyRun` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}/runs/{run_id}/submit_tool_outputs` | **POST** | `submitToolOutputs` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}/runs/{run_id}/cancel` | **POST** | `cancelRun` | **Stateful (Write)** | ❌ No |
| `/threads/{thread_id}/runs/{run_id}/steps` | **GET** | `listRunSteps` | **Stateful (Read)** | ❌ No |
| `/threads/{thread_id}/runs/{run_id}/steps/{step_id}` | **GET** | `getRunStep` | **Stateful (Read)** | ❌ No |

> ⚠️ **DEPRECATED** — Part of the Assistants API. Will be retired on **August 26, 2026**.

> ⚠️ **Not exposed in the APIM gateway spec**.

---

### 15. Realtime Sessions

| Endpoint | Method | Operation ID | Statefulness | Cross-Instance OK? |
|---|---|---|---|---|
| `/realtime/sessions` | **POST** | `createRealtimeSession` | **Stateful (Write)** | ❌ No |
| `/realtime/transcription_sessions` | **POST** | `createTranscriptionRealtimeSession` | **Stateful (Write)** | ❌ No |

**Description**: Initiates a WebSocket-based realtime session for interactive voice/text conversations or live transcription.

**Cross-Instance Behavior**: Session tokens/IDs are instance-bound. The WebSocket connection must stay with the same instance.

> ⚠️ **Not exposed in the APIM gateway spec**. Preview only.

---

## APIs Missing from the APIM Gateway Spec

The following APIs are documented in the Azure Foundry public documentation but are **not present** in the APIM gateway OpenAPI spec (`ais-fnd1-6ohufxbigpdyo.openapi.yaml`):

| API Group | Endpoints Missing | Status | Notes |
|---|---|---|---|
| **Completions (Legacy)** | `POST /deployments/{id}/completions` | GA | Uses `deployments/{id}` URL pattern |
| **Audio — Transcriptions** | `POST /deployments/{id}/audio/transcriptions` | GA | Whisper model |
| **Audio — Translations** | `POST /deployments/{id}/audio/translations` | GA | Whisper model |
| **Audio — Speech (TTS)** | `POST /deployments/{id}/audio/speech` | Preview | TTS voices |
| **Image Generations** | `POST /deployments/{id}/images/generations` | GA | DALL-E / gpt-image-1 |
| **Image Edits** | `POST /deployments/{id}/images/edits` | Preview | gpt-image-1 |
| **Assistants** | All CRUD operations on `/assistants` | **Deprecated** | Retiring Aug 2026 |
| **Threads** | All CRUD operations on `/threads` | **Deprecated** | Part of Assistants |
| **Messages** | All operations on `/threads/{id}/messages` | **Deprecated** | Part of Assistants |
| **Runs / Run Steps** | All operations on `/threads/{id}/runs` | **Deprecated** | Part of Assistants |
| **Realtime Sessions** | `POST /realtime/sessions` | Preview | WebSocket-based |
| **Realtime Transcription** | `POST /realtime/transcription_sessions` | Preview | Live transcription |
| **Vector Store Search** | `POST /vector_stores/{id}/search` | Preview | Semantic search |
| **Vector Store File Content** | `GET /vector_stores/{id}/files/{file_id}/content` | Preview | Retrieve raw file |

**Why are they missing?** The APIM gateway spec uses the newer `/v1` path structure (e.g., `/chat/completions`), while many Azure-specific APIs still use the older `/deployments/{deployment-id}/...` pattern. The gateway may also intentionally exclude deprecated (Assistants) and preview-only features.

---

## Cross-Instance Portability Guide

### Safe to Load-Balance (Stateless Operations)

These operations can be freely distributed across multiple Foundry instances behind a load balancer:

```
POST /chat/completions          (standard usage without store:true)
POST /embeddings
POST /responses                 (only with store: false)
GET  /models
GET  /models/{model}
POST /fine_tuning/alpha/graders/run
POST /fine_tuning/alpha/graders/validate
POST /deployments/{id}/audio/transcriptions
POST /deployments/{id}/audio/translations
POST /deployments/{id}/audio/speech
POST /deployments/{id}/images/generations
POST /deployments/{id}/images/edits
POST /deployments/{id}/completions
```

### Require Session Affinity (Stateful Operations)

These operations create or reference instance-bound resources. If you're using a load balancer or APIM gateway:

| Pattern | Affinity Key | Strategy |
|---|---|---|
| Multi-turn Responses API | `previous_response_id` | Route all requests in a conversation chain to the same backend |
| File upload → fine-tuning | `file_id` | Upload training files to the same instance that will run the job |
| Vector store workflows | `vector_store_id` | Create, populate, and search on the same instance |
| Eval workflows | `eval_id` | Create eval, run, and retrieve results on the same instance |
| Container workflows | `container_id` | All container operations on the same instance |

### What Happens If You Use a Resource ID on the Wrong Instance?

| Scenario | Result |
|---|---|
| `GET /responses/{id}` on wrong instance | `404 Not Found` |
| `GET /files/{id}` on wrong instance | `404 Not Found` |
| `POST /responses` with `previous_response_id` from another instance | `404 Not Found` or conversation context lost |
| `POST /fine_tuning/jobs` referencing `file_id` from another instance | `400 Bad Request` — file not found |
| `GET /vector_stores/{id}` on wrong instance | `404 Not Found` |
| `GET /evals/{id}` on wrong instance | `404 Not Found` |

---

## Statefulness Summary by API Group

| API Group | Total Ops | Stateless | Stateful | Conditional |
|---|---|---|---|---|
| Chat Completions | 1 | 1 | 0 | 0 |
| Completions (Legacy) | 1 | 1 | 0 | 0 |
| Embeddings | 1 | 1 | 0 | 0 |
| Responses | 4 | 0 | 3 | 1 |
| Models | 2 | 2 | 0 | 0 |
| Files | 5 | 0 | 5 | 0 |
| Containers | 9 | 0 | 9 | 0 |
| Vector Stores | 15 | 0 | 15 | 0 |
| Fine-Tuning | 12 | 2 | 10 | 0 |
| Evals | 12 | 0 | 12 | 0 |
| Audio | 3 | 3 | 0 | 0 |
| Images | 2 | 2 | 0 | 0 |
| Assistants (Deprecated) | 5 | 0 | 5 | 0 |
| Threads/Messages/Runs (Deprecated) | 16 | 0 | 16 | 0 |
| Realtime Sessions | 2 | 0 | 2 | 0 |
| **TOTAL** | **90** | **12** | **77** | **1** |

---

## References

- [Azure OpenAI in Microsoft Foundry Models REST API (GA)](https://learn.microsoft.com/en-us/azure/foundry/openai/reference)
- [Azure OpenAI in Microsoft Foundry Models REST API (Preview)](https://learn.microsoft.com/en-us/azure/foundry/openai/reference-preview)
- [Azure AI Foundry documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [API Lifecycle Guide](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle)
- [Migrate from Assistants to Foundry Agents](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/migrate)
