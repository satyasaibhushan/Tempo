# Tempo - Project Outline

## Project Overview
A personal-use time tracking application with a web-first MVP and a backend designed from day one for future iOS and macOS apps. The product should feel like a focused Timery/Toggl-style tracker for one user, with reliable timers, tags, folders and sub-folders, and real-time sync across platforms once the Apple apps are added.

## Product Direction
- Build the web app first and treat it as the MVP
- Keep the backend, schema, and domain model stable so iOS and macOS apps can reuse them later
- Optimize for personal productivity, not for invoicing, billing, client work, or team collaboration
- Do not introduce organizations or workspaces; each user account owns its own data directly
- Support real-time sync across platforms through Convex
- Defer offline support on the web; require connectivity for the web MVP

---

## Technology Stack

### Frontend
- **Web Application**: Next.js (App Router) + React + TypeScript
  - Tailwind CSS for styling
  - shadcn/ui for foundational components
  - date-fns for date and duration handling

- **iOS Application**: Swift + SwiftUI
  - WidgetKit for widgets
  - App Intents for Shortcuts
  - Shared domain contracts aligned with the web app and Convex schema

- **macOS Application**: Swift + SwiftUI
  - Shared codebase with iOS where possible
  - WidgetKit for widgets
  - Native macOS adaptations for navigation and menu bar access

### Backend
- **Convex**: primary backend across all platforms
  - Real-time database with subscriptions
  - TypeScript queries, mutations, and actions
  - Stable API surface for web and future Apple apps

### Authentication
- **Selected: Auth0 + Convex**
  - Use Auth0 as the shared auth provider across web, iOS, and macOS
  - Enable Google login through Auth0 Social Connections
  - Keep email/password available as a fallback option
  - Auth0's free plan is sufficient for this personal app unless usage grows far beyond personal scale

### Workspace / Repo Layout
- **Monorepo from the start**
  - `apps/web` for Next.js
  - `apps/apple` reserved for future Swift app workspace/project
  - `convex` for backend functions and schema
  - `packages/shared` for shared TypeScript types, constants, and business rules used by the web app

---

## Why Convex Stays
- Convex is still a good fit for this project because real-time sync is a core requirement
- The backend logic stays in TypeScript, which keeps the web app and backend aligned
- Future iOS/macOS apps can consume the same data model without replacing the backend
- Simpler alternatives like Supabase are viable, but they would require more custom real-time orchestration and backend logic for a timer-heavy app

## Cost Strategy
- Aim to stay on hosted free tiers for as long as possible
- Convex's free/starter limits are likely sufficient for a personal tracker
- Auth0's free tier is sufficient for cross-device login plus Google auth for this project
- Avoid introducing paid-only infrastructure for the MVP

---

## Core Features

### 1. Web MVP

#### Timer Tracking
- Start, stop, pause, and resume a timer
- Allow multiple active timers per user
- Align every live display to the same wall-clock second boundary
- Show live running time on the dashboard
- Allow a timer title and optional notes
- Continue a previous timer with the same setup
- Timers may start with no title

#### Manual Entries
- Add past entries manually
- Edit title, notes, folder, labels, and timestamps
- Delete entries

#### Organization
- A single hierarchy of folders only
- Folders can contain child folders recursively
- A built-in `Inbox` folder exists as the default uncategorized location
- Labels can be attached to folders as defaults
- Default labels cascade down through descendant folders
- Labels can also be attached directly to individual timers
- Archive folders without deleting history

#### Views
- Dashboard with current timer and recent entries
- Entries page grouped by date
- Folder management
- Labels management
- Basic personal reports: today, this week, this month

### 2. Future Apple Apps
- Native iOS and macOS apps using the same backend model
- Real-time sync with the web app
- Widgets for the active timer and daily totals
- Shortcuts integration for starting/stopping timers
- Focus mode automation after the core apps are stable

---

## Domain Model

### Design Principles
- Keep the backend authoritative for timer state
- Model pause and resume explicitly so the same logic works on web and native apps
- Use a single hierarchical folder model instead of separate folders and projects
- Labels are reusable user-owned entities that can be applied by folder defaults and by individual timers
- Folder label inheritance should be deterministic and easy to compute for any selected folder

### Users
```typescript
{
  _id: Id<"users">,
  authProvider: "auth0",
  authSubject: string,
  email?: string,
  name?: string,
  avatarUrl?: string,
  timezone: string,
  weekStart: "monday" | "sunday",
  timeFormat: "12h" | "24h",
  createdAt: number,
  updatedAt: number,
}
```

### Tenancy Model
- There is no organization or workspace table
- Every folder, label, and time entry belongs directly to a single user
- If multi-user support is ever added, it should be treated as a separate product change rather than something implied by the MVP schema

### Folders
```typescript
{
  _id: Id<"folders">,
  userId: Id<"users">,
  name: string,
  color?: string,
  parentFolderId?: Id<"folders">,
  defaultLabelIds: Id<"labels">[],
  isInbox: boolean,
  archived: boolean,
  sortOrder: number,
  createdAt: number,
  updatedAt: number,
}
```

