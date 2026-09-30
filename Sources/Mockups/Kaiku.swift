import SwiftUI
import PartitiUI

/// A level meter made of rounded segments, for the microphone and the call audio.
struct LevelMeter: View {
    let level: Double
    var segments = 22
    @Environment(\.colorScheme) private var scheme
    @Environment(\.puiAccent) private var accent

    var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                let on = Double(i) / Double(segments) < level
                Capsule()
                    .fill(on ? (Double(i) / Double(segments) > 0.8 ? ink.orange : ink.green) : ink.strongFill)
                    .frame(width: 4, height: 10)
            }
        }
    }
}

struct KaikuPopover: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        let accent = AppAccent.kaiku
        PopoverScaffold {
            PopoverHeader(icon: Assets.icon(.kaiku), name: "Kaiku") {
                GlassCircleButton("folder") {}
            }
        } content: {
            // Recording
            Card(tint: accent.color, padding: PUI.Popover.cardPadding) {
                VStack(alignment: .leading, spacing: PUI.Space.l) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: PUI.Space.xxs) {
                            HStack(spacing: PUI.Space.s) {
                                Circle().fill(accent.color).frame(width: 7, height: 7)
                                    .shadow(color: accent.color.opacity(0.6), radius: 3)
                                Text("Recording").font(PUI.Font.label).foregroundStyle(accent.legible(scheme))
                            }
                            Text("Design review with Marta").font(PUI.Font.headline).foregroundStyle(ink.primary)
                            HStack(spacing: PUI.Space.xs) {
                                Image(systemName: "video.fill").font(.system(size: 9))
                                Text("Zoom").font(PUI.Font.caption)
                            }
                            .foregroundStyle(ink.secondary)
                        }
                        Spacer()
                        BigNumber("4:12").padding(.top, -3)
                    }
                    VStack(spacing: PUI.Space.s) {
                        meterRow("mic.fill", "Microphone", 0.55, ink)
                        meterRow("speaker.wave.2.fill", "Call audio", 0.72, ink)
                    }
                    PopUpField("MacBook Pro Microphone", symbol: "mic")
                    HStack(spacing: PUI.Space.m) {
                        Button {} label: { Label("Pause", systemImage: "pause.fill").labelStyle(TightLabelStyle(spacing: PUI.Space.s)) }
                            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                        Button {} label: { Label("Bookmark", systemImage: "bookmark.fill").labelStyle(TightLabelStyle(spacing: PUI.Space.s)) }
                            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                    }
                    VStack(spacing: 0) {
                        bookmark("1:37", "Pricing for the team plan", ink, placeholder: false)
                        Hairline(leading: 24)
                        bookmark("3:05", "Add a note", ink, placeholder: true)
                    }
                    Button {} label: {
                        Label("Stop Recording", systemImage: "stop.fill").labelStyle(TightLabelStyle(spacing: PUI.Space.s))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            // Recent
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.xs) {
                    SectionHeader("Recent") { Text("4 calls") }
                    recent("text.bubble", "Weekly sync", "Today, 9:30 · 28 min", ink, copy: true)
                    recent("waveform", "Onboarding with Luca", "Yesterday · 42 min", ink, status: "Transcribing")
                    recent("text.bubble", "Interview, backend role", "Monday · 55 min", ink, copy: true)
                    recent("text.bubble", "Supplier call", "Friday · 17 min", ink, copy: true)
                }
            }
            Card(padding: PUI.Space.m + 2) {
                HStack(spacing: PUI.Space.m) {
                    RowSymbol("mic.slash")
                    Text("Mute all microphones").font(PUI.Font.body).foregroundStyle(ink.primary)
                    Spacer()
                    Toggle("", isOn: .constant(false)).toggleStyle(PUISwitchStyle(mini: true)).labelsHidden()
                }
                .padding(.horizontal, PUI.Space.xxs)
            }
        } footer: {
            SampleFooter.make([.init("Recordings", symbol: "list.bullet.rectangle") {}])
        }
    }

    private func meterRow(_ symbol: String, _ title: String, _ level: Double, _ ink: Ink) -> some View {
        HStack(spacing: PUI.Space.m) {
            RowSymbol(symbol)
            Text(title).font(PUI.Font.callout).foregroundStyle(ink.primary)
            Spacer()
            LevelMeter(level: level)
        }
        .frame(height: 16)
    }

    private func bookmark(_ time: String, _ note: String, _ ink: Ink, placeholder: Bool) -> some View {
        HStack(spacing: PUI.Space.m) {
            Image(systemName: "bookmark.fill").font(.system(size: 10)).foregroundStyle(AppAccent.kaiku.legible(scheme)).frame(width: 16)
            Text(time).font(PUI.Font.callout).monospacedDigit().foregroundStyle(ink.secondary).frame(width: 30, alignment: .leading)
            Text(note).font(PUI.Font.callout).foregroundStyle(placeholder ? ink.tertiary : ink.primary).lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: PUI.Control.small + 2)
    }

    private func recent(_ symbol: String, _ title: String, _ detail: String, _ ink: Ink, copy: Bool = false, status: String? = nil) -> some View {
        HStack(spacing: PUI.Space.m) {
            RowSymbol(symbol, color: status == nil ? ink.secondary : AppAccent.kaiku.legible(scheme))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(PUI.Font.body).foregroundStyle(ink.primary).lineLimit(1)
                Text(detail).font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
            }
            Spacer(minLength: PUI.Space.m)
            if let status {
                HStack(spacing: PUI.Space.xs) {
                    ProgressDots()
                    Text(status).font(PUI.Font.caption)
                }
                .foregroundStyle(ink.secondary)
            } else if copy {
                Image(systemName: "doc.on.doc").font(.system(size: 11, weight: .medium)).foregroundStyle(ink.tertiary)
                    .frame(width: 22, height: 22)
            }
        }
        .frame(height: 34)
    }
}

