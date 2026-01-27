import AppKit

struct HeuristicSpaceLayout {
    struct Style {
        let topInset: CGFloat
        let labelHeight: CGFloat
        let maxRowWidth: CGFloat
        let maxLabelWidth: CGFloat
        let minLabelWidth: CGFloat
        let minGap: CGFloat

        static let `default` = Style(
            topInset: 26,
            labelHeight: 18,
            maxRowWidth: 900,
            maxLabelWidth: 140,
            minLabelWidth: 80,
            minGap: 10
        )
    }

    static func items(spaceCount: Int, screen: NSScreen, style: Style = .default) -> [SpaceLabelItem] {
        guard spaceCount > 0 else {
            return []
        }

        let screenFrame = screen.frame
        let rowWidth = min(screenFrame.width * 0.7, style.maxRowWidth)
        let availableWidth = max(rowWidth, style.minLabelWidth * CGFloat(spaceCount))

        let rawLabelWidth = availableWidth / CGFloat(spaceCount)
        let labelWidth = min(style.maxLabelWidth, max(style.minLabelWidth, rawLabelWidth))

        let totalLabelWidth = labelWidth * CGFloat(spaceCount)
        let gaps = max(spaceCount - 1, 1)
        let totalGapWidth = max(style.minGap * CGFloat(gaps), availableWidth - totalLabelWidth)
        let gap = totalGapWidth / CGFloat(gaps)

        let totalWidth = totalLabelWidth + gap * CGFloat(gaps)
        let startX = screenFrame.midX - totalWidth / 2
        let y = screenFrame.maxY - style.topInset - style.labelHeight

        return (1...spaceCount).map { index in
            let x = startX + CGFloat(index - 1) * (labelWidth + gap)
            let frame = CGRect(x: x, y: y, width: labelWidth, height: style.labelHeight)
            return SpaceLabelItem(index: index, frame: frame)
        }
    }
}
