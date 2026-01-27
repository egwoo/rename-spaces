import Foundation

public enum SpaceLabelParser {
    public static func index(from label: String) -> Int? {
        let pattern = "^(Desktop|Space)\\s+(\\d+)\\s*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(label.startIndex..<label.endIndex, in: label)
        guard let match = regex.firstMatch(in: label, options: [], range: range) else {
            return nil
        }

        guard match.numberOfRanges > 2,
              let numberRange = Range(match.range(at: 2), in: label) else {
            return nil
        }

        return Int(label[numberRange])
    }
}
