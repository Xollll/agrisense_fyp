# AI Recommendation Error - Root Cause & Fix

## Problem
You were getting **"Error generating recommendation"** message when trying to generate AI recommendations.

## Root Cause
The issue was a **timeout conflict** between two HTTP timeout settings:

1. **HttpRetryService**: Had a hardcoded 1.2-second timeout
   - This is designed for fast local/internal API calls
   - Way too short for Gemini API calls

2. **GeminiService**: Tried to set a 30-second timeout
   - But the retry service's timeout was being enforced FIRST
   - The request was timing out after 1.2 seconds before completion

### Timeline of the Error
```
Request starts
    ↓
HttpRetryService.post() is called with 1.2s timeout
    ↓
Makes HTTP request to Gemini API (Google's servers)
    ↓
1.2 seconds pass → TIMEOUT EXCEPTION
    ↓
Retries once more, fails again at 1.2s
    ↓
Throws timeout exception
    ↓
GeminiService catches it and returns "Error generating recommendation."
```

## Solution
Made the `HttpRetryService.post()` method accept an optional `timeout` parameter:

### Changes Made

#### 1. **lib/services/http_retry_service.dart**
- Added `Duration? timeout` parameter to the `post()` method
- Uses `timeout ??= requestTimeout` to fall back to default if not provided
- Passes the timeout parameter through all retry attempts
- This allows callers to specify custom timeouts for different API calls

**Before:**
```dart
static Future<http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  int retries = maxRetries,
  Duration? delay,
}) async {
  // ...
  .timeout(requestTimeout);  // ❌ Always 1.2 seconds!
}
```

**After:**
```dart
static Future<http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  int retries = maxRetries,
  Duration? delay,
  Duration? timeout,  // ✅ NEW parameter
}) async {
  timeout ??= requestTimeout;  // ✅ Use custom timeout if provided
  // ...
  .timeout(timeout);
}
```

#### 2. **lib/gemini_service.dart**
- Updated `_makeApiRequest()` to pass the 30-second timeout when calling HttpRetryService
- This ensures Gemini API requests have enough time to complete

**Before:**
```dart
final response = await HttpRetryService.post(
  url,
  headers: {"Content-Type": "application/json"},
  body: body,
).timeout(NetworkConfig.geminiRequestTimeout);  // ❌ Too late - retry service already timed out
```

**After:**
```dart
final response = await HttpRetryService.post(
  url,
  headers: {"Content-Type": "application/json"},
  body: body,
  timeout: NetworkConfig.geminiRequestTimeout,  // ✅ Passed to retry service
);
```

## How It Works Now

1. **Fast API calls** (detection server): Use default 1.2-second timeout
2. **Slow API calls** (Gemini): Get custom 30-second timeout
3. **Flexible**: Future API calls can specify their own timeout

## Benefits
- ✅ Recommendations now generate successfully
- ✅ Retry logic still works correctly
- ✅ Backward compatible (other calls still work)
- ✅ Extensible (other services can specify custom timeouts)

## Testing
To verify the fix works:
1. Take a photo with a disease
2. Tap "Get AI Recommendation" button
3. You should now see the recommendation instead of error message
4. If network is slow, it may take up to 30 seconds (normal for AI processing)

## Network Config Reference
```dart
// lib/config/network_config.dart
static const Duration geminiRequestTimeout = Duration(seconds: 30);
```

This is the correct timeout for Gemini API - enough time for the AI to generate content.
