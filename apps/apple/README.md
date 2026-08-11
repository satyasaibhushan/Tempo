# Tempo for Apple Platforms

Native development includes SwiftUI iPhone and macOS applications plus the
shared `TempoCore` package. The core mirrors the production Convex domain model
and keeps timer behavior independent from presentation code.

## Current foundation

- Swift 6 package targeting iOS 17+ and macOS 14+
- Sendable, Codable models aligned with the Convex schema
- Whole-second timer calculations shared across every active timer
- Stable names for the existing Convex queries and mutations
- Official Convex Swift client with live query subscriptions
- Auth0 Universal Login with cached Keychain credentials
- Reproducible Xcode project generated from `project.yml`
- Native timer dashboard with multiple synchronized timers
- Native macOS app with a desktop sidebar and the shared Now, Log, Folders,
  Labels, and Setup workflows
- Terra-styled navigation matching the web app across Now, Log, Folders,
  Labels, and Setup
- Full timer composer with notes, folder selection, and labels
- Searchable entry history with Day, Week, Month, folder, and label filters
- Manual entry creation plus edit, continue, and delete actions
- Nested folder management with parent moves, default labels, and archiving
- Label creation, editing, color selection, usage counts, and deletion
- Compact current-timer widget with a system-rendered live clock
- Configurable horizontal summary widget with Day, Week, or Month range
- Matching iPhone and macOS widget extensions backed by one shared snapshot
- Dynamic folder and label filters backed by the shared app snapshot
- Unit tests for shared timer behavior

Run the core tests:

```bash
cd apps/apple
swift test
```

Create the Apple Silicon release archive used by GitHub Releases:

```bash
CONVEX_URL=https://your-deployment.convex.cloud \
  zsh apps/apple/Scripts/package-macos.sh /tmp/Tempo.zip
```

Pushing a `v*` tag builds an ad-hoc-signed `Tempo.zip` release asset. Developer
ID signing and notarization remain a separate distribution step. The release
workflow reads `CONVEX_URL` from the repository's GitHub Actions variables and
fails before building when it is missing or invalid.

Generate and open the Apple project:

```bash
xcodegen generate
open Tempo.xcodeproj
```

Local Xcode builds read `CONVEX_URL` from the repository root's `.env.local`;
CI and release builds may provide it through the build environment. A final
build phase validates and embeds the value into both Apple app bundles, so an
installed app never depends on Xcode's launch environment. Active timers,
recent entries, folders, and labels update through live subscriptions; all
native management actions call the existing Convex mutations. Synced data is
also published to the widget App Group.

## Auth0 native application

The Apple apps use a separate Auth0 **Native** application. The web application
is a confidential client and its secret must never be embedded in a native app.

Configure the Native application with all four of these values:

```text
Allowed Callback URLs:
fun.bhushan.tempo://dev-2eahmbvpb8dc1wei.jp.auth0.com/ios/fun.bhushan.tempo/callback
fun.bhushan.tempo://dev-2eahmbvpb8dc1wei.jp.auth0.com/macos/fun.bhushan.tempo/callback

Allowed Logout URLs:
fun.bhushan.tempo://dev-2eahmbvpb8dc1wei.jp.auth0.com/ios/fun.bhushan.tempo/callback
fun.bhushan.tempo://dev-2eahmbvpb8dc1wei.jp.auth0.com/macos/fun.bhushan.tempo/callback
```

Then:

1. Put its public Client ID in `Sources/TempoApp/Auth0.plist`.
2. Add `AUTH0_NATIVE_CLIENT_ID` with the same value to every Convex environment
   used by an Apple build, including development and production.
3. Deploy the Convex auth configuration to each environment.

No Auth0 client secret belongs in either native target.

Interactive native sign-in uses a private authentication session and asks which
account to use. Choose the same Auth0 identity as the web app to see the same
timers and entries.

## Widgets

The apps and widget extensions share data through the
`group.fun.bhushan.tempo` App Group. Add that App Group capability to the
`Tempo`, `TempoMac`, `TempoWidgets`, and `TempoMacWidgets` identifiers in the
Apple Developer portal before a device or release build. Simulator SDK builds
work without signing.

The summary widget is configured from the Home Screen or desktop widget editor. Its
folder and label choices come from the latest shared snapshot, so the Convex
adapter only needs to publish the user's current entries and filter options.

## Environment rules

- Never commit Auth0 secrets or tokens.
- Never hardcode a Convex deployment URL; provide `CONVEX_URL` through the
  runtime or build environment.
- Pin official Swift packages through `Package.resolved`.
- Use a public Auth0 Native client ID; never use the web client secret.
- Production points to the same Convex deployment as the released web app.
