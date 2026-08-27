import SwiftUI

/// How the log presents its history: the row list, or the month grid. The
/// grid exists for a daily practice whose list has grown to years — a way to
/// see and reach a month without scrolling through every row above it.
private enum LogDisplayMode: String {
    case list
    case calendar
}

struct MeditationLogView: View {
    let sections: [MonthSection]
    let practicedDays: [DailyTotal]
    let warnsAboutUnreadableEntries: Bool
    let onSave: (MeditationRecord) -> Void
    let onAdd: (Date, Int) -> Void
    let onDelete: (UUID) -> Void
    let healthKitAvailable: Bool
    let healthKitEnabled: Bool
    let onHealthKitChanged: (Bool) -> Void
    let onAbout: () -> Void

    @State private var editor: LogEditorPresentation?
    /// Months outside the current year start collapsed; this set holds the ones
    /// the user has opened. Collapsing is what keeps a multi-year log bounded.
    @State private var expandedMonths: Set<String> = []
    @AppStorage("logDisplayMode") private var displayModeRaw = LogDisplayMode.list.rawValue
    @Environment(\.isCompactHeight) private var isCompactHeight
    @Environment(\.calendar) private var calendar

    private var displayMode: LogDisplayMode {
        LogDisplayMode(rawValue: displayModeRaw) ?? .list
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenHeader(title: "Meditation\nlog")

                    Text("Open a session to adjust its details or leave a private note.")
                        .font(.system(VTLayout.subtitleStyle(compact: isCompactHeight)))
                        .foregroundStyle(VTPalette.muted)
                        .padding(.top, isCompactHeight ? 8 : 12)

                    if warnsAboutUnreadableEntries {
                        Label(
                            "Some damaged history entries could not be read; valid sessions are still shown.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(VTPalette.accent)
                        .padding(.top, 16)
                    }

                    if healthKitAvailable {
                        Toggle(
                            "Log to Apple Health",
                            isOn: Binding(get: { healthKitEnabled }, set: onHealthKitChanged)
                        )
                        .toggleStyle(VTSwitchStyle())
                        .frame(minHeight: 56)
                        .padding(.top, 18)
                        .overlay(alignment: .top) { hairline }
                        .overlay(alignment: .bottom) { hairline }
                    }

                    if sections.isEmpty {
                        Text("Your first completed sitting will appear here. Sessions stay on this device.")
                            .font(.vtSerif(.title3))
                            .foregroundStyle(VTPalette.patina)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else if displayMode == .calendar {
                        calendarBody(proxy: proxy)
                    } else {
                        listBody
                    }
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 108)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            MobileTopBar(eyebrow: "PRACTICE") {
                HStack(spacing: 4) {
                    if !sections.isEmpty {
                        displayModeButton
                    }
                    addButton
                    AboutButton(action: onAbout)
                }
            }
        }
        .ganzfeldField(.log)
        .navigationTitle("Meditation Log")
        .sheet(item: $editor) { presentation in
            LogEditorView(
                presentation: presentation,
                onSave: { endedAt, minutes, note in
                    switch presentation {
                    case .new:
                        onAdd(endedAt, minutes)
                    case let .existing(record):
                        onSave(record.applyingEdit(endedAt: endedAt, minutes: minutes, note: note))
                    }
                    editor = nil
                },
                onDelete: {
                    if case let .existing(record) = presentation {
                        onDelete(record.id)
                    }
                    editor = nil
                },
                onCancel: { editor = nil }
            )
        }
    }

    // MARK: - List mode

    /// Whether a section's rows are visible. The current calendar year stays
    /// open; older months open only when asked, which is what keeps a log of
    /// years from being one endless scroll.
    private func isExpanded(_ section: MonthSection) -> Bool {
        calendar.component(.year, from: section.monthStart) ==
            calendar.component(.year, from: Date())
            || expandedMonths.contains(section.id)
    }

