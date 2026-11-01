/// Whether timeline videos and GIFs play by themselves (Settings; on by default, as Twitter's timeline loops GIFs and
/// plays videos muted). Accessibility's Auto-Play Video Previews still wins.
package enum MediaAutoplay {
    package static let settingKey = "autoplaysMedia"
    package static let defaultValue = true
}
