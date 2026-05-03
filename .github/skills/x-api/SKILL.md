

```yaml
---
name: x-api
description: X/Twitter API integration for posting tweets, threads, reading timelines, search, analytics, and account management. Covers OAuth 2.0 (recommended) and OAuth 1.0a, rate limits, media uploads, and platform-native content posting. Use when the user wants to interact with X programmatically (tweet, thread, search, timeline, bot, schedule, analytics).
origin: ECC
---

# X API

Programmatic interaction with X (Twitter) for posting, reading, searching, analytics, and account actions.  
Supports both modern OAuth 2.0 (preferred) and legacy OAuth 1.0a.

## When to Activate

- User wants to post tweets or threads programmatically (including scheduling)
- Reading timeline, mentions, or user data from X
- Searching X for content, trends, or conversations
- Building X integrations, bots, or analytics dashboards
- Account actions: follow, unfollow, like, retweet, delete tweet
- User says "post to X", "tweet", "X API", "Twitter API", "X bot", "schedule tweet"

## Authentication

Choose the authentication method based on your use case.

### OAuth 2.0 (Recommended)

**App-only Bearer Token** → Read-only public data, search, user lookup.  
No user login required.

```bash
export X_BEARER_TOKEN="your-bearer-token"
```

```python
import os
import requests

bearer = os.environ["X_BEARER_TOKEN"]
headers = {"Authorization": f"Bearer {bearer}"}
```

**Authorization Code Flow with PKCE** → User-context read/write (post, like, follow).  
Best for web apps, native apps, and services acting on behalf of a user.

> Implementation is more involved; use a library like `requests-oauthlib` or `oauthlib`.  
> See [X OAuth 2.0 docs](https://developer.x.com/en/docs/authentication/oauth-2-0) for full flow.

### OAuth 1.0a (Legacy, still works)

Required for some older endpoints (e.g., media upload v1.1) and if you need simple user-context auth.  
**Note:** X recommends migrating to OAuth 2.0 for new projects.

```bash
export X_API_KEY="your-api-key"
export X_API_SECRET="your-api-secret"
export X_ACCESS_TOKEN="your-access-token"
export X_ACCESS_SECRET="your-access-secret"
```

```python
import os
from requests_oauthlib import OAuth1Session

oauth = OAuth1Session(
    os.environ["X_API_KEY"],
    client_secret=os.environ["X_API_SECRET"],
    resource_owner_key=os.environ["X_ACCESS_TOKEN"],
    resource_owner_secret=os.environ["X_ACCESS_SECRET"],
)
```

## Core Operations

All examples use OAuth 1.0a (except where noted). For OAuth 2.0 user-context, adjust the client accordingly.

### Post a Tweet

```python
resp = oauth.post(
    "https://api.x.com/2/tweets",
    json={"text": "Hello from Claude Code"}
)
resp.raise_for_status()
tweet_id = resp.json()["data"]["id"]
```

### Post a Thread

```python
def post_thread(oauth, tweets: list[str]) -> list[str]:
    ids = []
    reply_to = None
    for text in tweets:
        payload = {"text": text}
        if reply_to:
            payload["reply"] = {"in_reply_to_tweet_id": reply_to}
        resp = oauth.post("https://api.x.com/2/tweets", json=payload)
        tweet_id = resp.json()["data"]["id"]
        ids.append(tweet_id)
        reply_to = tweet_id
    return ids
```

### Read User Timeline

```python
user_id = "2244994945"  # replace with actual user ID
resp = requests.get(
    f"https://api.x.com/2/users/{user_id}/tweets",
    headers=headers,
    params={
        "max_results": 10,
        "tweet.fields": "created_at,public_metrics",
    }
)
```

### Search Tweets (recent)

```python
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={
        "query": "from:affaanmustafa -is:retweet",
        "max_results": 10,
        "tweet.fields": "public_metrics,created_at",
    }
)
```

### Get User by Username

```python
resp = requests.get(
    "https://api.x.com/2/users/by/username/affaanmustafa",
    headers=headers,
    params={"user.fields": "public_metrics,description,created_at"}
)
```

### Upload Media and Post

> **Note:** Media upload uses X API v1.1 because v2 does not have a media endpoint.  
> Authentication must be OAuth 1.0a or OAuth 2.0 with write scope.

```python
# Step 1: Upload media to v1.1 endpoint
media_resp = oauth.post(
    "https://upload.twitter.com/1.1/media/upload.json",
    files={"media": open("image.png", "rb")}
)
media_id = media_resp.json()["media_id_string"]

