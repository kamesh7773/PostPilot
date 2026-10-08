# Instagram AI Social Media Automation — Technical Specification

> **Project goal:** Build a Flutter application for influencers/creators that connects to Instagram through Meta's official APIs and lets users plan, create, schedule, publish, and analyze Instagram content with an AI agent.

## 1. Product Vision

The application is an **AI social media manager** for creators.

Core workflow:

```text
Creator
  ↓
Flutter App
  ↓
Connect Instagram
  ↓
OAuth / Meta authorization
  ↓
Backend
  ↓
AI Strategy + Content + Scheduling
  ↓
Instagram Graph API / Instagram API
  ↓
Publish
  ↓
Collect performance data
  ↓
AI learns what works
  ↓
Improve next content plan
```

The product should not promise guaranteed reach. It should provide **AI-assisted optimization** based on the creator's content history, audience behavior, and available insights.

---

# 2. Important Platform Rule

Use **Meta's official Instagram APIs only**.

Do **not** depend on:

- private Instagram APIs
- reverse-engineered endpoints
- browser automation
- Instagram password automation
- unofficial scraping/login libraries

The official API has account, permission, publishing, and feature limitations. The application must check the current Meta documentation before implementing each feature.

---

# 3. Account Types

The product should primarily target:

- Instagram Professional accounts
  - Business
  - Creator

A normal personal Instagram account should not be assumed to have the same publishing API capabilities.

The app should show the user which account type and API capabilities are available after connection.

---

# 4. Main Features

## MVP

1. Connect Instagram
2. Secure OAuth authorization
3. Detect connected Instagram account
4. Upload image/video
5. Create caption
6. Schedule post
7. Publish automatically
8. Show publishing status
9. Store Instagram media ID
10. Handle publishing failures

## Version 2

- AI caption generation
- AI hashtag suggestions
- Content calendar
- Recommended publishing times
- Reels
- Carousels
- Analytics
- Post history
- Drafts
- Retry failed posts

## Version 3

- AI content strategy
- AI content ideas
- AI content calendar
- Automatic scheduling
- Performance analysis
- Automatic optimization
- Autopilot mode

## Future

- TikTok
- YouTube
- Facebook
- LinkedIn
- Cross-platform content adaptation

---

# 5. User Modes

## Manual

The AI only provides recommendations.

```text
AI recommendation
      ↓
User approves
      ↓
Scheduled
      ↓
Published
```

## Copilot

The AI prepares content and scheduling but asks for approval before publishing.

## Autopilot

The AI can:

- choose content
- generate captions
- recommend/create schedules
- schedule content
- publish supported content
- analyze performance
- adjust future strategy

Autopilot should have clear user controls and an emergency pause button.

---

# 6. Suggested Flutter Architecture

```text
Flutter
├── Authentication
├── Onboarding
├── Instagram Connection
├── Dashboard
├── Content Calendar
├── Create Content
├── AI Assistant
├── Drafts
├── Scheduled Posts
├── Published Posts
├── Analytics
├── Account Settings
└── Autopilot Settings
```

Suggested Flutter stack:

```text
Flutter
Dart
Riverpod or Bloc
GoRouter
Dio
Freezed / json_serializable
Secure storage
```

The exact packages can change; keep the frontend independent of Meta API details.

---

# 7. Do NOT Call Meta APIs Directly From Flutter

Recommended architecture:

```text
Flutter
   |
   | HTTPS
   v
Your Backend API
   |
   +---- Authentication
   |
   +---- Instagram service
   |
   +---- AI service
   |
   +---- Scheduler
   |
   +---- Analytics service
   |
   +---- Media service
   |
   v
Meta APIs
```

Reasons:

- never expose app secrets in Flutter
- protect access tokens
- centralize publishing logic
- retry failed jobs
- schedule posts reliably
- support multiple social platforms later
- keep AI tools server-side

---

# 8. Recommended Backend

A practical stack:

```text
Node.js
TypeScript
PostgreSQL
Redis
Queue/Worker system
Object storage
```

Possible infrastructure:

```text
API server
Worker server
PostgreSQL
Redis
Object storage
Monitoring/logging
```

The exact hosting provider can be selected later.

---

