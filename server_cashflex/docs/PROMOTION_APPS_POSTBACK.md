# Promotion Apps Postback API Documentation

## Overview

The Promotion Apps Postback API allows trusted external services to notify GrabReward when a user should be rewarded for completing a promotional app flow.  
This endpoint accepts the format used by external promotional apps and automatically extracts the app identifier (cashalpha or cashraze) from the referrer parameter.

**Promotional App Play Store URL:**
```
https://play.google.com/store/apps/details?id=com.billtracker.billexpensetracker
```

## Endpoint

```
POST https://grabrewardserver.vercel.app/api/postback/promotion-apps
```

## Authentication

All requests must include a valid API key in the request body.  
Accepted API keys:
- `cashapps123` (default for external promotional apps)
- `MYSTERY_KEY` environment variable (from admin settings)

## Request Format

### Content-Type

```
application/json
```

### Request Body

```json
{
  "apiKey": "cashapps123",
  "coins": 100,
  "referrer": "ref_id=firebase-user-uid&pid=cashraze",
  "details": "Rewards"
}
```

### Parameters

| Parameter        | Type   | Required | Description                                                |
|-----------------:|--------|----------|------------------------------------------------------------|
| `apiKey`         | string | ✅ Yes   | API key for authentication (`cashapps123` or `MYSTERY_KEY`).   |
| `coins`          | number | ✅ Yes   | Number of coins to reward the user (must be > 0).        |
| `referrer`       | string | ✅ Yes   | **Required** - Referrer string containing `ref_id` and `pid` parameters. Format: `ref_id=USER_ID&pid=cashraze` or `ref_id=USER_ID&pid=cashalpha`. The backend extracts both the user ID (from `ref_id`) and app identifier (from `pid`) from this parameter. |
| `userid`         | string | ❌ No    | Optional Firebase user ID (UID). If provided, it will be used as fallback if `ref_id` is not found in referrer. However, it's recommended to always include `ref_id` in the referrer parameter. |
| `details`        | string | ❌ No    | Optional description of the reward (defaults to "Rewards"). |

## Response Format

### Success Response (200 OK)

```json
{
  "status": "success",
  "message": "Coins added successfully",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "userId": "user-firebase-uid",
  "coins": 100,
  "appId": "cashraze"
}
```

### Error Responses

#### 400 Bad Request – Missing Required Fields

```json
{
  "error": "Missing required fields",
  "required": ["apiKey", "userId", "coins"]
}
```

#### 400 Bad Request – Invalid Coins or User ID

```json
{
  "error": "Invalid coins value. Must be a positive number"
}
```

or

```json
{
  "error": "Invalid userid"
}
```

#### 409 Conflict – Duplicate Transaction

```json
{
  "error": "Duplicate transaction detected",
  "message": "This user has already completed this promotion app in this application"
}
```

**Note:** The same user can complete the promotional app task in both `cashraze` and `cashalpha` separately. However, they cannot complete it twice in the same app.

#### 403 Forbidden – Invalid API Key

```json
{
  "error": "Unauthorized - Invalid API key"
}
```

#### 404 Not Found – User Not Found

```json
{
  "error": "User not found"
}
```

#### 500 Internal Server Error

```json
{
  "status": "failed",
  "message": "Server error occurred",
  "error": "Error details"
}
```

## Example Requests

### Example 1: cURL (Cash Raze)

```bash
curl -X POST https://grabrewardserver.vercel.app/api/postback/promotion-apps \
  -H "Content-Type: application/json" \
  -d '{
    "apiKey": "cashapps123",
    "userid": "firebase-user-id-123",
    "coins": 150,
    "details": "Rewards",
    "referrer": "ref_id=firebase-user-id-123&pid=cashraze"
  }'
```

### Example 2: cURL (Cash Alpha)

