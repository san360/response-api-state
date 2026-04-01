# Azure AI Foundry API — Comprehensive Operations & Statefulness Report

> **Generated:** 2026-03-31  
> **Sources:** Azure OpenAI REST API Reference (GA 2024-10-21, Preview 2025-04-01-preview), OpenAPI spec from workspace (`ais-fnd1-6ohufxbigpdyo.openapi.yaml`), OpenAI API Reference

---

## Executive Summary

The Azure AI Foundry API surface is divided into **stateless inference operations** (that can be freely load-balanced across any Foundry instance) and **stateful resource management operations** (that create server-side resources bound to a specific Foundry instance/project). When a stateful resource (file ID, vector store ID, fine-tuning job ID, etc.) is created on Instance A, it **cannot be accessed from Instance B** — the request will return `404 Not Found`.

---

## 1. Complete API Operations by Group

### Legend
| Symbol | Meaning |
|--------|---------|
| 🟢 | **STATELESS** — No server-side state created/modified; can route to any instance |
| 🔴 | **STATEFUL** — Creates/reads/modifies/deletes server-side resources tied to a specific instance |
| ✅ | Available in Azure Foundry (confirmed in OpenAPI spec or docs) |
| ⚠️ | Available in Azure Foundry (preview only, not in OpenAPI gateway spec) |
| ❌ | Not available in Azure Foundry (OpenAI-only or not yet supported) |

---

### 1.1 Chat Completions ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/chat/completions` | createChatCompletion | 🟢 STATELESS |

**Notes:** Pure inference. Sends messages, receives completion. No server-side resources created. Can be routed to any Foundry instance. Includes Azure-specific extensions (Azure Search, Cosmos DB, Elasticsearch, Pinecone, MongoDB data sources).

---

### 1.2 Completions (Legacy) ⚠️
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/completions` | createCompletion | 🟢 STATELESS |

**Notes:** Legacy text completion API. Available in Azure preview (`2025-04-01-preview`) but **not present in the workspace OpenAPI gateway spec**. Pure inference, stateless.

---

### 1.3 Embeddings ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/embeddings` | createEmbedding | 🟢 STATELESS |

**Notes:** Pure inference. Sends text, receives vector. Stateless.

---

### 1.4 Responses API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/responses` | createResponse | 🟢/🔴 **HYBRID** |
| GET | `/responses/{response_id}` | getResponse | 🔴 STATEFUL |
| DELETE | `/responses/{response_id}` | deleteResponse | 🔴 STATEFUL |
| GET | `/responses/{response_id}/input_items` | listInputItems | 🔴 STATEFUL |

**Notes:** The `POST /responses` call itself performs inference (stateless in nature), but when `store: true` (the default), it **persists the response server-side**, making the response_id a stateful resource. The `previous_response_id` parameter for multi-turn conversations references stored state. If `store: false`, the inference is fully stateless but you cannot retrieve the response later.

**Critical for load balancing:**
- With `store: false`: 🟢 STATELESS — safe to route anywhere
- With `store: true` (default): 🔴 STATEFUL — response_id is tied to the instance that created it
- Multi-turn via `previous_response_id`: 🔴 STATEFUL — must route to the same instance that has the stored previous response

---

### 1.5 Containers API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| GET | `/containers` | ListContainers | 🔴 STATEFUL |
| POST | `/containers` | CreateContainer | 🔴 STATEFUL |
| GET | `/containers/{container_id}` | RetrieveContainer | 🔴 STATEFUL |
| DELETE | `/containers/{container_id}` | DeleteContainer | 🔴 STATEFUL |
| POST | `/containers/{container_id}/files` | CreateContainerFile | 🔴 STATEFUL |
| GET | `/containers/{container_id}/files` | ListContainerFiles | 🔴 STATEFUL |
| GET | `/containers/{container_id}/files/{file_id}` | RetrieveContainerFile | 🔴 STATEFUL |
| DELETE | `/containers/{container_id}/files/{file_id}` | DeleteContainerFile | 🔴 STATEFUL |
| GET | `/containers/{container_id}/files/{file_id}/content` | RetrieveContainerFileContent | 🔴 STATEFUL |

**Notes:** Containers are a new API for managing file storage associated with a Foundry project. Entirely stateful — container IDs and their files are bound to the specific instance.

---