# 9. Meta Developer Setup

Create an application in Meta for Developers.

The Meta application will be responsible for:

- OAuth
- permissions
- Instagram API access
- application credentials
- app review / access requirements
- production configuration

The exact dashboard labels and permission names can change, so implementation should always be checked against the current Meta documentation.

---

# 10. Instagram Authorization

High-level flow:

```text
Flutter
   ↓
User taps "Connect Instagram"
   ↓
Meta authorization page
   ↓
User logs in
   ↓
User authorizes application
   ↓
Authorization callback
   ↓
Backend exchanges/handles authorization
   ↓
Backend stores required token data securely
   ↓
Instagram account connected
```

Never ask users for their Instagram password.

---

# 11. OAuth Security

Access tokens are sensitive credentials.

Rules:

- never store them in Flutter local storage as the primary source
- never put them in source code
- never log tokens
- encrypt sensitive token data at rest
- use HTTPS
- restrict backend access
- rotate/refresh tokens according to Meta's supported mechanism
- revoke/disconnect credentials when the user disconnects the account

Recommended database approach:

```text
instagram_accounts
    access_token_encrypted
    token_expires_at
    instagram_user_id
```

---

# 12. Instagram Account Model

Example:

```text
User
 └── InstagramAccount
       ├── instagram_user_id
       ├── username
       ├── account_type
       ├── profile_picture
       ├── access_token
       ├── token_expires_at
       ├── connected_at
       └── status
```

A single application user should eventually be able to connect multiple supported social accounts.

---

# 13. Database Schema

## users

```text
id
email
name
created_at
updated_at
```

## social_accounts

```text
id
user_id
platform
platform_user_id
username
access_token_encrypted
refresh_token_encrypted
token_expires_at
status
created_at
updated_at
```

## instagram_accounts

```text
id
social_account_id
instagram_user_id
username
account_type
profile_picture_url
```

## content

```text
id
user_id
type
title
caption
media_url
thumbnail_url
status
created_at
updated_at
```

Possible types:

```text
IMAGE
VIDEO
REEL
CAROUSEL
STORY
```

## scheduled_posts

```text
id
content_id
social_account_id
scheduled_at
timezone
status
attempt_count
last_error
published_at
platform_media_id
created_at
updated_at
```

## analytics

```text
id
content_id
platform
impressions
reach
likes
comments
shares
saves
views
watch_time
captured_at
```

---

# 14. Media Storage

Instagram publishing generally requires media to be available to Meta in the manner required by the API.

Recommended flow:

```text
Flutter
   ↓
Backend / signed upload
   ↓
Object Storage
   ↓
Publicly accessible / API-compatible media URL
   ↓
Meta
```

Do not rely on a local file sitting on the user's phone when a scheduled post executes hours later.

The backend should own the media lifecycle.

---

# 15. Publishing Architecture

Generic publishing flow:

```text
Scheduled Job
     ↓
Validate content
     ↓
Validate Instagram account
     ↓
Validate token
     ↓
Validate media
     ↓
Create Instagram media container
     ↓
Wait/check processing status when required
     ↓
Publish container
     ↓
Receive platform media ID
     ↓
Save result
     ↓
Notify user
```

Important:

**Container creation and publishing are separate conceptual steps.**

Do not assume that uploading/creating a container automatically means the post is live.

---

# 16. Posts

Supported professional-account publishing capabilities should be implemented according to the current Meta API documentation.

Typical application flow:

```text
Image
 ↓
Upload/store media
 ↓
Create media container
 ↓
Publish
 ↓
Instagram post
```

Store:

```text
platform_media_id
published_at
status
```

---

# 17. Reels

Reels should have their own publishing service because video processing can take longer and has additional media requirements.

Generic flow:

```text
Flutter
 ↓
Upload Reel
 ↓
Backend storage
 ↓
Create Reel media container
 ↓
Check processing/status
 ↓
Publish
 ↓
Save Instagram media ID
```

The exact endpoint parameters, supported video specifications, and processing behavior must be verified against the current Meta documentation before implementation.

---

# 18. Carousel

Conceptually:

```text
Image 1
Image 2
Image 3
   ↓
Create individual media items
   ↓
Create carousel container
   ↓
Publish carousel
```

