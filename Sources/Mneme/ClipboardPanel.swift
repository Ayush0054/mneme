import SwiftUI

struct ClipboardPanel: View {
    @Bindable var model: ClipboardModel
    var height: CGFloat = BookTheme.height

    private var count: Int { model.section == .queue ? model.queue.count : model.history.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            navigation
                .padding(.horizontal, BookTheme.inset).padding(.bottom, 18)
            if model.section == .settings {
                BookSettingsPanel(model: model)
            } else {
                clipboardContent
            }
            Spacer(minLength: 0)
            footer
        }
        .font(BookFonts.sans())
        .foregroundStyle(BookTheme.ink)
        .frame(width: BookTheme.width, height: height)
        .background { BookBackdrop() }
        .tint(BookTheme.accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        if model.section != .settings {
                            MnemeMark(height: 34)
                                .frame(width: 42, height: 48)
                                .bookGlass(radius: 10, tint: BookTheme.brass.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(BookTheme.brass.opacity(0.32), lineWidth: 0.5))
                                .accessibilityHidden(true)
                        }
                        Text(model.section == .settings ? "Preferences" : "Mneme")
                            .font(BookFonts.serif(model.section == .settings ? 46 : 56)).tracking(-0.8)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(model.section == .settings ? "Make Mneme work your way." : "Your clipboard, kept in order.")
                        .font(BookFonts.serif(19, italic: true)).foregroundStyle(BookTheme.muted)
                }
                Spacer(minLength: 12)
                if model.section != .settings {
                    VStack(alignment: .trailing, spacing: -5) {
                        Text(String(count)).font(BookFonts.serif(72)).tracking(-2)
                        Text(model.section == .queue ? "IN QUEUE" : "IN HISTORY")
                            .font(BookFonts.sans(9, weight: .medium)).tracking(1.5)
                            .foregroundStyle(BookTheme.muted)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.horizontal, BookTheme.inset).padding(.top, 18).padding(.bottom, 22)
    }

