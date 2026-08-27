import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearanceRaw = VTAppearance.system.rawValue

    private var appearance: VTAppearance {
        VTAppearance(rawValue: appearanceRaw) ?? .system
    }

    private let repositoryURL = URL(string: "https://github.com/ajrnair/VipassanaTimerApple")!
    /// The published page rather than the Markdown behind it: tapping this in the app should
    /// open the policy, not a file browser showing the policy's source.
    private let privacyURL = URL(
        string: "https://ajrnair.github.io/VipassanaTimerApple/privacy.html"
    )!
    private let licenseURL = URL(
        string: "https://github.com/ajrnair/VipassanaTimerApple/blob/main/LICENSE"
    )!
    private let acknowledgementsURL = URL(
        string: "https://github.com/ajrnair/VipassanaTimerApple/blob/main/ASSET_LICENSES.md"
    )!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    appearanceChoice
                    introduction
                    privacyPromise
                    openSource
                    independence
                    version
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity)
            }
            .ganzfeldField(.idle)
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        #if os(macOS)
        .frame(minWidth: 540, minHeight: 600)
        #endif
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            GongMark(size: 42)

            Text("QUIET PRACTICE")
                .font(.caption.weight(.medium))
                .tracking(2.2)
                .foregroundStyle(VTPalette.accent)

            Text("Private by\ndesign.")
                .font(.vtSerif(.largeTitle))
                .foregroundStyle(VTPalette.text)

            Text("A free, open-source practice timer with no account, scores, streaks, advertising, analytics, or tracking.")
                .font(.body)
                .foregroundStyle(VTPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Night and Dawn are one language at two times of day, so this is a choice
    /// of field rather than a choice of theme. Automatic is the default and
    /// simply follows the system.
    private var appearanceChoice: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("APPEARANCE", systemImage: "circle.lefthalf.filled")
                .font(.caption2)
                .tracking(2)
                .foregroundStyle(VTPalette.patina)

            HStack(spacing: 24) {
                ForEach(VTAppearance.allCases) { option in
                    VTUnderlinedChoice(title: option.title, isSelected: appearance == option) {
                        appearanceRaw = option.rawValue
                    }
                }
            }

            Text(appearance.caption)
                .font(.subheadline)
                .foregroundStyle(VTPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .animation(nil, value: appearanceRaw)
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle().fill(VTPalette.border.opacity(0.5)).frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
    }

    private var privacyPromise: some View {
        informationCard(title: "YOUR PRACTICE STAYS YOURS", systemImage: "hand.raised") {
            Text("Your practice data is not collected by us. The timer works offline, and timer state, history, and private notes remain in app-owned storage on your devices.")

            Text("Apple Health is optional, off by default, and write-only when you choose to record completed sittings as Mindful Minutes.")

            linkRow("Read the full privacy policy", systemImage: "doc.text", destination: privacyURL)
        }
    }

    private var openSource: some View {
        informationCard(title: "FREE & OPEN SOURCE", systemImage: "chevron.left.forwardslash.chevron.right") {
            Text("The source code is public under the MIT License, so the app’s privacy promises and behavior can be inspected and improved by anyone.")

            Text("The bundled bell and voice recordings have their own terms and are not licensed for reuse under the MIT License.")

            linkRow("View the source code", systemImage: "arrow.up.right", destination: repositoryURL)
            linkRow("Read the MIT License", systemImage: "doc.plaintext", destination: licenseURL)
            linkRow("Audio and asset terms", systemImage: "waveform", destination: acknowledgementsURL)
        }
    }

    private var independence: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INDEPENDENT PRACTICE TOOL")
                .font(.caption2.weight(.semibold))
                .tracking(1.3)
                .foregroundStyle(VTPalette.patina)

            Text("No affiliation with a meditation school, teacher, lineage, or teaching organization is implied.")
                .font(.caption)
                .foregroundStyle(VTPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var version: some View {
        Text("Version \(appVersion) (\(buildNumber))")
            .font(.caption2)
            .foregroundStyle(VTPalette.muted)
            .accessibilityLabel("App version \(appVersion), build \(buildNumber)")
    }

    private func informationCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(VTPalette.patina)

            content()
                .font(.subheadline)
                .foregroundStyle(VTPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            Rectangle().fill(VTPalette.border.opacity(0.5)).frame(height: 1)
        }
    }

    private func linkRow(_ title: String, systemImage: String, destination: URL) -> some View {
        Link(destination: destination) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(VTPalette.text)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityHint("Opens in your browser")
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}
