# Privacy Policy for Brick & Brew

Last updated: 22 September 2026

Brick & Brew is a private crew app for friends training for a triathlon. It is not a public social network.

## Who we are

Brick & Brew is provided by the app developer who invited you to TestFlight. Contact them through App Store Connect / TestFlight if you have questions about this policy.

## Data we collect

- **Account.** Sign in with Apple gives us an opaque user identifier and, if you share it, your name. We store a display name you choose, and an optional profile photo, so teammates can recognize you on the leaderboard.
- **Crew membership.** Invite code and team name so you can share one private board.
- **Training.** When you connect Strava, we read your activity summaries (sport, start time, distance, moving time, elevation, average and max heart rate). We do not request permission to post to Strava and we do not download heart-rate streams.
- **Beers.** Counts, timestamps, optional notes, and optional photos you take with the camera. Teammates on your crew can see those photos on the crew board.
- **Location (optional).** If you turn on Nearby pint in the Me tab, the app reads your location on this iPhone to mark home and work (so we do not ping you on the couch) and to ask Apple Maps whether you are lingering at a bar, brewery, or restaurant between 6:00 pm and 2:00 am. Location is never stored in CloudKit, never shown to teammates, and never used for ads or tracking. Turn the toggle off or clear home/work at any time.
- **Technical.** Tokens needed to talk to Strava are stored in the iOS Keychain on your device. Crew records are stored in Apple CloudKit.
- **Waitlist.** If you join from the website, we store the email you submit so we can send a TestFlight invite. We do not use it for a newsletter or ads.

## Why we collect it

Account, training, beers, and crew data are used only to sign you in, sync your own training, let you log beers, and show the crew leaderboard (including optional profile photos and pint photos). Location is used only to decide whether to ask you to log a pint. We do not sell data, run ads, or use the data for tracking across other companies' apps or websites.

## Where it is stored

- Strava access and refresh tokens: on-device Keychain.
- Optional home and work pins, Nearby pint on/off, and the last local pint-ping day: on this iPhone (UserDefaults). They are deleted when you sign out, delete your account, or clear them in Me.
- Profiles (including optional profile photos), activities, beers (including optional pint photos), and team records: Apple CloudKit (public database, filtered by your crew's invite code). This is a small private-crew design: teammates in the same crew can read the board. It is not bank-level isolation.

The Cloudflare Worker used for Strava OAuth sees a one-time authorization code or a refresh token only to exchange it with Strava. It does not keep a database of athletes.

Waitlist emails are stored in a separate Cloudflare Worker (Cloudflare KV), keyed by a hash of the address, until we send the invite or you ask us to delete it.

## Sharing

We share data with:

- **Apple** (Sign in with Apple, CloudKit, TestFlight, and — if Nearby pint is on — MapKit place lookup and visit delivery).
- **Strava** (when you choose Connect with Strava), under Strava's terms and privacy policy.
- **Cloudflare** (waitlist email storage only).

We do not share your crew board, waitlist, or location with advertisers.

## Retention

Disconnect Strava in the Me tab to delete tokens from the Keychain and clear the Strava athlete id on your profile. Sign out removes the local session only, including home/work pins and Nearby pint settings.

To delete your account, open the Me tab and choose **Delete account**. That removes your CloudKit profile (including your photo), activities, beers, and pint photos from the crew board, clears on-device location pins, and signs you out. The crew itself stays for teammates. Deletion is immediate.

To leave the waitlist, email the developer listed on the App Store Connect record for Brick & Brew and we will delete that address.

## Your choices

- Skip Strava and only log beers.
- Skip a profile photo; the board shows your initials.
- Skip a pint photo; you can still log beers without the camera.
- Leave Nearby pint off; the app never reads location.
- Turn Nearby pint off later; background location stops.
- Skip or clear home and work pins.
- Disconnect Strava at any time.
- Sign out at any time.
- Delete your account at any time from the Me tab.

## Children

The app is intended for adults on a private TestFlight crew. It is not directed at children under 13.

## Changes

We will update this page if the data we collect or how we use it changes.

## Contact

Open a TestFlight feedback ticket or email the developer listed on the App Store Connect record for Brick & Brew.