    private var navigation: some View {
        HStack(spacing: 3) {
            ForEach(PanelSection.allCases, id: \.self) { section in
                Button { model.section = section } label: {
                    Text(section.rawValue)
                    .font(BookFonts.sans(12, weight: model.section == section ? .semibold : .medium))
                    .foregroundStyle(model.section == section ? BookTheme.paper : BookTheme.muted)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background {
                        if model.section == section {
                            RoundedRectangle(cornerRadius: 8).fill(BookTheme.ink)
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(section.rawValue)
                .accessibilityAddTraits(model.section == section ? .isSelected : [])
            }
        }
        .padding(4).bookGlass(radius: 12)
    }

    private var clipboardContent: some View {
        VStack(spacing: 12) {
            if !model.unavailableShortcuts.isEmpty {
                notice("A shortcut is unavailable.", icon: "keyboard", action: "Change") { model.section = .settings }
            }
            if !model.accessibilityEnabled {
                notice("Allow Accessibility to paste into apps.", icon: "hand.raised", action: "Enable") {
                    model.grantAccessibility()
                }
            }
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(BookTheme.muted)
                TextField("Find a copied item…", text: $model.search)
                    .font(BookFonts.sans(12)).textFieldStyle(.plain)
                    .accessibilityLabel("Find a copied item")
                if !model.search.isEmpty {
                    Button { model.search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(BookTheme.muted).accessibilityLabel("Clear search")
                }
            }
            .padding(11).bookGlass(radius: 9)

            if model.section == .queue {
                HStack {
                    Toggle("Collect copies", isOn: $model.isCollecting)
                        .font(BookFonts.sans(11)).toggleStyle(.switch).controlSize(.mini)
                        .help("Append each new copy to the queue in copy order")
                    Spacer()
                    Button("Clear queue") { model.clearQueue() }
                        .font(BookFonts.sans(11)).buttonStyle(.borderless).disabled(model.queue.isEmpty)
                }
                HStack(spacing: 10) {
                    Button { model.smartPaste(fromPanel: true) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles").font(.system(size: 12))
                            Text("Smart Paste")
                            Spacer(minLength: 3)
                            BookKey(text: model.shortcuts.smart.label)
                        }
                    }
                    .buttonStyle(BookButtonStyle(prominent: true))
                    .disabled(model.isBusy || (model.queue.isEmpty && model.history.isEmpty))
                    .help("Choose the copied item that matches the focused field")
                    Button { model.pasteNext(fromPanel: true) } label: {
                        HStack(spacing: 6) {
                            Text("Paste next")
                            Spacer(minLength: 3)
                            BookKey(text: model.shortcuts.next.label)
                        }
                    }
                    .buttonStyle(BookButtonStyle()).disabled(model.queue.isEmpty || model.isBusy)
                    .help("Paste the first queued item, regardless of field")
                }
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !model.suggestions.isEmpty {
                        HStack {
                            Label("Choose for \(model.targetLabel)", systemImage: "sparkles")
                                .font(BookFonts.sans(11, weight: .medium)).lineLimit(1)
                            Spacer()
                            Button("Dismiss") { model.suggestions.removeAll() }
                                .font(BookFonts.sans(11)).buttonStyle(.borderless)
                        }
                        .padding(.vertical, 12)
                        ForEach(model.suggestions) { clip in
                            ClipRow(clip: clip, number: nil, isQueue: false, model: model)
                        }
                        BookRule().padding(.vertical, 10)
                    }
                    if model.visibleClips.isEmpty {
                        emptyState
                    } else {
                        ForEach(model.visibleClips) { clip in
                            ClipRow(clip: clip, number: rowNumber(clip),
                                    isQueue: model.section == .queue, model: model)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
            if model.lastSent != nil && model.section == .queue {
                Button { model.restoreLast() } label: {
                    Label("Return last sent item to queue", systemImage: "arrow.uturn.backward")
                }
                .font(BookFonts.sans(11)).buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, BookTheme.inset)
    }

    private func rowNumber(_ clip: Clip) -> Int? {
        guard model.section == .queue else { return nil }
        return model.queue.firstIndex(where: { $0.id == clip.id }).map { $0 + 1 }
    }

    private func notice(_ text: String, icon: String, action: String, perform: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text).font(BookFonts.sans(11))
            Spacer(minLength: 4)
            Button(action, action: perform).font(BookFonts.sans(11, weight: .medium)).buttonStyle(.borderless)
        }
        .padding(10).background(BookTheme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(model.search.isEmpty ? "A blank page." : "Nothing on this page.")
                .font(BookFonts.serif(32))
            Text(model.search.isEmpty
                 ? "Copy a name, a link, a line worth keeping.\nIt will be waiting here."
                 : "Try another word or source app.")
                .font(BookFonts.sans(12)).lineSpacing(4)
                .foregroundStyle(BookTheme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 30)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            BookRule()
            HStack(alignment: .top, spacing: 8) {
                if model.isBusy { ProgressView().controlSize(.small) }
                Text(model.status).font(BookFonts.sans(11)).foregroundStyle(BookTheme.muted).lineLimit(3)
                Spacer(minLength: 0)
                if model.isBusy {
                    Button("Cancel") { model.cancelPending(); model.status = "Cancelled. Nothing will be pasted." }
                        .font(BookFonts.sans(11)).buttonStyle(.borderless)
                }
            }
            HStack(spacing: 6) {
                Circle().fill(model.isPaused ? Color.orange : BookTheme.accent).frame(width: 4, height: 4)
                Text(model.isPaused ? "Capture paused" : "Capturing locally")
                Spacer()
                BookKey(text: model.shortcuts.smart.label)
                Text("Smart Paste")
                Button { NSApplication.shared.terminate(nil) } label: {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BookTheme.ink)
                        .frame(width: 28, height: 28)
                        .bookGlass(radius: 8, tint: BookTheme.accent.opacity(0.12), interactive: true)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
                .help("Quit Mneme")
                .accessibilityLabel("Quit Mneme")
            }
            .font(BookFonts.sans(10)).foregroundStyle(BookTheme.muted)
        }
        .padding(.horizontal, BookTheme.inset).padding(.bottom, 16).padding(.top, 12)
    }
}

private struct ClipRow: View {
    let clip: Clip
    let number: Int?
    let isQueue: Bool
    @Bindable var model: ClipboardModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Group {
                    if let number {
                        Text(String(number)).font(BookFonts.serif(43)).tracking(-1)
                    } else {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 18, weight: .light)).padding(.top, 6)
                    }
                }
                .foregroundStyle(BookTheme.muted)
                .frame(width: 45, alignment: .leading).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 9) {
                    Text(clip.preview).font(BookFonts.sans(13)).lineSpacing(3)
                        .lineLimit(3).frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 6) {
                        Text(clip.source)
                            .font(BookFonts.sans(9, weight: .medium)).tracking(0.5)
                            .foregroundStyle(BookTheme.muted).lineLimit(1)
                        Spacer(minLength: 2)
                        if isQueue {
                            Button { model.move(clip, by: -1) } label: { Image(systemName: "arrow.up").frame(width: 22, height: 24) }
                                .disabled(number == 1 || model.isBusy).help("Move earlier").accessibilityLabel("Move earlier")
                            Button { model.move(clip, by: 1) } label: { Image(systemName: "arrow.down").frame(width: 22, height: 24) }
                                .disabled(number == model.queue.count || model.isBusy).help("Move later").accessibilityLabel("Move later")
                        } else if !isSuggestion {
                            Button { model.enqueue(clip) } label: { Image(systemName: "plus").frame(width: 22, height: 24) }
                                .help("Add to queue").accessibilityLabel("Add to queue")
                        }
                        Button("Copy") { model.copy(clip) }.frame(minHeight: 24)
                        Button("Paste") { model.paste(clip) }.frame(minHeight: 24).disabled(model.isBusy)
                        if !isSuggestion {
                            Button { model.remove(clip) } label: { Image(systemName: "xmark").frame(width: 22, height: 24) }
                                .help("Remove item").accessibilityLabel("Remove item")
                        }
                    }
                    .buttonStyle(.borderless).font(BookFonts.sans(10, weight: .medium))
                }
                .padding(.top, 5)
            }
            .padding(.vertical, 14)
            BookRule()
        }
    }

    private var isSuggestion: Bool { model.suggestions.contains(where: { $0.id == clip.id }) }
}
