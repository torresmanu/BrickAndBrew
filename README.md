# Brick & Brew

iPhone app for a private triathlon crew: Sign in with Apple, sync swim / bike / run from Strava, log beers, and rank everyone on one board.

**Total Index** = training + beers × 12 − grind tax. Each beer covers 20 training points; uncovered swim / bike / run is stripped and taxed at 25%.

There is no paid backend. CloudKit holds the crew board. Cloudflare Workers cover Strava OAuth (so the client secret never ships in the iOS app) and the public waitlist.

## Architecture

```
Views → ViewModels → Services → CloudKit / Strava / Keychain
```

- Identity: Sign in with Apple (Strava is a data source, not the account).
- Shared data: CloudKit public database, always filtered by `teamId`.
- Tokens: Keychain (`AfterFirstUnlockThisDeviceOnly`).
- Nearby pint: on-device visit monitoring + MapKit. Home/work pins stay in UserDefaults; they never go to CloudKit.
- Leaderboards: computed on-device from CloudKit records. Each phone syncs **its own** Strava activities, so teammates do not share one API quota.

## Repo layout

| Path | What |
| --- | --- |
| `BrickAndBrew/` | SwiftUI app (iOS 18+) |
| `BrickAndBrewTests/` | Scoring, Strava mapping, season-window tests |
| `worker/strava-oauth/` | Cloudflare Worker (`POST /token`, `POST /refresh`) |
| `worker/waitlist/` | Cloudflare Worker (`POST /waitlist`) + KV |
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
- `BeerPhoto`: `teamId`, `userId`, `beerId`, `loggedAt` (also mark `loggedAt` **Sortable**)
- `Team`: `inviteCode`

Record types: `Team`, `Profile`, `Activity`, `Beer`, `BeerPhoto`. `Profile.avatar` and `BeerPhoto.photo` are optional Assets (not queryable). They appear after the first photo save. Scoring queries never download `BeerPhoto`.

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

### 5. Waitlist worker (free)

The marketing site posts to this worker instead of linking to a download.

```bash
cd worker/waitlist
npx wrangler kv namespace create WAITLIST
```

Paste the returned id into `worker/waitlist/wrangler.toml`, then:

```bash
npx wrangler deploy
```

The homepage form already points at `https://brickandbrew-waitlist.brickandbrew.workers.dev/waitlist`. To read signups:

```bash
npx wrangler kv key list --binding WAITLIST --prefix email: --remote
npx wrangler kv key get --binding WAITLIST "<key>" --remote
```

### 6. Privacy policy URL

The public site is GitHub Pages from the `docs/` folder:

- Home: `https://torresmanu.github.io/BrickAndBrew/`
- Privacy (Strava + App Store Connect): `https://torresmanu.github.io/BrickAndBrew/privacy.html`

## Scoring

Weights live in `Scoring` so you can tweak them in one file.

Sport boards (swim / bike / run / beers) still rank raw volume:

- Swim: 10 points / km
- Run: 3 points / km
- Bike: 1 point / km
- Beer: 12 points each

The overall **Total Index** is the pub rule, not a sum of those boards:

1. Add training the same way as the sport boards.
2. Add beers at 12 points each.
3. Each beer covers 20 training points at full value.
4. Uncovered training is removed from the Index, then taxed another 25% (grind tax). Train past your pints and the number drops — even below zero.

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
- [ ] Privacy policy live; App Privacy filled in App Store Connect (fitness, health/heart rate from Strava, name, user id, photos/camera, **precise and coarse location** for optional Nearby pint — not used for tracking, not linked for tracking, purpose App Functionality)
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption` is already `false`
- [ ] Archive → Distribute App → TestFlight
- [ ] External testers / App Review notes: login is Sign in with Apple; Strava is optional; beers are logged in-app; Nearby pint is opt-in in Me → grant **Always** and **Precise Location** → optionally set home/work. Background location is only used to notice lingering at a bar, brewery, or restaurant between 6:00 pm and 2:00 am. Location never leaves the device except Apple Maps POI lookup. App Review cannot simulate a `CLVisit`; the toggle, permission prompts, and home/work pins are the reviewable surface.
- [ ] Share one invite code with the crew (4–20 letters/numbers). First person to use a new code creates the crew.

## What v1 does not include

Remote push notifications, multiple crews, Android, HealthKit, Strava webhooks, chat. Local pint reminders and the optional Nearby pint ping are in.