# Step 2: Post with media using v2 endpoint (OAuth 1.0a or 2.0)
resp = oauth.post(
    "https://api.x.com/2/tweets",
    json={"text": "Check this out", "media": {"media_ids": [media_id]}}
)
```

### Delete a Tweet

```python
tweet_id = "1234567890123456789"
resp = oauth.delete(f"https://api.x.com/2/tweets/{tweet_id}")
resp.raise_for_status()
```

### Retweet

```python
# POST /2/users/:id/retweets
user_id = "me"  # or actual user ID
tweet_id = "1234567890123456789"
resp = oauth.post(f"https://api.x.com/2/users/{user_id}/retweets", json={"tweet_id": tweet_id})
```

### Like a Tweet

```python
# POST /2/users/:id/likes
user_id = "me"
tweet_id = "1234567890123456789"
resp = oauth.post(f"https://api.x.com/2/users/{user_id}/likes", json={"tweet_id": tweet_id})
```

### Get Followers

```python
user_id = "2244994945"
resp = requests.get(
    f"https://api.x.com/2/users/{user_id}/followers",
    headers=headers,
    params={"max_results": 100, "user.fields": "username,name"}
)
```

### Send a Direct Message (v2)

```python
# Requires OAuth 2.0 with dm_write scope
# First, get or create a conversation
conversation_id = "..."  # or use participant IDs
resp = oauth.post(
    "https://api.x.com/2/dm_conversations/:dm_conversation_id/messages",
    json={"text": "Hello via API", "participant_ids": ["123", "456"]}
)
```

## Utilities

### Validate Tweet Length

X allows 280 characters for regular accounts, 4000 for Premium/Blue subscribers.

```python
def validate_tweet_length(text: str, is_premium: bool = False) -> None:
    max_len = 4000 if is_premium else 280
    if len(text) > max_len:
        raise ValueError(f"Tweet exceeds {max_len} characters (actual: {len(text)})")
```

### Automatic Rate Limit Handling (Decorator)

```python
import time
from functools import wraps

def rate_limit_aware(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        while True:
            resp = func(*args, **kwargs)
            remaining = int(resp.headers.get("x-rate-limit-remaining", 1))
            if remaining > 0:
                return resp
            reset = int(resp.headers.get("x-rate-limit-reset", 0))
            wait = max(0, reset - int(time.time())) + 1
            time.sleep(wait)
    return wrapper
```

## Error Handling

```python
resp = oauth.post("https://api.x.com/2/tweets", json={"text": content})
if resp.status_code == 201:
    return resp.json()["data"]["id"]
elif resp.status_code == 429:
    reset = int(resp.headers["x-rate-limit-reset"])
    raise Exception(f"Rate limited. Resets at {reset}")
elif resp.status_code == 403:
    detail = resp.json().get("detail", "check permissions")
    raise Exception(f"Forbidden: {detail}")
elif resp.status_code == 401:
    raise Exception("Authentication failed – check your tokens")
else:
    raise Exception(f"X API error {resp.status_code}: {resp.text}")
```

## Rate Limits

X API rate limits vary by endpoint, auth method, account tier, and change over time.  
Always:
- Read `x-rate-limit-remaining` and `x-rate-limit-reset` headers at runtime.
- Back off automatically (use the decorator above).
- Check the [official rate limit docs](https://developer.x.com/en/docs/twitter-api/rate-limits) for current numbers.

Example of reading headers:

```python
remaining = int(resp.headers.get("x-rate-limit-remaining", 0))
reset = int(resp.headers.get("x-rate-limit-reset", 0))
print(f"Remaining: {remaining}, resets at {reset}")
```

## Quick Test: Verify Credentials

Copy-paste this to test your OAuth 1.0a setup:

```python
# Using OAuth 1.0a session from above
resp = oauth.get("https://api.x.com/1.1/account/verify_credentials.json")
if resp.status_code == 200:
    print(f"Authenticated as @{resp.json()['screen_name']}")
else:
    print(f"Auth failed: {resp.status_code}")
```

## Security

- **Never hardcode tokens.** Use environment variables or `.env` files.
- **Add `.env` to `.gitignore`** – never commit secrets.
- **Rotate tokens immediately** if exposed (regenerate at developer.x.com).
- **Use read-only tokens** when write access is not needed.
- **Store OAuth secrets securely** – never in logs or client-side code.
- **⚠️ Remote installation risk:** Do not `curl | bash` scripts from untrusted sources to install dependencies or run code – it can steal your tokens. Always review and use package managers or pinned hashes.

## Integration with Content Engine

Use `content-engine` skill to generate platform-native content, then post via X API:

1. Generate content with content-engine (X platform format)
2. Validate length with `validate_tweet_length()`
3. Post via X API using patterns above
4. Track engagement via `public_metrics`

## Related Skills

- `content-engine` – Generate platform-native content for X
- `crosspost` – Distribute content across X, LinkedIn, and other platforms

## Official Documentation

- [X API v2 Documentation](https://developer.x.com/en/docs/x-api)
- [Rate Limits Guide](https://developer.x.com/en/docs/twitter-api/rate-limits)
- [OAuth 2.0 for X](https://developer.x.com/en/docs/authentication/oauth-2-0)
- [Media Upload Guide](https://developer.x.com/en/docs/twitter-api/v1/media/upload-media)
```

---
