# Privacy Policy for Brick & Brew

Last updated: 16 September 2026

Brick & Brew is a private crew app for friends training for a triathlon. It is not a public social network.

## Who we are

Brick & Brew is provided by the app developer who invited you to TestFlight. Contact them through App Store Connect / TestFlight if you have questions about this policy.

## Data we collect

- **Account.** Sign in with Apple gives us an opaque user identifier and, if you share it, your name. We store a display name you choose so teammates can recognize you on the leaderboard.
- **Crew membership.** Invite code and team name so you can share one private board.
- **Training.** When you connect Strava, we read your activity summaries (sport, start time, distance, moving time, elevation, average and max heart rate). We do not request permission to post to Strava and we do not download heart-rate streams.
- **Beers.** Counts, timestamps, and optional notes you enter in the app.
- **Technical.** Tokens needed to talk to Strava are stored in the iOS Keychain on your device. Crew records are stored in Apple CloudKit.

## Why we collect it

All of the above is used only to sign you in, sync your own training, let you log beers, and show the crew leaderboard. We do not sell data, run ads, or use the data for tracking across other companies' apps or websites.

## Where it is stored

- Strava access and refresh tokens: on-device Keychain.
- Profiles, activities, beers, and team records: Apple CloudKit (public database, filtered by your crew's invite code). This is a small private-crew design: teammates in the same crew can read the board. It is not bank-level isolation.

The Cloudflare Worker used for Strava OAuth sees a one-time authorization code or a refresh token only to exchange it with Strava. It does not keep a database of athletes.

## Sharing

We share data with:

- **Apple** (Sign in with Apple, CloudKit, TestFlight).
- **Strava** (when you choose Connect with Strava), under Strava's terms and privacy policy.

We do not share your crew board with advertisers.

## Retention

You can disconnect Strava in the Me tab, which deletes tokens from the Keychain and clears the Strava athlete id on your profile. Training already written to the crew board stays unless the crew owner asks the developer to delete records. Sign out removes the local session. To delete your CloudKit profile and logs, email the developer from the Apple ID you used to sign in.

## Your choices

- Skip Strava and only log beers.
- Disconnect Strava at any time.
- Sign out at any time.
- Delete the app. Local tokens are removed with the app; CloudKit records remain until you request deletion.

## Children

The app is intended for adults on a private TestFlight crew. It is not directed at children under 13.

## Changes

We will update this page if the data we collect or how we use it changes.

## Contact

Open a TestFlight feedback ticket or email the developer listed on the App Store Connect record for Brick & Brew.
