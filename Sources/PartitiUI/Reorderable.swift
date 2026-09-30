import SwiftUI

// MARK: - Order logic

/// The order logic behind a list the user arranges: moving one item onto another,
/// and fitting a saved order to the items the app knows today.
public enum Reorder {
    /// `items` with the one at `from` moved into the slot of the one at `to`:
    /// dragged up it lands before the target, dragged down after it, so the first and
    /// last slots are both reachable. Indices out of range leave the order as it is.
    public static func moving<Item>(_ items: [Item], from: Int, to: Int) -> [Item] {
        guard from != to, items.indices.contains(from), items.indices.contains(to) else { return items }
        var result = items
        result.insert(result.remove(at: from), at: to)
        return result
    }

    /// The same move, with locked items keeping their positions: the others reorder
    /// around them. A locked item can't be moved, or be the target of a move.
    public static func moving<Item>(_ items: [Item], from: Int, to: Int, isLocked: (Item) -> Bool) -> [Item] {
        guard from != to, items.indices.contains(from), items.indices.contains(to) else { return items }
        let free = items.indices.filter { !isLocked(items[$0]) }
        guard let a = free.firstIndex(of: from), let b = free.firstIndex(of: to) else { return items }
        var result = items
        for (slot, item) in zip(free, moving(free.map { items[$0] }, from: a, to: b)) {
            result[slot] = item
        }
        return result
    }

    /// Moves the item with `id` into the slot of the item with `target`.
    public static func moving<Item: Identifiable>(_ items: [Item], id: Item.ID, onto target: Item.ID,
                                                  isLocked: (Item) -> Bool = { _ in false }) -> [Item] {
        guard let from = items.firstIndex(where: { $0.id == id }),
              let to = items.firstIndex(where: { $0.id == target }) else { return items }
        return moving(items, from: from, to: to, isLocked: isLocked)
    }

    /// Moves the item with `id` by `offset` places among the items that aren't locked:
    /// -1 is one up, 1 one down. A move past either end stops at that end.
    public static func moving<Item: Identifiable>(_ items: [Item], id: Item.ID, by offset: Int,
                                                  isLocked: (Item) -> Bool = { _ in false }) -> [Item] {
        let free = items.indices.filter { !isLocked(items[$0]) }
        guard let position = free.firstIndex(where: { items[$0].id == id }) else { return items }
        let destination = min(max(position + offset, 0), free.count - 1)
        return moving(items, from: free[position], to: free[destination], isLocked: isLocked)
    }

    /// A saved order fitted to the items the app knows now: saved items that are no longer
    /// known are dropped, duplicates keep their first place, and known items missing from
    /// the saved order are appended in the order of `known`. Items are matched by `key`;
    /// the saved ones are kept as they are, with whatever state they carry.
    public static func normalized<Item, Key: Hashable>(_ saved: [Item], known: [Item], by key: (Item) -> Key) -> [Item] {
        let knownKeys = Set(known.map(key))
        var seen = Set<Key>()
        var result = saved.filter { knownKeys.contains(key($0)) && seen.insert(key($0)).inserted }
        result.append(contentsOf: known.filter { seen.insert(key($0)).inserted })
        return result
    }

    /// A saved order of plain values, such as raw values or ids, fitted to the known ones.
    public static func normalized<Item: Hashable>(_ saved: [Item], known: [Item]) -> [Item] {
        normalized(saved, known: known) { $0 }
    }
}

// MARK: - Rows

extension EnvironmentValues {
    /// Whether the reorderable row a label sits in is switched on.
    @Entry var puiReorderableIsOn: Bool = true
}

/// The standard label of a reorderable row: optional symbol, title, optional subtitle.
/// The symbol takes the accent and the title the primary ink while the row is switched on.
public struct ReorderableLabel: View {
    let title: Text
    var subtitle: Text?
    var symbol: String?
    @Environment(\.puiReorderableIsOn) private var isOn
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    public init(_ title: Text, subtitle: Text? = nil, symbol: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
    }