### 1.6 Evals API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| GET | `/evals` | listEvals | 🔴 STATEFUL |
| POST | `/evals` | createEval | 🔴 STATEFUL |
| GET | `/evals/{eval_id}` | getEval | 🔴 STATEFUL |
| POST | `/evals/{eval_id}` | updateEval | 🔴 STATEFUL |
| DELETE | `/evals/{eval_id}` | deleteEval | 🔴 STATEFUL |
| GET | `/evals/{eval_id}/runs` | getEvalRuns | 🔴 STATEFUL |
| POST | `/evals/{eval_id}/runs` | createEvalRun | 🔴 STATEFUL |
| GET | `/evals/{eval_id}/runs/{run_id}` | getEvalRun | 🔴 STATEFUL |
| POST | `/evals/{eval_id}/runs/{run_id}` | cancelEvalRun | 🔴 STATEFUL |
| DELETE | `/evals/{eval_id}/runs/{run_id}` | deleteEvalRun | 🔴 STATEFUL |
| GET | `/evals/{eval_id}/runs/{run_id}/output_items` | getEvalRunOutputItems | 🔴 STATEFUL |
| GET | `/evals/{eval_id}/runs/{run_id}/output_items/{output_item_id}` | getEvalRunOutputItem | 🔴 STATEFUL |

**Notes:** Evaluation framework for testing model performance. All operations are stateful — eval definitions, runs, and output items are resources stored on the specific instance.

---

### 1.7 Files API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/files` | createFile | 🔴 STATEFUL |
| GET | `/files` | listFiles | 🔴 STATEFUL |
| GET | `/files/{file_id}` | retrieveFile | 🔴 STATEFUL |
| DELETE | `/files/{file_id}` | deleteFile | 🔴 STATEFUL |
| GET | `/files/{file_id}/content` | downloadFile | 🔴 STATEFUL |

**Notes:** File storage for fine-tuning, assistants, etc. Files are bound to the specific Foundry instance. A `file_id` created on Instance A will not exist on Instance B.

---

### 1.8 Fine-Tuning Jobs API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/fine_tuning/jobs` | createFineTuningJob | 🔴 STATEFUL |
| GET | `/fine_tuning/jobs` | listPaginatedFineTuningJobs | 🔴 STATEFUL |
| GET | `/fine_tuning/jobs/{job_id}` | retrieveFineTuningJob | 🔴 STATEFUL |
| POST | `/fine_tuning/jobs/{job_id}/cancel` | cancelFineTuningJob | 🔴 STATEFUL |
| GET | `/fine_tuning/jobs/{job_id}/checkpoints` | listFineTuningJobCheckpoints | 🔴 STATEFUL |
| POST | `/fine_tuning/jobs/{job_id}/checkpoints/{cp_id}/copy` | FineTuning_CopyCheckpoint | 🔴 STATEFUL |
| GET | `/fine_tuning/jobs/{job_id}/checkpoints/{cp_id}/copy` | FineTuning_GetCheckpoint | 🔴 STATEFUL |
| GET | `/fine_tuning/jobs/{job_id}/events` | listFineTuningEvents | 🔴 STATEFUL |
| POST | `/fine_tuning/jobs/{job_id}/pause` | pauseFineTuningJob | 🔴 STATEFUL |
| POST | `/fine_tuning/jobs/{job_id}/resume` | resumeFineTuningJob | 🔴 STATEFUL |
| POST | `/fine_tuning/alpha/graders/run` | runGrader | 🟢 STATELESS |
| POST | `/fine_tuning/alpha/graders/validate` | validateGrader | 🟢 STATELESS |

**Notes:** Fine-tuning jobs, checkpoints, and events are all bound to the specific instance. The grader run/validate endpoints are stateless utility operations. The `CopyCheckpoint` operation enables cross-instance checkpoint copying (Azure-specific).

---

### 1.9 Models API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| GET | `/models` | listModels | 🟢 STATELESS |
| GET | `/models/{model}` | retrieveModel | 🟢 STATELESS |

**Notes:** Read-only model catalog. Lists available models/deployments. Stateless in terms of user-created resources (though different instances may expose different model deployments).

---