The backend should validate:

- number of items
- supported media formats
- media availability
- account/API support

before creating the container.

---

# 19. Stories

Stories require special treatment.

Do not assume that every feature available in the Instagram mobile application is available through the official API.

The product should:

```text
Check account
Check API capability
Check supported Story publishing capability
Show only supported options
```

Avoid promising:

- every sticker
- every interactive element
- every music feature
- every Instagram-app editing feature

The Story API capabilities can change, so keep Story publishing behind a dedicated provider/service.

---

# 20. Captions

The AI can generate captions.

Example input:

```json
{
  "niche": "fitness",
  "topic": "beginner workout",
  "tone": "friendly",
  "audience": "18-30",
  "language": "English"
}
```

Example output:

```text
5 beginner exercises you can start today 💪

No complicated equipment.
No advanced experience.

Save this for your next workout.

#fitness #workout #beginnerfitness
```

The user should always be able to edit the generated caption.

---

# 21. Hashtags

Do not treat hashtags as a guaranteed reach mechanism.

AI can:

- suggest relevant hashtags
- avoid irrelevant tags
- group hashtags by topic
- learn which combinations correlate with performance

But avoid claims such as:

> "These hashtags guarantee viral reach."

---

# 22. AI Content Strategy

The AI should maintain a creator profile.

Example:

```json
{
  "niche": "fitness",
  "audience": "young adults in India",
  "tone": "friendly",
  "content_pillars": [
    "workouts",
    "nutrition",
    "motivation",
    "transformations"
  ],
  "goals": [
    "followers",
    "engagement",
    "reach"
  ]
}
```

---

# 23. AI Content Calendar

Example:

```text
Monday
Reel — Beginner workout
7:30 PM

Tuesday
Carousel — Nutrition tips
1:00 PM

Wednesday
Story — Q&A
8:00 PM

Thursday
Reel — Gym mistakes
7:30 PM

Friday
Carousel — Workout guide
6:00 PM

Saturday
Reel — Transformation
8:00 PM
```

The time should be treated as a recommendation, not a guaranteed best time.

---

# 24. AI Agent Architecture

Do not build one giant unrestricted AI agent.

Recommended architecture:

```text
                AI ORCHESTRATOR
                       |
       +---------------+---------------+
       |               |               |
       v               v               v
 Strategy Agent   Content Agent   Analytics Agent
       |               |               |
       +---------------+---------------+
                       |
                       v
                Publishing Agent
                       |
                       v
                  Social APIs
```

---

# 25. AI Tools

Give the AI controlled tools such as:

```text
get_creator_profile()
get_recent_posts()
get_post_metrics()
analyze_content_performance()

generate_content_ideas()
generate_caption()
generate_hashtags()

find_recommended_posting_time()
create_content_plan()
create_schedule()

create_draft()
schedule_post()
publish_post()

pause_autopilot()
```

The AI should not have unrestricted database or API access.

---

# 26. AI Agent Safety

Every publishing action should be validated.

For example:

```text
AI says:
"Publish this Reel."

Backend:
- Is the user authorized?
- Is account connected?
- Is token valid?
- Is media valid?
- Is content approved under current user mode?
- Is scheduled time valid?
- Is platform publishing available?
```

Only then:

```text
Publish
```

---

# 27. Scheduler

Never depend on the Flutter application being open.

Bad architecture:

```text
Flutter
 ↓
Timer
 ↓
Instagram
```

Good architecture:

```text
Post scheduled
     ↓
Database
     ↓
Queue
     ↓
Worker
     ↓
Instagram API
```

The user's phone can be offline.

---

# 28. Scheduler Timezones

Every scheduled post should store:

```text
scheduled_at_utc
timezone
```

Example:

```text
User timezone:
Asia/Kolkata

Requested:
7:30 PM

Store:
UTC timestamp + Asia/Kolkata
```

This prevents daylight-saving/timezone issues for international users.

---

# 29. Retry System

Publishing can fail.

Example states:

```text
SCHEDULED
   ↓
PROCESSING
   ↓
PUBLISHING
   ↓
PUBLISHED
```

Failure:

```text
PUBLISHING
   ↓
FAILED
   ↓
Retry
```

