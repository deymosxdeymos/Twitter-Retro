# Twitter Retro

A slopfork of [Sam Henri Gold's Twitter client](https://github.com/samhenrigold/Twitter), reskinned to feel like Tweetie 2 and Twitter for iPhone circa 2010–2012: silver bars, glossy buttons, gold stars, the striped pull-to-refresh arrow, slate action sheets, and so on. It keeps the modern stuff that's actually useful: X's API, bookmarks, quote tweets, threads, alt text and media autoplay.

"Slopfork" because most of it was written by AI coding agents with me steering and squinting at simulator screenshots. It's mainly for my own phone, but feel free to try it. There's no support, no roadmap and no promises, and it will break when X changes things.

Lives on [GitHub](https://github.com/deymosxdeymos/Twitter-Retro) and [Tangled](https://tangled.org/@deymos.dev/Twitter-Retro), kept in step: pushes from a laptop go to both, and a GitHub Action mirrors anything else (cloud agents, merges on github.com) to Tangled.

**What's different from upstream, how to build it, and what's been checked:** see [RETRO.md](RETRO.md).

## Credits

- **[Sam Henri Gold](https://github.com/samhenrigold)** wrote the app this is built on: the SwiftUI/TCA client, the X API work, the column navigation and the original skeuomorphic artwork this fork brings back. All of the hard parts are his. Go star [his repo](https://github.com/samhenrigold/Twitter).
- **[NeoFreeBird](https://github.com/NeoFreeBird/app)** was a source of ideas for which old-Twitter features and touches were worth bringing back. No code or assets are taken from it.
- **[GlassX](https://github.com/R44VC0RP/glassx/)** for the sign-in approach Sam's client uses.
- **[EGOTableViewPullRefresh](https://github.com/enormego/EGOTableViewPullRefresh)** (MIT) for the pull-to-refresh arrow and layout. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- Loren Brichter's **Tweetie**, the original Twitter for iPhone, and **Tweetbot** for the design and interaction references. Nothing here is affiliated with them, with X, or with Twitter.

Same warning as upstream: using an unofficial client can get your account in trouble. Don't ship this to TestFlight or the App Store. Install it on your own device, at your own risk.

---

## Original README (upstream)

I don't like that they're making me use this poo from a butt:

<img width="675" height="1200" alt="image" src="https://github.com/user-attachments/assets/72b214b3-a60c-4dd1-8927-75cbe748a335" />

So I'm making my own like it's 2012 babyyyyyyyy. Except with SwiftUI and TCA and it uses the auth trick from [GlassX](https://github.com/R44VC0RP/glassx/)

it should go without saying but this super shouldn’t go to TestFlight let alone the App Store, it’ll very likely get rejected or get your users accounts in trouble. this is just for you to mess around with locally. 
