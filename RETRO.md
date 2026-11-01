# Retro build

This worktree starts at upstream `1fc31b4`. It restores artwork and SwiftUI chrome from `0e9f97d`, before upstream removed the skeuomorphic design in `d552a67`.

The current reducers, API client, database, text handling, media playback and column navigation remain in place. This is a UI port, not a rollback to the old app.

## Local changes

- iOS 27.0 deployment targets, with availability checks around newer APIs.
- Original silver bar artwork and a dark horizontal bottom tab bar using the original icons. Compose stays in the top navigation bar.
- Original feed and search switchers, Follow, poll and pill buttons, gap groove, letterpress, and the bird debossed at the end of timelines and threads, as on Twitter for iPad.
- "Tweet your reply" as a white field pressed into the detail action bar's shelf, instead of glass.
- Laid out for a normal iPhone. iPhone Duo's vertical bar, fold-aware layouts and leading title alignment need iOS 27.1/27.2, so they are dropped or behind availability checks. `ClassicSidebar` is kept but unused.
- Rounded-square avatars (including the profile header's ring and the profile preview), bitmap action icons, gold favorite stars and corner dog-ears.
- A standard media overlay instead of the fold-aware arrangement.
- Settings in the old grouped style: the column stack's hatched backdrop, bordered white groups, letterpressed headers, blue values, iOS 5-style ON/OFF switches, the silver bar and a blue Done button (`ClassicForm.swift`, applied with `.formStyle(.classicGrouped)`).
- Settings → Display and Sound → Appearance: a System / Light / Dark segmented control, switching with a short crossfade (instant with Reduce Motion).
- The bottom bar calls the current tab actions. Reselecting a tab still returns to its root or scrolls it to the top. Holding Compose opens a menu with Drafts. The Notifications tab keeps its unread badge.

## Features beyond upstream

- No view counts: they arrived with X in late 2022, after the classic era. A Tweet's date line reads "21.14 · 31 Oct 2026 · Twitter for iPhone" (views still show in the iPad-only wide timeline, which the retro build doesn't use).
- Settings → Tweets: exact counts (12,345 instead of 12.3K), and source labels ("· Twitter for iPhone" in a Tweet's date line, matching its other dot separators; on by default). The source comes from X's `source` field; the mock Tweets say Twitter for iPhone.
- Settings → Ask First: confirm before liking, following or unfollowing, and sending a Tweet.
- Settings → Privacy: Lock Twitter asks for Face ID or the passcode on launch and on return from the background. Without a passcode set it can't lock, so it doesn't.
- After "Show more replies", the loaded replies stay joined to the conversation's thread line (an upstream bug, fixed in its own commit).
- Tweetie 2-style pull-to-refresh: the striped arrow and "Pull down to refresh…", flipping to "Release to refresh…" while still holding past the catch, then "Loading…" with "Last Updated" underneath. Pulling back below the catch resets the arrow. Only the arrow animates, and Reduce Motion disables the flip animation. The system refresh control still owns the request and haptics; its spinner is hidden only inside classic feeds, leaving Lists and user lists alone. The arrow and psst catch sound share an 80pt threshold, an approximation because UIKit doesn't expose its arm distance. Arrow, colors and layout come from EGOTableViewPullRefresh (MIT, see THIRD_PARTY_NOTICES.md); dark colors are ours. The psst/pop sounds come from Twitter for iPad, so this is a period-inspired blend rather than an exact Tweetie 2 reproduction.
- Settings → Notifications → New Notifications: asks for permission when turned on, then checks X in the background (an iOS background refresh, earliest 15 minutes after leaving the app; iOS decides when). New ones arrive as local notifications with their own text ("Becky Hansmeyer followed you"), or one summary for more than three, and the app icon shows the unread count. X doesn't push to third-party apps, so they can be late. `Twitter-Info.plist` adds the background mode and task ID to the generated Info.plist. Debug builds can run a check with `--check-notifications-in <seconds>`. Tapping a notification opens the Notifications tab, whether the app was in the background or closed; alerts that land while the app is open still show and go to Notification Center.
- Search suggests accounts as you type (after a 0.25 s pause, using the existing typeahead endpoint), under a "Search for …" row. Hashtags and already-searched queries aren't looked up.

The feed uses the full available phone width. The system tab bar is hidden and its reserved space given back, so content sits directly on the classic tab bar. The tab bar's background extends under the home indicator, while its buttons stay in the safe area.

Still system: sign-in. On iPhone, links open in Safari's view, so the iPad web panel is unchanged.

## Classic interaction pass

- Composer and Drafts: a silver bar with Cancel and a blue Tweet button, and a plain numeric countdown instead of the circular gauge. On iPhone both cover the whole screen with square edges, as the old modal composer did, instead of iOS's rounded floating sheet; the iPad keeps a form sheet. Media, threads and today's character limit are unchanged.
- Cancelling a Tweet with text asks with the same classic sheet: a red Delete Draft, Save Draft, and Cancel to keep writing.
- Favorites: visible Like/Likes wording, held actions and accessibility labels say Favorite/Favorites to match the gold star. The X API calls are unchanged.
- Classic Back button: a silver bezel instead of glass. The native edge swipe still works, including cancelled and repeated swipes.
- Retweet / Quote Tweet: an iPhone OS 3 `UIActionSheet` (`ClassicActionSheet.swift`): the page dims, a blue-grey tray rises with white glossy Retweet (or Undo Retweet) and Quote Tweet buttons, and a dark Cancel set apart. Pressed buttons turn the old selection blue. Tapping outside, Cancel, Escape and the VoiceOver escape gesture all dismiss it. The chosen action runs after the sheet is gone, so Quote Tweet can open the composer. Reduce Motion fades instead of sliding.
- Lists and user lists share the timeline's arrow-and-text refresh header.
- Timeline videos and GIFs autoplay muted by default (upstream had it off), as Twitter's timeline loops GIFs. Settings → Media turns it off, and iOS's Auto-Play Video Previews setting still wins. With it off, tiles show a classic white-ringed play button instead of glass. Installs that already saved the switch as off keep it off.
- Media viewer in the old Photos and movie-player style: a black translucent bar with a glossy Done, "2 of 3" and the classic share glyph, and the Tweet in the same black strip along the bottom. Video gets the old player's smoked, rounded control panel with a blue-filled scrubber and glossy knob, moved down to the thumb as one row (play/pause, times, sound) without a volume slider. A paused video shows the classic play badge. Swipe-down dismissal, zoom transitions, pinch zoom, alt text and VoiceOver (the scrubber is a standard slider to VoiceOver) are unchanged.
- Swipe left on a Tweet for a dark, Tweetie-style tray: Reply, Retweet, Favorite, Bookmark, Share and Close. Swiping right closes it. Every action is still available from the visible action bar.

The look stays Tweetie / Twitter 4.x. Tweetbot is a reference for interaction (muting, timeline behavior), not a second visual theme.

Larger feature gaps include direct messages, multi-account switching and saved searches distinct from recent searches. The client currently has no DM endpoints or saved-search operations, and the session model has one shared viewer. Those need backend/session work, not decorative tabs. Bookmarks, quote cards, threaded composition and private likes are intentional modern departures; don't remove them for visual fidelity alone.

Checks: all package tests (except snapshots) and all 11 simulator UI tests pass, including the swipe tray → Retweet sheet → Quote composer flow, composer and Drafts, the Back button with edge swipes, and Lists refresh. Screenshots of the sheet, composer and Drafts were checked on an iPhone 11 simulator. Refresh tests don't prove exact UIKit trigger alignment, loading timing on a real network, VoiceOver or device haptics.

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
