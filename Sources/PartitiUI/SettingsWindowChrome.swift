import AppKit

public extension NSWindow {
    /// Prepares a window to host `SettingsWindow`: the content runs under a transparent
    /// title bar, and an empty unified toolbar gives the taller title bar of sidebar
    /// windows. That moves the traffic lights down and in, so they sit inside the
    /// sidebar's glass instead of straddling its top edge.
    @MainActor
    func puiConfigureForSettings() {
        styleMask.insert(.fullSizeContentView)
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        titlebarSeparatorStyle = .none
        if toolbar == nil {
            toolbar = NSToolbar()
        }
        toolbarStyle = .unified
    }
}
