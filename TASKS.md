# Tempo - Development Tasks

## Task Management Guide
- Each task has an estimated complexity: `[Easy]`, `[Medium]`, `[Hard]`
- Tasks inside a phase should usually be completed in order
- This plan is intentionally scoped for a personal-use product
- There is no organization or workspace layer; every record belongs directly to one user
- There is no separate project model; folders are the only hierarchy type

---

## Phase 1: Web MVP + Cross-Platform Foundation

**Goal**: Ship a reliable web app first while keeping the backend and data model stable for future iOS and macOS apps.

### 1.1 Repository Foundation
- [x] `[Easy]` Set up the repo as a monorepo
  - `apps/web`
  - `apps/apple` placeholder for future native app work
  - `convex`
  - `packages/shared`
- [x] `[Easy]` Choose and configure the workspace package manager
  - Prefer `pnpm` workspaces for the monorepo
- [x] `[Easy]` Set up TypeScript, ESLint, Prettier, and shared path aliases
- [x] `[Easy]` Create environment variable conventions for web and Convex
- [x] `[Easy]` Create a starter README with setup steps after the first working app shell exists

### 1.2 Web App Setup
- [x] `[Easy]` Initialize Next.js App Router app in `apps/web`
- [x] `[Easy]` Install Tailwind CSS and core utility packages
  - `clsx`
  - `tailwind-merge`
  - `date-fns`
- [x] `[Easy]` Initialize shadcn/ui
- [x] `[Easy]` Create the initial app shell
  - Auth layout
  - Protected app layout
  - Global navigation

### 1.3 Shared Domain Contracts
- [x] `[Medium]` Create shared TypeScript domain types in `packages/shared`
  - User
  - Folder
  - Label
  - TimeEntry
  - Timer status and segment types
- [x] `[Easy]` Add shared domain constants and enums
  - Auth providers
  - Time formats
  - Week start options
  - Timer states
- [x] `[Easy]` Add shared default color tokens
  - Folder colors
  - Label colors
- [x] `[Medium]` Add shared formatting helpers used by the web app

### 1.4 Authentication Foundation
- [x] `[Medium]` Configure Auth0 for the web app
- [x] `[Medium]` Enable Google social login in Auth0
- [x] `[Medium]` Keep email/password login available as a fallback
- [x] `[Medium]` Connect Auth0 identity to Convex user records
- [x] `[Medium]` Implement login and sign-up flows
- [x] `[Easy]` Add protected routes and redirect handling
- [x] `[Easy]` Add logout flow
- [x] `[Easy]` Create first-run user provisioning in Convex

### 1.5 Convex Schema
- [x] `[Hard]` Create `convex/schema.ts`
  - Users table
  - Folders table with `parentFolderId`
  - Abstract `Inbox` rule via missing `folderId`
  - Folder `defaultLabelIds`
  - Labels table
  - TimeEntries table with `segments` and timer `status`
- [x] `[Medium]` Add indexes for common queries
  - By user
  - By folder parent
  - By `startedAt`
  - By running or paused timer state
- [x] `[Medium]` Document invariants in code comments
  - Multiple active timers are allowed per user
  - No organization scope
  - `Inbox` is abstract and represented by missing `folderId`
  - Root folders use missing `parentFolderId`

### 1.6 User Queries and Mutations
- [x] `[Easy]` Add query to fetch current user
- [x] `[Medium]` Add mutation to update user profile
- [x] `[Easy]` Add mutation to update user preferences
  - Timezone
  - Time format
  - Week start

### 1.7 Folder Management
- [x] `[Medium]` Add queries to list root folders and nested folders
- [x] `[Medium]` Add mutation to create folder
- [x] `[Medium]` Add mutation to rename folder
- [x] `[Medium]` Add mutation to move folder under another parent
- [x] `[Medium]` Add mutation to manage folder default labels
- [x] `[Medium]` Add logic to resolve inherited labels from the full folder ancestry
- [x] `[Medium]` Add mutation to archive and unarchive folder
- [x] `[Hard]` Add folder deletion behavior
  - Move direct child folders to root
  - Move timers in the deleted folder to `Inbox`
  - Preserve history