### Labels
```typescript
{
  _id: Id<"labels">,
  userId: Id<"users">,
  name: string,
  color: string,
  createdAt: number,
  updatedAt: number,
}
```

### TimeEntries
```typescript
{
  _id: Id<"timeEntries">,
  userId: Id<"users">,
  folderId: Id<"folders">,
  title: string,
  notes?: string,
  labelIds: Id<"labels">[],
  inheritedLabelIds: Id<"labels">[],
  manualLabelIds: Id<"labels">[],
  status: "running" | "paused" | "completed",
  segments: Array<{
    startTime: number,
    endTime?: number,
  }>,
  startedAt: number,
  endedAt?: number,
  durationSeconds?: number,
  createdAt: number,
  updatedAt: number,
}
```

### Timer Rules
- Multiple entries can be in `running` or `paused` state for a user at a time
- Timer lifecycle timestamps use whole-second precision
- `segments` is the source of truth for pause and resume
- `durationSeconds` is derived and stored when needed for fast reporting
- Timer calculations should use server time where possible, with client-side live updates for display only
- Every timer belongs to one folder
- The `Inbox` folder is used when a folder is missing or content is moved out of a deleted folder
- Folder default labels are applied automatically when creating a timer
- Folder default labels are inherited from all ancestor folders up to the selected folder
- Individual timers may add extra labels beyond inherited defaults

---

## Application Architecture

### Repository Structure
```text
/apps
  /web
    /app
    /components
    /lib
    /types
  /apple            # reserved for future Xcode workspace/project

/convex
  /queries
  /mutations
  /actions
  schema.ts

/packages
  /shared
    /src
      /domain
      /constants
      /formatters
```

### Web App Areas
```text
/app
  /(auth)
  /dashboard
  /entries
  /folders
  /labels
  /settings
```

### Future Apple App Areas
```text
/Tempo
  /Models
  /Views
  /ViewModels
  /Services
  /Widgets
  /Shortcuts
  /Shared
```

---

## Development Phases

### Phase 1: Web MVP + Stable Foundation
**Goal**: Ship a reliable personal time tracker on the web without painting the backend into a corner for future native apps.

- Monorepo setup
- Convex schema and backend functions
- Auth0 authentication with Google login integrated
- Users, folders, labels, and time entries
- Running timer with pause and resume
- Manual entries and editing
- Dashboard and entries list
- Basic personal reports and filters

### Phase 2: iOS App Core
**Goal**: Reuse the same backend and domain model in a native iPhone app.

- SwiftUI app foundation
- Shared auth strategy
- Timer interface
- Entries and folder browsing
- Real-time sync with the web app

### Phase 3: macOS App + Apple Automation
**Goal**: Extend the same model to desktop Apple workflows.

- macOS app target
- Widgets
- App Intents and Shortcuts
- Focus mode automation

### Phase 4: Personal Reporting and Refinement
**Goal**: Better visibility and polish for long-term personal use.

- Improved reporting views
- CSV and JSON export
- Accessibility and performance
- Optional native offline queueing later if needed

---

## Key Technical Decisions

### Authentication
- Use Auth0 as the long-term auth provider
- Enable Google login in Auth0 from the beginning
- Keep the integration aligned across web and future Apple apps
- Avoid choosing a web-only auth path that will complicate future native apps

### Real-time Sync
- Convex subscriptions are the default sync mechanism
- The same schema and backend functions must serve web and native apps

### Web Offline Support
- The web MVP is online-only
- Basic optimistic UI is fine, but there is no requirement to work without connectivity
- Offline queueing can be considered later for native apps, where it is more useful

### Timer Accuracy
- Server timestamps should be authoritative for mutations
- The client updates the displayed timer every second
- On stop or pause, the client reconciles with the backend response

### Organization Model
- There is only one hierarchy type: folders
- Folders are hierarchical and recursive
- Labels can be set as defaults on folders
- Default labels cascade from parent folders to descendant folders
- Labels can also be added directly on time entries
- The system should always maintain an `Inbox` folder for fallback placement

### Personal-Use Scope
- No billable hours
- No invoicing
- No clients
- No team, workspace, or organization features

---

## Success Metrics

### MVP Functionality
- Timer start, stop, pause, and resume are reliable
- Concurrent timers remain independent and tick in sync
- Folders and labels are easy to manage
- Entries can be added manually and edited later
- The web app feels fast and stable for daily personal use

### Cross-Platform Foundation
- The backend schema does not need redesign before iOS/macOS work begins
- Auth, sync, and timer logic can be reused by future Apple apps
- Shared naming and domain concepts stay consistent across platforms

---

## Next Steps
1. Deploy the web app and Convex backend
2. Run a production smoke test for authentication, timers, and reporting
3. Begin the native iOS app foundation in `apps/apple`

---

**Last Updated**: July 11, 2026
**Status**: Web MVP accepted; production deployment is next, followed by iOS development