Use exponential backoff where appropriate.

Example:

```text
Attempt 1 → immediately
Attempt 2 → 1 minute
Attempt 3 → 5 minutes
Attempt 4 → 15 minutes
```

Do not blindly retry permanent API errors.

---

# 30. Idempotency

The scheduler must prevent duplicate publishing.

Example:

```text
scheduled_post_id = 123
status = PUBLISHED
platform_media_id = abc123
```

If the worker runs again:

```text
Check status
    ↓
Already PUBLISHED
    ↓
Do nothing
```

This is extremely important.

---

# 31. Analytics

The backend should periodically collect available Instagram insights.

Potential metrics include:

```text
reach
impressions
likes
comments
shares
saves
views
engagement
```

Exact metrics available depend on content type, API capabilities, account type, and current Meta API version.

Never hard-code assumptions about a metric being available forever.

---

# 32. AI Performance Loop

The most valuable feature is the feedback loop.

```text
Create
  ↓
Publish
  ↓
Collect metrics
  ↓
Analyze
  ↓
Identify patterns
  ↓
Update creator strategy
  ↓
Create better content
```

Example:

```text
Last 30 days:

Reels:
Average reach = 42,000

Carousels:
Average reach = 12,000

Best topic:
Beginner workouts

Weak topic:
Generic motivational quotes
```

AI recommendation:

```text
Increase beginner-workout Reels.

Reduce generic quote content.

Test educational hooks.

Continue testing evening publishing windows.
```

This is optimization, not a guarantee of reach.

---

# 33. Content Scoring

Before scheduling, AI can score content.

Example:

```text
Hook:          8/10
Relevance:     9/10
Clarity:       8/10
Originality:   7/10
Audience fit:  9/10
CTA:           7/10
```

Then:

```text
Overall:
8.0/10
```

The score should be presented as an AI heuristic, not an Instagram ranking score.

---

# 34. Content Approval

Recommended UX:

```text
AI created content

[ Preview ]

Caption:
...

Recommended time:
Friday 7:30 PM

[ Edit ]
[ Approve ]
[ Schedule ]
```

For Autopilot:

```text
Autopilot enabled

AI may automatically:
✓ Generate ideas
✓ Create captions
✓ Schedule content
✓ Publish supported content
✓ Analyze performance
```

Include:

```text
[ PAUSE AUTOPILOT ]
```

---

# 35. Flutter Screens

Recommended initial screens:

```text
Splash
Login
Onboarding

Dashboard

Connect Accounts

Instagram Account
    ├── Profile
    ├── Connection status
    └── Permissions

AI Assistant

Create Content

Content Preview

Calendar

Scheduled Posts

Published Posts

Analytics

Autopilot

Settings
```

---

# 36. Dashboard

Example:

```text
Good evening, Creator 👋

This week

Posts       3
Reels       4
Stories     5

Reach       +18%
Engagement  +12%

AI Recommendation

"Your educational Reels are performing
better than motivational posts."

[ View strategy ]
```

---

# 37. Content Calendar

Calendar should show:

```text
MON
7:30 PM
🎬 Reel

TUE
1:00 PM
📸 Carousel

WED
8:00 PM
📱 Story

THU
7:30 PM
🎬 Reel
```

Actions:

```text
Edit
Reschedule
Duplicate
Delete
Publish now
```

---

# 38. API Abstraction

Do not hard-code Instagram throughout the application.

Use:

```text
SocialPlatformProvider
```

Interface concept:

```text
connect()
disconnect()

getAccount()

createMedia()
publishMedia()

scheduleMedia()

getPost()
getInsights()
```

Then:

```text
InstagramProvider
TikTokProvider
YouTubeProvider
FacebookProvider
```

This makes future expansion much easier.

---

# 39. Backend API Example

Your Flutter app could communicate with your backend using endpoints such as:

```text
POST /auth/instagram/start
GET  /auth/instagram/callback

GET  /social-accounts
POST /social-accounts/instagram/connect
DELETE /social-accounts/:id

POST /content
GET  /content
PUT  /content/:id
DELETE /content/:id

POST /posts/:id/schedule
POST /posts/:id/publish
POST /posts/:id/cancel

GET /calendar
GET /analytics
GET /analytics/posts/:id

POST /ai/content-ideas
POST /ai/caption
POST /ai/content-plan
POST /ai/analyze

POST /autopilot/enable
POST /autopilot/disable
```