### 1.10 Vector Stores API ✅
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| GET | `/vector_stores` | listVectorStores | 🔴 STATEFUL |
| POST | `/vector_stores` | createVectorStore | 🔴 STATEFUL |
| GET | `/vector_stores/{vs_id}` | getVectorStore | 🔴 STATEFUL |
| POST | `/vector_stores/{vs_id}` | modifyVectorStore | 🔴 STATEFUL |
| DELETE | `/vector_stores/{vs_id}` | deleteVectorStore | 🔴 STATEFUL |
| GET | `/vector_stores/{vs_id}/files` | listVectorStoreFiles | 🔴 STATEFUL |
| POST | `/vector_stores/{vs_id}/files` | createVectorStoreFile | 🔴 STATEFUL |
| GET | `/vector_stores/{vs_id}/files/{file_id}` | getVectorStoreFile | 🔴 STATEFUL |
| POST | `/vector_stores/{vs_id}/files/{file_id}` | updateVectorStoreFileAttributes | 🔴 STATEFUL |
| DELETE | `/vector_stores/{vs_id}/files/{file_id}` | deleteVectorStoreFile | 🔴 STATEFUL |
| POST | `/vector_stores/{vs_id}/file_batches` | createVectorStoreFileBatch | 🔴 STATEFUL |
| GET | `/vector_stores/{vs_id}/file_batches/{batch_id}` | getVectorStoreFileBatch | 🔴 STATEFUL |
| POST | `/vector_stores/{vs_id}/file_batches/{batch_id}/cancel` | cancelVectorStoreFileBatch | 🔴 STATEFUL |
| GET | `/vector_stores/{vs_id}/file_batches/{batch_id}/files` | listFilesInVectorStoreBatch | 🔴 STATEFUL |

**Notes:** Vector stores and their files are bound to a specific instance. All operations are stateful. The `file_search` tool in Responses API depends on vector store IDs existing on the same instance.

---

### 1.11 Audio / Speech APIs ⚠️
| Method | Endpoint | Operation | State | Availability |
|--------|----------|-----------|-------|-------------|
| POST | `/audio/transcriptions` | createTranscription | 🟢 STATELESS | ⚠️ Azure Preview |
| POST | `/audio/translations` | createTranslation | 🟢 STATELESS | ⚠️ Azure Preview |
| POST | `/audio/speech` | createSpeech | 🟢 STATELESS | ⚠️ Azure Preview |

**Notes:** All audio operations are pure inference (stateless). They take input audio/text and return output. **Not present in the workspace OpenAPI gateway spec** — available directly on Azure OpenAI endpoints, not currently exposed through the APIM Foundry gateway in this spec.

---

### 1.12 Image Generation ⚠️
| Method | Endpoint | Operation | State | Availability |
|--------|----------|-----------|-------|-------------|
| POST | `/images/generations` | createImage | 🟢 STATELESS | ⚠️ Azure Preview |
| POST | `/images/edits` | createImageEdit | 🟢 STATELESS | ⚠️ Azure Preview |

**Notes:** Pure inference. Stateless. **Not present in the workspace OpenAPI gateway spec** — available directly on Azure OpenAI endpoints with deployment-specific routing (`/deployments/{deployment-id}/images/generations`).

---

### 1.13 Assistants API (DEPRECATED) ⚠️
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| GET | `/assistants` | listAssistants | 🔴 STATEFUL |
| POST | `/assistants` | createAssistant | 🔴 STATEFUL |
| GET | `/assistants/{assistant_id}` | getAssistant | 🔴 STATEFUL |
| POST | `/assistants/{assistant_id}` | modifyAssistant | 🔴 STATEFUL |
| DELETE | `/assistants/{assistant_id}` | deleteAssistant | 🔴 STATEFUL |
| POST | `/threads` | createThread | 🔴 STATEFUL |
| GET | `/threads/{thread_id}` | getThread | 🔴 STATEFUL |
| POST | `/threads/{thread_id}` | modifyThread | 🔴 STATEFUL |
| DELETE | `/threads/{thread_id}` | deleteThread | 🔴 STATEFUL |
| GET | `/threads/{thread_id}/messages` | listMessages | 🔴 STATEFUL |
| POST | `/threads/{thread_id}/messages` | createMessage | 🔴 STATEFUL |
| GET | `/threads/{thread_id}/messages/{msg_id}` | getMessage | 🔴 STATEFUL |
| POST | `/threads/{thread_id}/messages/{msg_id}` | modifyMessage | 🔴 STATEFUL |
| POST | `/threads/runs` | createThreadAndRun | 🔴 STATEFUL |
| GET | `/threads/{thread_id}/runs` | listRuns | 🔴 STATEFUL |
| POST | `/threads/{thread_id}/runs` | createRun | 🔴 STATEFUL |
| GET | `/threads/{thread_id}/runs/{run_id}` | getRun | 🔴 STATEFUL |
| POST | `/threads/{thread_id}/runs/{run_id}` | modifyRun | 🔴 STATEFUL |
| POST | `/threads/{thread_id}/runs/{run_id}/submit_tool_outputs` | submitToolOutputsToRun | 🔴 STATEFUL |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | cancelRun | 🔴 STATEFUL |
| GET | `/threads/{thread_id}/runs/{run_id}/steps` | listRunSteps | 🔴 STATEFUL |
| GET | `/threads/{thread_id}/runs/{run_id}/steps/{step_id}` | getRunStep | 🔴 STATEFUL |

