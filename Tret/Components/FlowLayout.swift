import SwiftUI

/// Простой layout с переносом строк (chips/tags).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(subviews: subviews, maxWidth: maxWidth)
        let totalHeight = rows.reduce(0) { partial, row in
            partial + row.height + (partial == 0 ? 0 : lineSpacing)
        }
        let totalWidth = rows.map(\.width).max() ?? 0
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for entry in row.entries {
                let size = entry.size
                let placeY = y + (row.height - size.height) / 2
                entry.subview.place(at: CGPoint(x: x, y: placeY), proposal: ProposedViewSize(width: size.width, height: size.height))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var entries: [(subview: LayoutSubview, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let projectedWidth = current.entries.isEmpty
                ? size.width
                : current.width + spacing + size.width
            if projectedWidth > maxWidth, !current.entries.isEmpty {
                rows.append(current)
                current = Row()
            }
            if current.entries.isEmpty {
                current.width = size.width
            } else {
                current.width += spacing + size.width
            }
            current.height = max(current.height, size.height)
            current.entries.append((subview, size))
        }
        if !current.entries.isEmpty { rows.append(current) }
        return rows
    }
}