These are **your backend endpoints**, not Meta endpoints.

---

# 40. Webhooks

Where Meta provides supported webhook functionality, use webhooks for events instead of constantly polling.

Architecture:

```text
Meta
  ↓
Webhook
  ↓
Your backend
  ↓
Process event
  ↓
Database
  ↓
Flutter notification/update
```

Still implement polling where the API requires it, especially for asynchronous media processing.

---

# 41. Notifications

Notify users when:

```text
Post scheduled
Post published
Post failed
Token/account needs attention
AI generated new content
Weekly report ready
Autopilot made a strategy change
```

Flutter push notifications can be used for user-facing alerts.

---

# 42. Security Checklist

## Backend

- HTTPS only
- encrypted credentials
- no tokens in logs
- database access restrictions
- rate limiting
- request validation
- authentication
- authorization
- audit logs

## Flutter

- do not ship Meta app secret
- do not ship backend private credentials
- secure local session storage
- validate deep links / OAuth callbacks

---

# 43. Multi-Tenant Security

This is a SaaS product, so every database query must respect:

```text
user_id
```

Example:

```text
User A
  ↓
Can only access
  ↓
User A's Instagram account
User A's content
User A's analytics
```

Never trust a `user_id` supplied by the client without checking the authenticated session.

---

# 44. Audit Log

Keep an audit trail.

Example:

```text
2026-10-07 19:30
AI created Reel

2026-10-07 19:32
User approved Reel

2026-10-07 19:45
Post scheduled

2026-10-08 19:45
Instagram publish request

2026-10-08 19:46
Published successfully
```

For Autopilot, this becomes especially important.

---

# 45. Rate Limits

The system must respect Meta API rate limits.

Do not build:

```text
infinite requests
```

Use:

```text
queue
rate limiter
retry policy
caching
backoff
```

Meta can change limits and quotas, so retrieve the current limits from the official documentation when implementing production code.

---

# 46. API Versioning

Meta APIs are versioned.

Do not assume today's endpoint/version will remain unchanged.

Create a configuration value:

```text
META_GRAPH_API_VERSION
```

Example:

```text
vXX.X
```

The actual production version should be selected from Meta's current supported versions at implementation time.

---

# 47. Environment Variables

Example backend `.env`:

```text
META_APP_ID=
META_APP_SECRET=

META_REDIRECT_URI=

DATABASE_URL=

REDIS_URL=

STORAGE_BUCKET=
STORAGE_REGION=
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=

ENCRYPTION_KEY=

AI_API_KEY=

APP_BASE_URL=
```

Never commit `.env` files.

---

# 48. Development Environments

Use:

```text
Development
Staging
Production
```

Each should have separate:

- databases
- credentials
- storage
- Meta configuration where appropriate
- logs

---

# 49. Testing

## Unit tests

Test:

```text
caption generation
scheduling
timezone conversion
status transitions
retry logic
token validation
```

## Integration tests

Test:

```text
OAuth
Instagram account connection
media upload
container creation
publishing
analytics
webhooks
```

## Failure tests

Simulate:

```text
expired token
invalid media
API timeout
rate limit
duplicate worker execution
Instagram processing failure
network failure
```

---

# 50. Important Product Limitation

The official Instagram API does **not** mean:

> "Everything possible inside the Instagram app can be automated."

The application must explicitly distinguish:

```text
Supported by official API
```

from:

```text
Only possible inside Instagram app
```

Do not use private endpoints to bypass those limitations.

---

# 51. AI Agent Product Rules

The AI should never:

- promise viral reach
- guarantee follower growth
- spam users
- publish without permission when the user selected approval mode
- bypass Meta restrictions
- use private Instagram endpoints
- fabricate analytics
- invent unavailable API features

The AI should explain:

```text
"This is an optimization recommendation based on your historical data."
```

rather than:

```text
"This will make your Reel go viral."
```

---

# 52. Suggested MVP Milestones

## Milestone 1