    private var listBody: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(sections) { section in
                sectionHeader(section)
                    .id(section.id)

                if isExpanded(section) {
                    ForEach(section.records) { record in
                        recordRow(record)
                            .id(record.id)
                    }
                }
            }
        }
    }

    /// The month eyebrow with the month's sitting time across from it — a
    /// description of that month, in the list's own caption voice; nothing
    /// cumulative, nothing to keep up. Older months use the whole header as
    /// the expand control rather than growing a chevron.
    private func sectionHeader(_ section: MonthSection) -> some View {
        let currentYear = calendar.component(.year, from: section.monthStart) ==
            calendar.component(.year, from: Date())
        return Button {
            guard !currentYear else { return }
            if expandedMonths.contains(section.id) {
                expandedMonths.remove(section.id)
            } else {
                expandedMonths.insert(section.id)
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(section.title.uppercased())
                    .font(.caption2)
                    .tracking(2.4)
                    .foregroundStyle(VTPalette.patina)
                Spacer()
                Text(DurationFormatter.concise(section.totalDuration))
                    .font(.caption)
                    .foregroundStyle(VTPalette.patina)
            }
            .padding(.top, 26)
            .padding(.bottom, 6)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isExpanded(section) { hairline }
            }
        }
        .buttonStyle(.plain)
        .disabled(currentYear)
        .accessibilityLabel("\(section.title), \(DurationFormatter.concise(section.totalDuration)) of practice")
        .accessibilityHint(currentYear ? "" : (isExpanded(section) ? "Collapses this month" : "Shows this month's sessions"))
    }

    // MARK: - Calendar mode

    private var displayModeButton: some View {
        VTCircleButton(
            systemImage: displayMode == .calendar ? "list.bullet" : "calendar",
            label: displayMode == .calendar ? "Show the list" : "Show the calendar"
        ) {
            displayModeRaw = (displayMode == .calendar ? LogDisplayMode.list : .calendar).rawValue
        }
    }

    /// The months as seven-column grids. A day either holds a dot or it does
    /// not — no counts, no chains, nothing that could be read as a streak.
    /// Tapping a practiced day returns to the list, opened to that day.
    private func calendarBody(proxy: ScrollViewProxy) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(sections) { section in
                let grid = LogPresentation.monthGrid(
                    for: section.monthStart,
                    totals: practicedDays,
                    calendar: calendar
                )

                HStack(alignment: .firstTextBaseline) {
                    Text(section.title.uppercased())
                        .font(.caption2)
                        .tracking(2.4)
                        .foregroundStyle(VTPalette.patina)
                    Spacer()
                    Text(DurationFormatter.concise(section.totalDuration))
                        .font(.caption)
                        .foregroundStyle(VTPalette.patina)
                }
                .padding(.top, 26)
                .padding(.bottom, 10)

                monthGridView(grid, section: section, proxy: proxy)
            }
        }
    }

    private func monthGridView(_ grid: MonthGrid, section: MonthSection, proxy: ScrollViewProxy) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 10) {
            // Weekday initials repeat (two Ts, two Ss), so identity comes from
            // the position, not the letter.
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(VTPalette.patina)
                    .accessibilityHidden(true)
            }
            ForEach(0..<grid.leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: 24)
            }
            ForEach(grid.days) { day in
                Button {
                    jumpToDay(day, section: section, proxy: proxy)
                } label: {
                    VStack(spacing: 4) {
                        Text("\(day.dayNumber)")
                            .font(.caption2)
                            .foregroundStyle(VTPalette.muted)
                        Circle()
                            .fill(day.practiced ? VTPalette.patina : .clear)
                            .frame(width: 3, height: 3)
                    }
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!day.practiced)
                .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                .accessibilityValue(day.practiced ? "Practiced" : "")
                .accessibilityHint(day.practiced ? "Shows this day in the list" : "")
            }
        }
    }

    /// One-letter weekday headers, rotated to the calendar's first weekday.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Back to the list, scrolled to the first sitting of the tapped day. The
    /// section is scrolled first and the row on the next runloop: rows inside
    /// a collapsed or unmaterialized LazyVStack have no geometry to land on yet.
    private func jumpToDay(_ day: MonthGrid.Day, section: MonthSection, proxy: ScrollViewProxy) {
        guard let record = section.records.last(where: {
            calendar.isDate($0.endedAt, inSameDayAs: day.date)
        }) ?? section.records.first(where: {
            calendar.isDate($0.endedAt, inSameDayAs: day.date)
        }) else { return }

        expandedMonths.insert(section.id)
        displayModeRaw = LogDisplayMode.list.rawValue
        // Two hops: the section first, so the lazy stack materializes its rows,
        // then the row itself once it has geometry to land on. The pause is one
        // frame of settling; without it the second scroll silently no-ops.
        DispatchQueue.main.async {
            proxy.scrollTo(section.id, anchor: .top)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(record.id, anchor: .center)
                }
            }
        }
    }

    private var hairline: some View {
        Rectangle().fill(VTPalette.border.opacity(0.5)).frame(height: 1)
    }

    private var addButton: some View {
        VTCircleButton(systemImage: "plus", label: "Add a meditation session") {
            editor = .new
        }
    }

    /// A row, not a card. The date leads in light serif and the duration is the
    /// one warm mark, which is what makes the column scannable.
    private func recordRow(_ record: MeditationRecord) -> some View {
        Button {
            editor = .existing(record)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(record.endedAt, format: .dateTime.weekday(.abbreviated).day())
                        .font(.vtSerif(.title3))
                        .foregroundStyle(VTPalette.text)
                    HStack(spacing: 6) {
                        Text(record.endedAt, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundStyle(VTPalette.patina)
                        // The quietest mark the app has — the bottom bar's route
                        // dot — saying only that a note exists. Never its text.
                        // Contract amendment v1.1 in practice-log-and-notes.md.
                        if record.note?.isEmpty == false {
                            Circle()
                                .fill(VTPalette.patina)
                                .frame(width: 3, height: 3)
                                .accessibilityHidden(true)
                        }
                    }
                }
                Spacer()
                Text(DurationFormatter.concise(record.creditedDuration))
                    .font(.body)
                    .foregroundStyle(VTPalette.accent)
            }
            .frame(minHeight: 62)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { hairline }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Edit this session")
        .accessibilityValue(record.note?.isEmpty == false ? "Has a note" : "")
    }
}