### 1.8 Label Management
- [x] `[Easy]` Add query to list labels
- [x] `[Medium]` Add mutation to create label
- [x] `[Easy]` Add mutation to update label
- [x] `[Easy]` Add mutation to delete label

### 1.9 Timer Engine
- [x] `[Hard]` Add query to fetch the current active timers
- [x] `[Hard]` Add mutation to start a timer
  - Allow independent concurrent timers
  - Create the first time segment
  - Default to `Inbox` when no folder is selected
  - Accept title, notes, folder, and labels
  - Apply inherited folder labels automatically
- [x] `[Hard]` Add mutation to pause a timer
  - Close the current segment
  - Mark entry as `paused`
- [x] `[Hard]` Add mutation to resume a timer
  - Open a new segment
  - Mark entry as `running`
- [x] `[Hard]` Add mutation to stop a timer
  - Close the current segment
  - Mark entry as `completed`
  - Compute `durationSeconds`
- [x] `[Medium]` Add mutation to discard an active timer
- [x] `[Medium]` Add mutation to continue a previous entry as a new running timer

### 1.10 Manual Entries and Entry CRUD
- [x] `[Medium]` Add query to list entries by date range
- [x] `[Medium]` Add query to list recent entries
- [x] `[Medium]` Add query to list entries with filters
  - Folder
  - Label
  - Date range
- [x] `[Hard]` Add mutation to create a manual entry with computed duration
- [x] `[Hard]` Add mutation to edit an existing completed entry
- [x] `[Easy]` Add mutation to delete an entry

### 1.11 Web UI Foundation
- [x] `[Easy]` Add core shadcn/ui components
  - Button
  - Input
  - Dialog
  - Select
  - Dropdown Menu
  - Card
  - Table
  - Popover
  - Calendar
  - Command
- [x] `[Medium]` Define a consistent app layout and navigation model
- [x] `[Medium]` Add reusable empty, loading, and error states

### 1.12 Web Pages
- [x] `[Medium]` Create dashboard page
- [x] `[Medium]` Create entries page
- [x] `[Medium]` Create folders page
- [x] `[Medium]` Create labels page
- [x] `[Easy]` Create settings page

### 1.13 Timer UI
- [x] `[Hard]` Build the primary timer component
  - Title input
  - Notes input
  - Folder picker
  - Label multi-select
  - Show inherited labels from the selected folder
  - Start, pause, resume, stop, discard controls
- [x] `[Medium]` Implement live second-by-second timer display
  - Use one shared wall-clock tick for every active timer
- [x] `[Medium]` Handle optimistic UI for timer actions
- [x] `[Medium]` Reconcile timer state with server responses
- [x] `[Medium]` Add clear error handling for invalid state transitions

### 1.14 Folders UI
- [x] `[Hard]` Build folder tree UI with nested display
- [x] `[Easy]` Show the built-in `Inbox` folder clearly
- [x] `[Medium]` Build folder create and rename dialog
- [x] `[Medium]` Build folder move flow
- [x] `[Medium]` Build folder default label management
- [x] `[Easy]` Add archive filters

### 1.15 Labels UI
- [x] `[Medium]` Build labels management page
- [x] `[Medium]` Build label create and edit dialog
- [x] `[Easy]` Add color picker for labels

### 1.16 Entries UI
- [x] `[Hard]` Build entries list grouped by date
- [x] `[Medium]` Build manual entry dialog
- [x] `[Medium]` Build edit entry dialog
- [x] `[Medium]` Add filters for folder, label, and date
- [x] `[Easy]` Add continue action on previous entries
- [x] `[Medium]` Add pagination or infinite scroll

### 1.17 Basic Personal Reporting
- [x] `[Medium]` Add dashboard stats for today and this week
- [x] `[Medium]` Add this month total
- [x] `[Medium]` Add simple breakdown by folder
- [x] `[Medium]` Add simple breakdown by label