**Notes:** **DEPRECATED — retiring August 26, 2026.** Replaced by Microsoft Foundry Agents service. All operations are heavily stateful. Available in Azure OpenAI preview but **not present in the workspace APIM gateway spec**.

---

### 1.14 Batch API ❌
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/batches` | createBatch | 🔴 STATEFUL |
| GET | `/batches` | listBatches | 🔴 STATEFUL |
| GET | `/batches/{batch_id}` | retrieveBatch | 🔴 STATEFUL |
| POST | `/batches/{batch_id}/cancel` | cancelBatch | 🔴 STATEFUL |

**Notes:** Available in OpenAI and Azure OpenAI (via direct endpoint), but **not present in the workspace APIM Foundry gateway spec** and not documented in the Azure Foundry Models preview reference. Entirely stateful.

---

### 1.15 Realtime API ⚠️
| Method | Endpoint | Operation | State |
|--------|----------|-----------|-------|
| POST | `/realtime` (WebSocket upgrade) | createRealtimeSession | 🟢 STATELESS (session-scoped) |
| POST | `/realtime/transcription` (WebSocket) | createTranscriptionRealtimeSession | 🟢 STATELESS (session-scoped) |

**Notes:** WebSocket-based real-time audio/text streaming. Session state only exists for the duration of the WebSocket connection — no persisted server-side resources. Available in Azure preview but **not in the workspace gateway spec**.

---

## 2. APIs Missing from Your Listed Groups

Your listed groups were: Chat Completions, Containers, Embeddings, Evals, Files, Fine-tuning, Models, Responses, Vector Stores.

**Additional APIs available in Azure Foundry (not in your list):**

| API Group | Availability | Notes |
|-----------|-------------|-------|
| **Completions** (legacy) | ⚠️ Azure Preview | Legacy text completions, being phased out |
| **Audio Transcriptions** | ⚠️ Azure Preview | Whisper-based speech-to-text |
| **Audio Translations** | ⚠️ Azure Preview | Whisper-based speech translation to English |
| **Audio Speech (TTS)** | ⚠️ Azure Preview | Text-to-speech generation |
| **Image Generations** | ⚠️ Azure GA + Preview | DALL-E / gpt-image-1 image generation |
| **Image Edits** | ⚠️ Azure Preview | Image editing/inpainting |
| **Assistants** (deprecated) | ⚠️ Azure Preview | Full Assistants API (retiring 2026-08-26) |
| **Batch** | ❌ Not in gateway | Batch processing API |
| **Realtime** | ⚠️ Azure Preview | WebSocket-based real-time audio |

---

## 3. Statelessness Summary Table

| API Group | Classification | Safe to Load Balance? |
|-----------|---------------|----------------------|
| **Chat Completions** | 🟢 STATELESS | ✅ Yes — any instance |
| **Completions** (legacy) | 🟢 STATELESS | ✅ Yes — any instance |
| **Embeddings** | 🟢 STATELESS | ✅ Yes — any instance |
| **Audio Transcriptions** | 🟢 STATELESS | ✅ Yes — any instance |
| **Audio Translations** | 🟢 STATELESS | ✅ Yes — any instance |
| **Audio Speech (TTS)** | 🟢 STATELESS | ✅ Yes — any instance |
| **Image Generations** | 🟢 STATELESS | ✅ Yes — any instance |
| **Image Edits** | 🟢 STATELESS | ✅ Yes — any instance |
| **Models** (list/get) | 🟢 STATELESS | ✅ Yes (catalog may vary per instance) |
| **Grader Run/Validate** | 🟢 STATELESS | ✅ Yes — any instance |
| **Responses** (`store: false`) | 🟢 STATELESS | ✅ Yes — any instance |
| **Realtime** | 🟢 STATELESS | ✅ Yes — per-session |
| | | |
| **Responses** (`store: true`, default) | 🔴 STATEFUL | ❌ No — response_id bound to instance |
| **Containers** | 🔴 STATEFUL | ❌ No — container_id bound to instance |
| **Evals** | 🔴 STATEFUL | ❌ No — eval_id bound to instance |
| **Files** | 🔴 STATEFUL | ❌ No — file_id bound to instance |
| **Fine-Tuning Jobs** | 🔴 STATEFUL | ❌ No — job_id bound to instance |
| **Vector Stores** | 🔴 STATEFUL | ❌ No — vector_store_id bound to instance |
| **Assistants** (deprecated) | 🔴 STATEFUL | ❌ No — all IDs bound to instance |

---

## 4. Cross-Instance Behavior for Stateful Operations

### What happens when you use a stateful resource ID across different Foundry instances?

| Scenario | Result |
|----------|--------|
| Create file on Instance A, retrieve on Instance B | **404 Not Found** — file_id doesn't exist on Instance B |
| Create fine-tuning job on Instance A, check status on Instance B | **404 Not Found** — job doesn't exist on Instance B |
| Create vector store on Instance A, search on Instance B | **404 Not Found** — vector_store_id not found |
| Create response with `store: true` on Instance A, GET on Instance B | **404 Not Found** — response_id not found |
| Use `previous_response_id` from Instance A in POST to Instance B | **Error** — previous response not found, conversation chain broken |
| Create eval on Instance A, run it on Instance B | **404 Not Found** — eval_id bound to Instance A |
| Create container on Instance A, list files on Instance B | **404 Not Found** — container_id not found |

### Key Implications for APIM / Load Balancer Architecture:

1. **Stateless operations** can use round-robin, least-latency, or any load balancing strategy across multiple Foundry instances.

2. **Stateful operations** require **session affinity** (sticky sessions) — all requests involving a given resource ID must be routed to the same backend instance that created the resource.

3. **The Responses API is the trickiest** because:
   - The `POST /responses` call looks like inference but defaults to `store: true`
   - Multi-turn via `previous_response_id` creates an implicit dependency chain
   - If you set `store: false`, it becomes fully stateless but loses retrieval capability

4. **Fine-tuning checkpoint copy** (`FineTuning_CopyCheckpoint`) is the only operation that explicitly supports cross-instance resource transfer — it copies a checkpoint from one account/region to another.

---

## 5. Operation Count Summary

| API Group | Total Operations | Stateless | Stateful |
|-----------|-----------------|-----------|----------|
| Chat Completions | 1 | 1 | 0 |
| Completions (legacy) | 1 | 1 | 0 |
| Embeddings | 1 | 1 | 0 |
| Responses | 4 | 1* | 3 |
| Containers | 9 | 0 | 9 |
| Evals | 12 | 0 | 12 |
| Files | 5 | 0 | 5 |
| Fine-Tuning | 12 | 2 | 10 |
| Models | 2 | 2 | 0 |
| Vector Stores | 14 | 0 | 14 |
| Audio (Transcription/Translation/Speech) | 3 | 3 | 0 |
| Image Generation/Edit | 2 | 2 | 0 |
| Assistants (deprecated) | 22 | 0 | 22 |
| Batch | 4 | 0 | 4 |
| Realtime | 2 | 2 | 0 |
| **TOTAL** | **94** | **15** | **79** |

\* POST /responses is stateless only when `store: false`

---

## 6. Workspace OpenAPI Spec Coverage

The workspace file [ais-fnd1-6ohufxbigpdyo.openapi.yaml](ais-fnd1-6ohufxbigpdyo.openapi.yaml) exposes **9 API groups** through the APIM gateway at `https://apim-lab-sdc-001.azure-api.net/ai/openai/v1`:

| API Group | In Gateway Spec? | Operation Count |
|-----------|-----------------|-----------------|
| Chat Completions | ✅ | 1 |
| Containers | ✅ | 9 |
| Embeddings | ✅ | 1 |
| Evals | ✅ | 12 |
| Files | ✅ | 5 |
| Fine-Tuning | ✅ | 12 |
| Models | ✅ | 2 |
| Responses | ✅ | 4 |
| Vector Stores | ✅ | 14 |
| **Not in spec:** Audio, Images, Assistants, Batch, Realtime, Completions | ❌ | — |

**Total operations in gateway spec: 60** (of which only 5 are stateless: chat completions, embeddings, list/get models, and grader run/validate)