private enum LogEditorPresentation: Identifiable {
    case new
    case existing(MeditationRecord)

    var id: String {
        switch self {
        case .new: "new"
        case let .existing(record): record.id.uuidString
        }
    }
}

/// The editor wears the same dress as every other screen: the field behind it,
/// a serif title, hairline rows. It used to be a stock grouped `Form` — the one
/// surface in the app that painted its own background and ignored an explicit
/// Dawn or Night choice (a sheet is its own presentation host, so the root's
/// `preferredColorScheme` does not reach it; compare `AboutView`).
private struct LogEditorView: View {
    let presentation: LogEditorPresentation
    let onSave: (Date, Int, String?) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @AppStorage("appearance") private var appearanceRaw = VTAppearance.system.rawValue
    @State private var endedAt: Date
    @State private var durationMinutes: Int
    @State private var note: String
    @State private var confirmsDeletion = false

    private var appearance: VTAppearance {
        VTAppearance(rawValue: appearanceRaw) ?? .system
    }

    private var isNew: Bool {
        if case .new = presentation { return true }
        return false
    }

    init(
        presentation: LogEditorPresentation,
        onSave: @escaping (Date, Int, String?) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.presentation = presentation
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        switch presentation {
        case .new:
            _endedAt = State(initialValue: Date())
            _durationMinutes = State(initialValue: 60)
            _note = State(initialValue: "")
        case let .existing(record):
            _endedAt = State(initialValue: record.endedAt)
            _durationMinutes = State(initialValue: max(1, Int(record.creditedDuration / 60)))
            _note = State(initialValue: record.note ?? "")
        }
    }