```bash
curl -X POST https://grabrewardserver.vercel.app/api/postback/promotion-apps \
  -H "Content-Type: application/json" \
  -d '{
    "apiKey": "cashapps123",
    "userid": "firebase-user-id-123",
    "coins": 150,
    "details": "Rewards",
    "referrer": "ref_id=firebase-user-id-123&pid=cashalpha"
  }'
```

### Example 3: JavaScript (Node.js - External App Format)

```javascript
const axios = require('axios');

// Extract userid and pid from referrer
const referrer = "ref_id=firebase-user-id-123&pid=cashraze";
const userid = referrer.split("ref_id=")[1].split("&")[0];
const pid = referrer.includes("pid=") 
  ? referrer.split("pid=")[1].split("&")[0] 
  : "cashraze";

const body = {
  userid: userid,
  coins: 150,
  details: "Rewards",
  apiKey: 'cashapps123'
};

const response = await axios.post(
  'https://grabrewardserver.vercel.app/api/postback/promotion-apps',
  body,
  {
    headers: { 'Content-Type': 'application/json' },
  }
);

if (response.status === 200 && response.data.status === 'success') {
  console.log('Reward granted:', response.data);
} else {
  console.error('Error:', response.data.error || response.data.message);
}
```

## How It Works Internally

1. Validates that `apiKey` and `coins` are present and valid.
2. Verifies `apiKey` against `cashapps123` or `MYSTERY_KEY` environment variable.
3. **Extracts `userid` from the `referrer` parameter's `ref_id` field** (or uses provided `userid` as fallback).
4. **Extracts `appId` from the `referrer` parameter's `pid` field** (defaults to `cashraze` if not provided).
5. Confirms that the user document exists in the `users` collection.
6. Checks for duplicate completions by verifying if this user has already received a reward for this promotion app in the same application (cashraze or cashalpha).
7. Generates a unique `transactionId` based on `userid`, `appId`, and timestamp.
8. Uses `addOfferwallRecord('PROMOTION_APP', userid, coins, transactionId)` to:
   - Update the user's coin balance and totals.
   - Store a reward record in Firestore with `appId` and `details` metadata.
   - (If configured) send a notification to the user.

**Key Feature:** The backend extracts both `userid` and `appId` from the `referrer` parameter, allowing the same server endpoint to handle multiple apps (cashraze, cashalpha, etc.) without requiring mobile app updates. The `pid` parameter in the referrer determines which app the user is using, enabling separate tracking per app.

## Important Notes

### Separate Tracking for Cash Raze and Cash Alpha

- The same user **can** complete the promotional app task in both `cashraze` and `cashalpha` separately.
- The same user **cannot** complete the promotional app task twice in the same application.
- The `appId` is automatically extracted from the `referrer` parameter's `pid` field.
- If `pid` is not provided or is invalid, the system defaults to `cashraze`.

### Referrer Parameter Format

The `referrer` parameter should follow this format:
```
ref_id=USER_ID&pid=cashraze
```
or
```
ref_id=USER_ID&pid=cashalpha
```

Where:
- `ref_id` contains the Firebase user UID
- `pid` specifies which app: `cashraze` or `cashalpha`

## Integration Checklist

- **Use** the API key `cashapps123` for external promotional apps.
- **Extract** the `userid` from the `referrer` parameter's `ref_id` field.
- **Include** the `pid` parameter in the `referrer` to specify which app (cashraze or cashalpha).
- **Call** this endpoint after the user has completed the promotional app flow.
- **Send** a positive `coins` value according to your campaign rules.
- **Handle** HTTP status codes:
  - `200` – success, reward granted.
  - `400` – bad request (missing/invalid fields).
  - `403` – invalid API key.
  - `404` – user not found.
  - `409` – duplicate transaction (user already completed in this app).
  - `500` – server error (you may retry with backoff).

## Security Notes

- Always use **HTTPS** when calling this endpoint.
- Keep the `apiKey` secret and never expose it in client-side or public code.
- Log and monitor your calls to detect abuse or misconfiguration.
