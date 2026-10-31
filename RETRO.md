# Retro build

This worktree starts at upstream `1fc31b4`. It restores artwork and SwiftUI chrome from `0e9f97d`, before upstream removed the skeuomorphic design in `d552a67`.

The current reducers, API client, database, text handling, media playback and column navigation remain in place. This is a UI port, not a rollback to the old app.

## Local changes

- iOS 27.0 deployment targets, with availability checks around newer APIs.
- Original silver bar artwork and a dark horizontal bottom tab bar using the original icons. Compose stays in the top navigation bar.
- Original feed and search switchers, Follow, poll and pill buttons, gap groove, letterpress and debossed end-of-timeline fleuron.
- "Tweet your reply" as a white field pressed into the detail action bar's shelf, instead of glass.
- Laid out for a normal iPhone. iPhone Duo's vertical bar, fold-aware layouts and leading title alignment need iOS 27.1/27.2, so they are dropped or behind availability checks. `ClassicSidebar` is kept but unused.
- Rounded-square avatars (including the profile header's ring and the profile preview), bitmap action icons, gold favorite stars and corner dog-ears.
- A standard media overlay instead of the fold-aware arrangement.
- Settings in the old grouped style: the column stack's hatched backdrop, bordered white groups, letterpressed headers, blue values, iOS 5-style ON/OFF switches, the silver bar and a blue Done button (`ClassicForm.swift`, applied with `.formStyle(.classicGrouped)`).
- Settings → Display and Sound → Appearance: a System / Light / Dark segmented control, switching with a short crossfade (instant with Reduce Motion).
- The bottom bar calls the current tab actions. Reselecting a tab still returns to its root or scrolls it to the top. Holding Compose opens a menu with Drafts. The Notifications tab keeps its unread badge.

## Features beyond upstream

- Search suggests accounts as you type (after a 0.25 s pause, using the existing typeahead endpoint), under a "Search for …" row. Hashtags and already-searched queries aren't looked up.

The feed uses the full available phone width. The system tab bar is hidden and its reserved space given back, so content sits directly on the classic tab bar. The tab bar's background extends under the home indicator, while its buttons stay in the safe area.

Still system glass: the back button (as in the original retro build), the Retweet / Quote Tweet popover, media overlays, compose and sign-in. On iPhone, links open in Safari's view, so the iPad web panel is unchanged.

## Build

Requires Xcode 27.2 / Swift 6.4. The SDK can be newer than the app's minimum iOS version.

```sh
./scripts/build-retro-ipa.sh
```

Output: `build/Twitter-Retro-iPhone-iOS27.0.ipa`. The script builds without signing and checks the IPA archive. AltStore Classic signs it during installation. Build output is in `build/retro-build.log`.

The bundle identifier is unchanged. Installing through the same AltStore setup should update the existing app rather than create a second one. Back up anything important first; installation and data retention have not been verified.

## Upstream updates

Keep the retro work as local commits before updating. Fetch upstream, inspect the changes, then merge `origin/main` into `retro-with-upstream`. Resolve presentation conflicts in favor of the retro UI without reverting reducer or client fixes. Rebuild and test after each merge. Do not merge unattended: upstream changes to navigation or the deployment target may need another compatibility pass.

## Checks on a phone

Compilation and IPA checks do not verify the layout. Before treating a build as finished, check:

- Bottom tabs, selected icons, unread badges and reselect-to-top.
- Compose, held Compose → Drafts, reply and thread navigation.
- Silver headers and feed switching without clipped controls.
- Like, Retweet, bookmark and share, including held actions.
- Photos, paging, zoom, caption controls and video playback.
- Notch/home-indicator clearance, rotation, dark mode, large text and Reduce Motion.

## Simulator

Xcode 27 replaces Simulator.app with DeviceHub (`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`). Debug builds can skip sign-in with canned data:

```sh
xcrun simctl launch <device> gold.samhenri.Twitter --mock-twitter --mock-media
```

Add `--tab profile`, `--open-thread` or `--search <query>` to open a specific screen.

Unofficial X authentication carries the account risk described in the upstream README.