    // No NavigationStack: the sheet has no navigation and no toolbar — the only
    // chrome is the Cancel word beside the title, which keeps the field clean.
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 16) {
                        ScreenHeader(title: isNew ? "Add\nsession" : "Edit\nsession")
                        Button("Cancel", action: onCancel)
                            .buttonStyle(.plain)
                            .font(.body)
                            .foregroundStyle(VTPalette.patina)
                            .padding(.top, 10)
                    }

                    endedRow
                        .padding(.top, 30)
                    durationRow

                    if case .existing = presentation {
                        noteSection
                            .padding(.top, 30)
                    }

                    saveButton
                        .padding(.top, 36)

                    if case .existing = presentation {
                        deleteButton
                            .padding(.top, 20)
                    }
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 18)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
            .ganzfeldField(.idle)
            .confirmationDialog(
                "Delete this session?",
                isPresented: $confirmsDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete Session", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            }
        // A sheet is its own presentation host: the override applied at the root
        // does not descend into it, so it is applied again here, as AboutView does.
        .preferredColorScheme(appearance.colorScheme)
        // Full height only. The medium detent truncated the form under the
        // keyboard exactly when someone was writing a note.
        .presentationDetents([.large])
    }

    private var hairline: some View {
        Rectangle().fill(VTPalette.border.opacity(0.5)).frame(height: 1)
    }

    /// The compact system picker is accepted furniture — a custom date control
    /// buys nothing — but it sits on a hairline row like everything else.
    private var endedRow: some View {
        HStack(spacing: 16) {
            Text("Ended")
                .font(.body)
                .foregroundStyle(VTPalette.text)
            Spacer(minLength: 12)
            DatePicker("", selection: $endedAt)
                .labelsHidden()
                .tint(VTPalette.accent)
        }
        .frame(minHeight: 60)
        .overlay(alignment: .bottom) { hairline }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ended")
    }

    /// The stepper, in the chrome's own shape: the numeral between two hairline
    /// circles, the same control the top bar is made of.
    private var durationRow: some View {
        HStack(spacing: 16) {
            Text("Duration")
                .font(.body)
                .foregroundStyle(VTPalette.text)
            Spacer(minLength: 12)
            HStack(spacing: 14) {
                VTCircleButton(systemImage: "minus", label: "Shorter") {
                    durationMinutes = max(1, durationMinutes - 1)
                }
                Text("\(durationMinutes) min")
                    .font(.vtSerif(.title3))
                    .monospacedDigit()
                    .foregroundStyle(VTPalette.text)
                    .frame(minWidth: 74)
                VTCircleButton(systemImage: "plus", label: "Longer") {
                    durationMinutes = min(1_440, durationMinutes + 1)
                }
            }
        }
        .frame(minHeight: 64)
        .overlay(alignment: .bottom) { hairline }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Duration")
        .accessibilityValue("\(durationMinutes) minutes")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: durationMinutes = min(1_440, durationMinutes + 1)
            case .decrement: durationMinutes = max(1, durationMinutes - 1)
            @unknown default: break
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NOTE")
                .font(.caption2)
                .tracking(2.4)
                .foregroundStyle(VTPalette.patina)

            TextEditor(text: $note)
                .scrollContentBackground(.hidden)
                .font(.body)
                .foregroundStyle(VTPalette.text)
                .frame(minHeight: 110)
                .padding(.bottom, 6)
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Stays on this device.")
                            .font(.body)
                            .foregroundStyle(VTPalette.patina)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .overlay(alignment: .bottom) { hairline }
                .accessibilityLabel("Private session note")
        }
    }

    private var saveButton: some View {
        Button("Save") {
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            onSave(endedAt, durationMinutes, trimmedNote.isEmpty ? nil : trimmedNote)
        }
        .buttonStyle(VTPrimaryButtonStyle())
        .frame(maxWidth: .infinity)
    }

    /// The word carries the weight; the dialog does the confirming.
    private var deleteButton: some View {
        Button("Delete this session") {
            confirmsDeletion = true
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(VTPalette.patina)
        .frame(maxWidth: .infinity)
    }
}