/// Three dots standing in for the spinner in snapshots.
struct ProgressDots: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(Ink(scheme).secondary.opacity(1 - Double(i) * 0.3)).frame(width: 3, height: 3)
            }
        }
    }
}

// MARK: - Settings: Transcription

struct KaikuTranscriptionPane: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        SettingsPane {
            PaneHeader("Transcription", subtitle: "Who turns your calls into text, and with which model.",
                       symbol: "text.quote", color: .blue)
        } content: {
            SettingsGroup("Provider", footer: "Your microphone and the call audio are transcribed separately, so the transcript knows who said what.") {
                provider("whisper.cpp", "Private and free. Runs on this Mac.", "desktopcomputer", .gray, "Ready", ink.green, true, ink)
                provider("ElevenLabs Scribe", "Scribe, with speaker detection.", "waveform", .indigo, "Needs an API key", ink.tertiary, false, ink)
                provider("OpenAI", "gpt-4o-transcribe and Whisper.", "sparkles", .teal, "Needs an API key", ink.tertiary, false, ink)
                provider("Groq", "Very fast Whisper in the cloud.", "bolt.fill", .orange, "Needs an API key", ink.tertiary, false, ink)
            }
            SettingsGroup("Model") {
                model("Small", "466 MB", "Good balance", ink, state: .download)
                model("Large v3 Turbo compact", "547 MB", "Great quality, fast", ink, state: .inUse, recommended: true)
                model("Large v3 Turbo", "1.6 GB", "Best quality", ink, state: .use)
            }
        }
    }

    enum ModelState { case download, use, inUse }

    private func provider(_ name: String, _ tagline: String, _ symbol: String, _ color: Color,
                          _ status: String, _ statusColor: Color, _ selected: Bool, _ ink: Ink) -> some View {
        HStack(spacing: PUI.Space.m + 2) {
            IconTile(symbol, color: color, size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(PUI.Font.body).foregroundStyle(ink.primary)
                Text(tagline).font(PUI.Font.caption).foregroundStyle(ink.secondary)
            }
            Spacer()
            HStack(spacing: PUI.Space.xs) {
                Circle().fill(statusColor).frame(width: 6, height: 6)
                Text(status).font(PUI.Font.caption).foregroundStyle(ink.secondary)
            }
            CheckMark(selected)
                .padding(.leading, PUI.Space.m)
        }
        .padding(.horizontal, PUI.Space.l)
        .frame(height: 44)
    }

    private func model(_ name: String, _ size: String, _ note: String, _ ink: Ink, state: ModelState, recommended: Bool = false) -> some View {
        HStack(spacing: PUI.Space.m) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: PUI.Space.s) {
                    Text(name).font(PUI.Font.body).foregroundStyle(ink.primary)
                    if recommended { Badge("Recommended") }
                }
                Text("\(size) · \(note)").font(PUI.Font.caption).foregroundStyle(ink.secondary)
            }
            Spacer()
            switch state {
            case .download:
                Button {} label: { Label("Download", systemImage: "arrow.down.circle").labelStyle(TightLabelStyle()) }
                    .buttonStyle(SecondaryButtonStyle(height: PUI.Control.small))
            case .use:
                Button("Use") {}.buttonStyle(SecondaryButtonStyle(height: PUI.Control.small))
            case .inUse:
                HStack(spacing: PUI.Space.xs) {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                    Text("In Use").font(PUI.Font.callout.weight(.medium))
                }
                .foregroundStyle(AppAccent.kaiku.legible(scheme))
            }
        }
        .padding(.horizontal, PUI.Space.l)
        .frame(height: 42)
    }
}

enum KaikuSettings {
    static let sections: [SidebarSection] = [
        SidebarSection(nil, [
            SidebarItem("General", symbol: "gearshape.fill", style: .tile(.gray)),
            SidebarItem("Shortcuts", symbol: "keyboard.fill", style: .tile(.indigo)),
            SidebarItem("Recording", symbol: "mic.fill", style: .tile(AppAccent.kaiku.color)),
            SidebarItem("Sources", symbol: "dot.radiowaves.left.and.right", style: .tile(.teal)),
            SidebarItem("Transcription", symbol: "text.quote", style: .tile(.blue)),
            SidebarItem("Webhook", symbol: "paperplane.fill", style: .tile(.purple)),
            SidebarItem("Permissions", symbol: "lock.shield.fill", style: .tile(.green)),
            SidebarItem("About", symbol: "info", style: .tile(.teal))
        ])
    ]
}
