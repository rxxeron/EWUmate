---
description: How to deploy Azure Functions for EWUmate backend
---

# Deploy EWUmate Azure Functions

## Prerequisites
1. Azure account with an active subscription
2. Python 3.9+ installed
3. Azure Functions Core Tools (`npm install -g azure-functions-core-tools@4`)
4. Azure CLI (`winget install Microsoft.AzureCLI`)

## Steps

### 1. Install Python Dependencies
```powershell
cd c:\Users\RH\Documents\EWUmate\azure_functions
pip install -r requirements.txt
```

### 2. Test Locally
```powershell
cd c:\Users\RH\Documents\EWUmate\azure_functions
func start
```
The function will be available at `http://localhost:7071/api/{action}`.

Test with:
```powershell
curl -X POST http://localhost:7071/api/recalculate_stats -H "Content-Type: application/json" -d '{"user_id": "YOUR_UUID"}'
```

### 3. Create Azure Function App
```powershell
az login
az group create --name ewumate-rg --location eastus
az storage account create --name ewumatestorage --location eastus --resource-group ewumate-rg --sku Standard_LRS
az functionapp create --resource-group ewumate-rg --consumption-plan-location eastus --runtime python --runtime-version 3.11 --functions-version 4 --name ewumate-api --storage-account ewumatestorage --os-type linux
```

### 4. Set Environment Variables
```powershell
az functionapp config appsettings set --name ewumate-api --resource-group ewumate-rg --settings SUPABASE_URL="https://jwygjihrbwxhehijldiz.supabase.co" SUPABASE_SERVICE_KEY="YOUR_SERVICE_KEY"
```

### 5. Deploy
```powershell
cd c:\Users\RH\Documents\EWUmate\azure_functions
func azure functionapp publish ewumate-api
```

### 6. Update Flutter App
After deployment, update the base URL in `lib/core/services/azure_functions_service.dart`:
```dart
static const String _baseUrl = 'https://ewumate-api.azurewebsites.net/api';
```

Also set the function key if you have authLevel set to "function":
```dart
static const String _functionKey = 'YOUR_FUNCTION_KEY';
```

Get the key from Azure Portal → Function App → Functions → App keys.

## API Endpoints

| Endpoint | Method | Body | Description |
|---|---|---|---|
| `/api/recalculate_stats` | POST | `{"user_id": "uuid"}` | Recalculates CGPA using course_metadata credits |
| `/api/update_progress` | POST | `{"user_id": "uuid", "semester_code": "Spring2026"}` | Updates live semester marks → predicted SGPA |
| `/api/generate_schedules` | POST | `{"user_id": "uuid", "semester": "Spring2026", "courses": ["CSE101"], "filters": {}}` | Generates schedule combinations |