### 1.18 Non-Goals for the Web MVP
- [x] `[Easy]` Do not build offline mode for the web app
- [x] `[Easy]` Do not build billing, invoicing, clients, or organization features
- [x] `[Easy]` Do not build team or sharing features

### 1.19 Testing and Deployment
- [x] `[Medium]` Test timer start, pause, resume, stop, and discard flows
- [ ] `[Medium]` Test hierarchy edge cases
  - Nested folder creation
  - Moving folders
  - Deleting folders and moving contents to `Inbox`
  - Applying inherited folder labels from ancestors
- [x] `[Medium]` Test auth and user provisioning flow
- [x] `[Easy]` Test Google login end-to-end
- [ ] `[Medium]` Test date and timezone handling
- [x] `[Easy]` Fix TypeScript and lint errors
- [x] `[Easy]` Test responsive layouts
- [x] `[Medium]` Add error boundaries
- [ ] `[Easy]` Deploy web app and Convex backend

---

## Phase 2: iOS App Core

**Goal**: Reuse the same backend and timer model in a native iPhone app.

### 2.1 Native App Foundation
- [x] `[Easy]` Create the SwiftUI iOS project in `apps/apple`
- [x] `[Easy]` Mirror the domain vocabulary from the web app
- [x] `[Medium]` Connect the app to Convex
- [x] `[Medium]` Implement the same Auth0 auth flow for iOS

### 2.2 iOS Core Features
- [x] `[Hard]` Build timer screen with start, pause, resume, and stop
- [x] `[Medium]` Build folder browsing
- [x] `[Medium]` Build labels support
- [x] `[Medium]` Build entries list and manual entry creation
- [x] `[Medium]` Verify real-time sync with the web app

---

## Phase 3: macOS App and Apple Automation

**Goal**: Extend the same model to desktop Apple workflows without backend redesign.

### 3.1 macOS App
- [ ] `[Medium]` Add a macOS target
- [ ] `[Medium]` Adapt navigation and layouts for macOS
- [ ] `[Medium]` Reuse the same timer, entry, and organization model

### 3.2 Automation and Widgets
- [ ] `[Medium]` Add App Intents for start, pause, resume, and stop
- [x] `[Medium]` Add widgets for current timer and filtered time summaries
  - Compact current running timer widget
  - Horizontal Day, Week, or Month chart
  - Configurable folder and label filters
- [ ] `[Hard]` Add Focus mode integration after the base app is stable

---

## Phase 4: Reporting, Export, and Refinement

**Goal**: Improve long-term usefulness for personal tracking.

### 4.1 Reporting
- [ ] `[Medium]` Add better daily, weekly, and monthly reporting views
- [ ] `[Medium]` Add richer folder and label breakdowns

### 4.2 Export
- [ ] `[Medium]` Add CSV export
- [ ] `[Easy]` Add JSON export
- [ ] `[Easy]` Skip PDF unless it becomes genuinely useful

### 4.3 Quality
- [ ] `[Medium]` Improve accessibility
- [ ] `[Medium]` Improve performance for large entry histories
- [ ] `[Medium]` Add observability and error tracking

---

## Open Product Decisions
- [x] Timers can start with an empty title
- [x] There is no separate project model; folders are the only hierarchy type
- [x] Deleting a folder moves contents to `Inbox`
- [ ] Decide whether archived folders should still appear in filters by default
- [x] Default labels from parent folders cascade into child folders

---

## Success Checklist

### Web MVP
- [x] Authentication works reliably
- [x] Google login works reliably
- [x] Multiple active timers run independently on one shared second boundary
- [x] Timer start, pause, resume, and stop work correctly
- [x] Folders, sub-folders, and labels can be managed cleanly
- [x] Inherited folder labels are applied correctly to timers
- [x] Entries can be created manually and edited later
- [x] The app is good enough for daily personal use

### Foundation
- [x] No organization model exists anywhere in the schema or UI
- [x] The backend schema can be reused for iOS and macOS
- [x] The web app does not require major backend redesign before native apps begin

---

**Last Updated**: July 11, 2026
**Status**: Web MVP accepted and ready to release. Next: production deployment, then Phase 2 iOS development.