    /// `title` and `subtitle` are looked up in the app's string catalog.
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, symbol: String? = nil) {
        self.init(Text(title), subtitle: subtitle.map { Text($0) }, symbol: symbol)
    }

    /// `title` and `subtitle` are shown as given.
    @_disfavoredOverload
    public init(_ title: String, subtitle: String? = nil, symbol: String? = nil) {
        self.init(Text(verbatim: title), subtitle: subtitle.map { Text(verbatim: $0) }, symbol: symbol)
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: PUI.Space.m + 2) {
            if let symbol { RowSymbol(symbol, color: isOn ? accent.legible(scheme) : nil) }
            VStack(alignment: .leading, spacing: 1) {
                title.font(PUI.Font.body).foregroundStyle(isOn ? ink.primary : ink.secondary)
                if let subtitle {
                    subtitle.font(PUI.Font.caption).foregroundStyle(ink.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// The rows of a list the user arranges, for a `SettingsGroup` that holds other rows too:
/// each item gets a drag handle, its label and a switch for whether it is shown.
/// Rows reorder by drag and drop, with a line where the dragged row will land, and by
/// Move Up and Move Down from the context menu, VoiceOver actions, or the arrow keys
/// with the handle focused. Locked items show neither handle nor switch and stay in place.
public struct ReorderableRows<Item: Identifiable, Label: View>: View {
    @Binding var items: [Item]
    let isOn: (Item) -> Binding<Bool>
    let isLocked: (Item) -> Bool
    let label: (Item) -> Label
    /// The row being dragged, with the token its drag carries.
    @State private var drag: (id: Item.ID, token: String)?
    /// The row the drag is over.
    @State private var target: Item.ID?
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `isOn` hands the binding to an item's visibility; `isLocked` marks the items
    /// that can't be hidden or moved.
    public init(_ items: Binding<[Item]>,
                isOn: @escaping (Item) -> Binding<Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self._items = items
        self.isOn = isOn
        self.isLocked = isLocked
        self.label = label
    }

    /// `isOn` is the item's own visibility flag, written back into `items`.
    public init(_ items: Binding<[Item]>,
                isOn: WritableKeyPath<Item, Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(items, isOn: { item in
            let id = item.id
            return Binding(
                get: { items.wrappedValue.first { $0.id == id }?[keyPath: isOn] ?? false },
                set: { on in
                    guard let index = items.wrappedValue.firstIndex(where: { $0.id == id }) else { return }
                    items.wrappedValue[index][keyPath: isOn] = on
                })
        }, isLocked: isLocked, label: label)
    }

    public var body: some View {
        ForEach(items) { item in
            if isLocked(item) {
                lockedRow(item)
            } else {
                row(item)
            }
        }
    }

    private func lockedRow(_ item: Item) -> some View {
        HStack(spacing: PUI.Space.m + 2) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Ink(scheme).quaternary)
                .frame(width: 16)
                .accessibilityHidden(true)
            label(item)
            Spacer(minLength: PUI.Space.l)
        }
        .padding(.horizontal, PUI.Space.l)
        .padding(.vertical, PUI.Space.m)
        .frame(minHeight: 38)
    }

    private func row(_ item: Item) -> some View {
        let on = isOn(item)
        return HStack(spacing: PUI.Space.m + 2) {
            moveActions(item, on: handle)
                .focusable()
                .onKeyPress(.upArrow) { move(item, by: -1); return .handled }
                .onKeyPress(.downArrow) { move(item, by: 1); return .handled }
                .accessibilityElement()
                .accessibilityLabel(Text(pui: "Reorder"))
            label(item)
                .environment(\.puiReorderableIsOn, on.wrappedValue)
                .accessibilityHidden(true)
            Spacer(minLength: PUI.Space.l)
            moveActions(item, on: Toggle(isOn: on) { label(item) }
                .toggleStyle(PUISwitchStyle(showsLabel: false)))
        }
        .padding(.horizontal, PUI.Space.l)
        .padding(.vertical, PUI.Space.m)
        .frame(minHeight: 38)
        .contentShape(Rectangle())
        .overlay(alignment: landsAbove(item) ? .top : .bottom) {
            // The line where the dragged row will land: above the target when dragged up,
            // below it when dragged down.
            if target == item.id, let drag, drag.id != item.id {
                Capsule()
                    .fill(accent.color)
                    .frame(height: 2)
                    .padding(.horizontal, PUI.Space.l)
                    .offset(y: landsAbove(item) ? -1 : 1)
                    .allowsHitTesting(false)
            }
        }
        .onDrag {
            let token = UUID().uuidString
            drag = (item.id, token)
            return NSItemProvider(object: token as NSString)
        } preview: {
            label(item).padding(PUI.Space.m)
        }
        .dropDestination(for: String.self) { tokens, _ in
            defer { drag = nil; target = nil }
            // Only a drag that started in this list carries the token.
            guard let drag, tokens.first == drag.token, drag.id != item.id else { return false }
            withAnimation(animation) {
                items = Reorder.moving(items, id: drag.id, onto: item.id, isLocked: isLocked)
            }
            return true
        } isTargeted: { targeted in
            if targeted { target = item.id } else if target == item.id { target = nil }
        }
        .contextMenu {
            Button { move(item, by: -1) } label: { Text(pui: "Move Up") }
                .disabled(!canMove(item, by: -1))
            Button { move(item, by: 1) } label: { Text(pui: "Move Down") }
                .disabled(!canMove(item, by: 1))
        }
    }

    private var handle: some View {
        Image(systemName: "line.3.horizontal")
            .font(PUI.Font.callout)
            .foregroundStyle(Ink(scheme).tertiary)
            .frame(width: 16)
    }

    /// Adds Move Up and Move Down as named accessibility actions.
    private func moveActions(_ item: Item, on view: some View) -> some View {
        view
            .accessibilityAction(named: Text(pui: "Move Up")) { move(item, by: -1) }
            .accessibilityAction(named: Text(pui: "Move Down")) { move(item, by: 1) }
    }

    /// Whether the dragged row comes from below `item`, and so lands above it.
    private func landsAbove(_ item: Item) -> Bool {
        guard let drag,
              let from = items.firstIndex(where: { $0.id == drag.id }),
              let to = items.firstIndex(where: { $0.id == item.id }) else { return false }
        return from > to
    }

    private func canMove(_ item: Item, by offset: Int) -> Bool {
        let free = items.filter { !isLocked($0) }
        guard let position = free.firstIndex(where: { $0.id == item.id }) else { return false }
        return free.indices.contains(position + offset)
    }

    private func move(_ item: Item, by offset: Int) {
        withAnimation(animation) {
            items = Reorder.moving(items, id: item.id, by: offset, isLocked: isLocked)
        }
    }

    /// Rows slide to their new place with the state spring, and jump with Reduce Motion.
    private var animation: Animation? {
        reduceMotion ? nil : PUI.Motion.spring(reduceMotion: false)
    }
}

// MARK: - Group

/// A settings group for choosing what is shown and in which order: a `SettingsGroup`
/// of `ReorderableRows`, with the same header and footer.
public struct ReorderableGroup<Item: Identifiable, Label: View>: View {
    var header: Text?
    var footer: Text?
    let rows: ReorderableRows<Item, Label>

    public init(_ header: Text, footer: Text? = nil,
                items: Binding<[Item]>,
                isOn: @escaping (Item) -> Binding<Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(header: header, footer: footer,
                  rows: ReorderableRows(items, isOn: isOn, isLocked: isLocked, label: label))
    }

    /// `header` and `footer` are looked up in the app's string catalog.
    public init(_ header: LocalizedStringKey? = nil, footer: LocalizedStringKey? = nil,
                items: Binding<[Item]>,
                isOn: @escaping (Item) -> Binding<Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(header: header.map { Text($0) }, footer: footer.map { Text($0) },
                  rows: ReorderableRows(items, isOn: isOn, isLocked: isLocked, label: label))
    }

    /// `header` and `footer` are shown as given.
    @_disfavoredOverload
    public init(_ header: String? = nil, footer: String? = nil,
                items: Binding<[Item]>,
                isOn: @escaping (Item) -> Binding<Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(header: header.map { Text(verbatim: $0) }, footer: footer.map { Text(verbatim: $0) },
                  rows: ReorderableRows(items, isOn: isOn, isLocked: isLocked, label: label))
    }

    /// `isOn` is the item's own visibility flag, written back into `items`.
    public init(_ header: Text, footer: Text? = nil,
                items: Binding<[Item]>,
                isOn: WritableKeyPath<Item, Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(header: header, footer: footer,
                  rows: ReorderableRows(items, isOn: isOn, isLocked: isLocked, label: label))
    }

    /// `header` and `footer` are looked up in the app's string catalog; `isOn` is the
    /// item's own visibility flag.
    public init(_ header: LocalizedStringKey? = nil, footer: LocalizedStringKey? = nil,
                items: Binding<[Item]>,
                isOn: WritableKeyPath<Item, Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(header: header.map { Text($0) }, footer: footer.map { Text($0) },
                  rows: ReorderableRows(items, isOn: isOn, isLocked: isLocked, label: label))
    }

    /// `header` and `footer` are shown as given; `isOn` is the item's own visibility flag.
    @_disfavoredOverload
    public init(_ header: String? = nil, footer: String? = nil,
                items: Binding<[Item]>,
                isOn: WritableKeyPath<Item, Bool>,
                isLocked: @escaping (Item) -> Bool = { _ in false },
                @ViewBuilder label: @escaping (Item) -> Label) {
        self.init(header: header.map { Text(verbatim: $0) }, footer: footer.map { Text(verbatim: $0) },
                  rows: ReorderableRows(items, isOn: isOn, isLocked: isLocked, label: label))
    }

    private init(header: Text?, footer: Text?, rows: ReorderableRows<Item, Label>) {
        self.header = header
        self.footer = footer
        self.rows = rows
    }

    public var body: some View {
        SettingsGroup(header: header, footer: footer) { rows }
    }
}
