# Brick & Brew

iPhone app for a private triathlon crew: Sign in with Apple, sync swim / bike / run from Strava, log beers, and rank everyone on one board.

**Total Index** = swim km × 10 + run km × 3 + bike km × 1 + beers × 2.

There is no paid backend. CloudKit holds the crew board. A free Cloudflare Worker exists only so the Strava client secret never ships in the iOS app.

## Architecture

```
Views → ViewModels → Services → CloudKit / Strava / Keychain
```

- Identity: Sign in with Apple (Strava is a data source, not the account).
- Shared data: CloudKit public database, always filtered by `teamId`.
- Tokens: Keychain (`AfterFirstUnlockThisDeviceOnly`).
- Leaderboards: computed on-device from CloudKit records. Each phone syncs **its own** Strava activities, so teammates do not share one API quota.

## Repo layout

| Path | What |
| --- | --- |
| `BrickAndBrew/` | SwiftUI app (iOS 18+) |
| `BrickAndBrewTests/` | Scoring, Strava mapping, season-window tests |
| `worker/strava-oauth/` | Cloudflare Worker (`POST /token`, `POST /refresh`) |
| `docs/` | Marketing site + privacy policy (GitHub Pages) |

## One-time setup

Do these in a browser before a device/TestFlight build. Simulator can compile without them; CloudKit and Strava will not work until they are done.

### 1. Apple Developer

1. Register App ID `com.brickandbrew.app`.
2. Enable **Sign in with Apple** and **CloudKit**.
3. Create container `iCloud.com.brickandbrew.app`.
4. In Xcode: select your team on the BrickAndBrew target. Capabilities are already in `BrickAndBrew.entitlements`.
5. Create an App Store Connect app (iOS, bundle id `com.brickandbrew.app`) for TestFlight.

### 2. CloudKit indexes (Development dashboard)

After the first run on a signed-in device, open [CloudKit Dashboard](https://icloud.developer.apple.com/) → container `iCloud.com.brickandbrew.app` → Schema and mark these fields **Queryable** (and deploy schema to Production before TestFlight):

- `Profile`: `appleUserId`, `teamId`
- `Activity`: `teamId`, `userId`, `startDate`
- `Beer`: `teamId`, `userId`, `loggedAt`
- `Team`: `inviteCode`

Record types: `Team`, `Profile`, `Activity`, `Beer`.

### 3. Strava API application

1. Create an app at [strava.com/settings/api](https://www.strava.com/settings/api).
2. Authorization Callback Domain: `localhost` (the app uses `brickandbrew://localhost/oauth`).
3. Privacy policy URL: your GitHub Pages URL for `docs/` (see below).
4. Put the **Client ID** into `BrickAndBrew/Info.plist` key `STRAVA_CLIENT_ID`. Never put the Client Secret in the app.

### 4. Cloudflare Worker (free)

```bash
cd worker/strava-oauth
npx wrangler login
npx wrangler secret put STRAVA_CLIENT_ID
npx wrangler secret put STRAVA_CLIENT_SECRET
npx wrangler deploy
```

Copy the `*.workers.dev` URL into `BrickAndBrew/Info.plist` key `STRAVA_OAUTH_WORKER_URL` (no trailing path). The app calls `/token` and `/refresh` on that host.

### 5. Privacy policy URL

The public site is GitHub Pages from the `docs/` folder:

- Home: `https://torresmanu.github.io/BrickAndBrew/`
- Privacy (Strava + App Store Connect): `https://torresmanu.github.io/BrickAndBrew/privacy.html`

## Scoring

Weights live in `Scoring` so you can tweak them in one file:

- Swim: 10 points / km
- Run: 3 points / km
- Bike: 1 point / km
- Beer: 2 points each

Season start is the date the crew is created. Activities and beers before that date do not score.

## Local build

```bash
brew install xcodegen   # already used to generate the project
xcodegen generate
open BrickAndBrew.xcodeproj
```

Pick your Development Team, then run on a physical iPhone signed into iCloud. CloudKit public DB and Sign in with Apple are unreliable in Simulator.

Unit tests (no Apple/Strava accounts required):

```bash
xcodebuild -scheme BrickAndBrew -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## TestFlight checklist

- [ ] Development Team selected; bundle id `com.brickandbrew.app`
- [ ] CloudKit schema deployed to **Production**
- [ ] Sign in with Apple enabled on the App ID
- [ ] `STRAVA_CLIENT_ID` and `STRAVA_OAUTH_WORKER_URL` are real values, not placeholders
- [ ] Worker secrets set; `/token` smoke-tested
- [ ] Privacy policy live; App Privacy filled in App Store Connect (fitness, health/heart rate from Strava, name, user id — not used for tracking)
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption` is already `false`
- [ ] Archive → Distribute App → TestFlight
- [ ] External testers: add review notes that login is Sign in with Apple, Strava is optional, and beers are logged in-app
- [ ] Share one invite code with the crew (4–20 letters/numbers). First person to use a new code creates the crew.

## What v1 does not include

Push notifications, beer photos, multiple crews, Android, HealthKit, Strava webhooks, chat.