```text
Flutter project
Backend project
Database
User authentication
```

## Milestone 2

```text
Meta Developer application
Instagram OAuth
Account connection
Token storage
```

## Milestone 3

```text
Image publishing
Video publishing
Reel publishing
```

## Milestone 4

```text
Scheduler
Queue
Workers
Retries
```

## Milestone 5

```text
Content calendar
Drafts
Publishing history
Notifications
```

## Milestone 6

```text
AI captions
AI content ideas
AI posting recommendations
```

## Milestone 7

```text
Analytics
AI performance analysis
```

## Milestone 8

```text
Autopilot
```

---

# 53. Recommended First Version

Do not start with:

```text
Instagram
TikTok
YouTube
Facebook
LinkedIn
AI video generation
AI image generation
AI voice
Autopilot
```

Start with:

```text
Flutter
+
Backend
+
Instagram
+
Image/Reel publishing
+
Scheduler
+
Basic AI captions
```

Once this works reliably, expand.

---

# 54. Product Differentiator

A normal scheduler:

```text
User chooses:
"What should I post?"
"When should I post?"
```

Your product:

```text
AI answers:
"What should I post?"
"Why?"
"When?"
"How should I write it?"
"What should I test next?"
"How did it perform?"
"What should we change?"
```

The strongest feature is the **closed feedback loop**:

```text
Plan
 ↓
Create
 ↓
Schedule
 ↓
Publish
 ↓
Measure
 ↓
Learn
 ↓
Optimize
 ↓
Repeat
```

---

# 55. Official Documentation

Always verify implementation details against Meta's current official documentation because API versions, permissions, supported media types, metrics, and review requirements can change.

Useful official starting points:

- Meta for Developers
- Instagram Platform documentation
- Instagram API documentation
- Meta app dashboard
- Meta developer app review documentation

Use official Meta documentation as the source of truth before production deployment.

---

# 56. Final Architecture

```text
                         ┌───────────────────────┐
                         │       Flutter         │
                         │                       │
                         │ Dashboard             │
                         │ Calendar              │
                         │ AI Assistant          │
                         │ Create Content        │
                         │ Analytics             │
                         │ Settings              │
                         └───────────┬───────────┘
                                     │
                                     │ HTTPS
                                     ▼
                         ┌───────────────────────┐
                         │     Backend API       │
                         │                       │
                         │ Auth                  │
                         │ Users                 │
                         │ Social Accounts       │
                         │ Content               │
                         │ Scheduler             │
                         │ AI Orchestrator       │
                         │ Analytics             │
                         └───────────┬───────────┘
                                     │
                 ┌───────────────────┼───────────────────┐
                 │                   │                   │
                 ▼                   ▼                   ▼
          ┌────────────┐      ┌────────────┐      ┌────────────┐
          │ PostgreSQL │      │   Redis    │      │  Storage   │
          │            │      │ Queue      │      │ Media      │
          └────────────┘      └─────┬──────┘      └────────────┘
                                    │
                                    ▼
                              ┌────────────┐
                              │  Workers   │
                              └─────┬──────┘
                                    │
                    ┌───────────────┼────────────────┐
                    │               │                │
                    ▼               ▼                ▼
             ┌────────────┐  ┌────────────┐  ┌────────────┐
             │ AI Service │  │ Instagram  │  │ Analytics  │
             │            │  │ Provider   │  │ Service    │
             └────────────┘  └─────┬──────┘  └────────────┘
                                   │
                                   ▼
                           ┌────────────────┐
                           │ Meta /         │
                           │ Instagram API  │
                           └────────────────┘
```

---

# 57. Core Principle

The application should be designed around this principle:

> **Flutter is the creator's control center. The backend is the automation engine. Meta's official API is the publishing layer. The AI is the strategy and decision layer.**

This separation will make the product scalable, secure, and much easier to extend to additional social platforms later.

---

## Implementation Note

Before writing production code, verify the **current Meta API version, Instagram Login flow, exact permissions, account eligibility, media requirements, publishing endpoints, Story capabilities, insights endpoints, rate limits, and app-review requirements** in Meta's official documentation.

This document is the product/engineering blueprint; individual Meta API parameters should be treated as version-specific implementation details.
