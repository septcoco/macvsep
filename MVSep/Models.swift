import Foundation

// MARK: - Core Data Structures

struct OptionValue: Hashable {
    let displayName: String
    let parameterValue: String
}

struct FieldCondition: Hashable {
    let parameterName: String
    let values: [String]
    let showWhenMatching: Bool
}

struct AdditionalOption: Hashable {
    enum Kind: Hashable { case choice, text, multilineText }

    let parameterName: String
    let uiName: String
    let kind: Kind
    let values: [OptionValue]
    let defaultValue: String
    let condition: FieldCondition?
    let priceMultipliers: [String: Double]

    func isVisible(with selection: [String: String]) -> Bool {
        guard let condition else { return true }
        let matches = condition.values.contains(selection[condition.parameterName] ?? "")
        return matches == condition.showWhenMatching
    }
}

struct SeparationModel: Identifiable, Hashable {
    enum Tier: Int { case everyone = 0, registered = 1, premium = 2 }

    let id: Int
    let name: String
    let group: String
    let order: Int
    let tier: Tier
    let priceCoefficient: Double
    let summary: String
    let usage: Int
    let rating: Double?
    let additionalOptions: [AdditionalOption]

    var defaultOptions: [String: String] {
        Dictionary(uniqueKeysWithValues: additionalOptions.map { ($0.parameterName, $0.defaultValue) })
    }

    /// MVSep charges floor(seconds * coefficient / 60) credits, with a minimum of 1.
    func estimatedCredits(duration: TimeInterval, options: [String: String]) -> Int {
        var coefficient = priceCoefficient
        for option in additionalOptions where option.isVisible(with: options) {
            if let multiplier = option.priceMultipliers[options[option.parameterName] ?? ""] { coefficient *= multiplier }
        }
        return max(1, Int((duration * coefficient / 60).rounded(.down)))
    }
}

struct OutputFormat: Identifiable, Hashable {
    let id: Int
    let name: String
    let premiumOnly: Bool

    static let all: [OutputFormat] = [
        OutputFormat(id: 0, name: "mp3 (320 kbps)", premiumOnly: false),
        OutputFormat(id: 1, name: "wav (uncompressed, 16 bit)", premiumOnly: false),
        OutputFormat(id: 2, name: "flac (lossless, 16 bit)", premiumOnly: false),
        OutputFormat(id: 3, name: "m4a (lossy)", premiumOnly: false),
        OutputFormat(id: 4, name: "wav (uncompressed, 32 bit)", premiumOnly: true),
        OutputFormat(id: 5, name: "flac (lossless, 24 bit)", premiumOnly: true)
    ]
}

struct SeparatedFile: Identifiable, Hashable {
    var id: String { downloadURL }
    let fileName: String
    let downloadURL: String
}

/// What the user picked for a given model, remembered between sessions.
struct ModelSettings: Codable {
    var options: [String: String]
    var formatID: Int
}

// MARK: - API Response Structures

/// MVSep sends some numbers as strings ("3.6667"), so accept both.
struct FlexibleDouble: Decodable, Hashable {
    let value: Double
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) { value = number }
        else { value = Double(try container.decode(String.self)) ?? 0 }
    }
}

struct APIAlgorithm: Decodable {
    struct Group: Decodable { let name: String }
    struct Rating: Decodable { let average: FlexibleDouble?; let total: Int? }
    struct Field: Decodable {
        struct Condition: Decodable {
            let depends_on_field_id: Int
            let operator_: String
            let value_json: [String]
            let action: String
            enum CodingKeys: String, CodingKey { case depends_on_field_id, operator_ = "operator", value_json, action }
        }
        struct PriceRule: Decodable { let option_key: String; let mode: String; let value: FlexibleDouble }

        let id: Int
        let name: String
        let text: String
        let options: String?
        let default_key: String?
        let input_type: String?
        let conditions: [Condition]?
        let price_rules: [PriceRule]?
    }

    let render_id: Int
    let name: String
    let algorithm_group: Group?
    let order_id: Int?
    let orientation: Int?
    let price_coefficient: FlexibleDouble?
    let description: String?
    let usage: Int?
    let rating: Rating?
    let audio_widget: String?
    let algorithm_fields: [Field]?

    var model: SeparationModel {
        let fields = algorithm_fields ?? []
        let fieldNames = Dictionary(fields.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let options: [AdditionalOption] = fields.map { field in
            let values = OrderedJSONObject.parse(field.options ?? "").map { OptionValue(displayName: $0.value, parameterValue: $0.key) }
            let kind: AdditionalOption.Kind
            switch field.input_type {
            case "text": kind = .text
            case "textarea": kind = .multilineText
            default: kind = .choice
            }
            let condition = field.conditions?.first.flatMap { condition -> FieldCondition? in
                guard condition.operator_ == "in", let parameterName = fieldNames[condition.depends_on_field_id] else { return nil }
                return FieldCondition(parameterName: parameterName, values: condition.value_json, showWhenMatching: condition.action != "hide")
            }
            var multipliers: [String: Double] = [:]
            for rule in field.price_rules ?? [] where rule.mode == "multiplier" { multipliers[rule.option_key] = rule.value.value }
            let defaultValue = kind == .choice ? (field.default_key ?? values.first?.parameterValue ?? "") : (field.default_key ?? "")
            return AdditionalOption(parameterName: field.name, uiName: field.text, kind: kind, values: values, defaultValue: defaultValue, condition: condition, priceMultipliers: multipliers)
        }
        return SeparationModel(
            id: render_id, name: name, group: algorithm_group?.name ?? "Other", order: order_id ?? 0,
            tier: SeparationModel.Tier(rawValue: orientation ?? 0) ?? .everyone,
            priceCoefficient: price_coefficient?.value ?? 1, summary: Self.cleanDescription(description),
            usage: usage ?? 0, rating: (rating?.total ?? 0) > 0 ? rating?.average?.value : nil,
            additionalOptions: options
        )
    }

    /// Descriptions can carry HTML, and models without one come back as "<i>No data found</i>".
    private static func cleanDescription(_ text: String?) -> String {
        let plain = (text ?? "").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return plain.caseInsensitiveCompare("No data found") == .orderedSame ? "" : plain
    }
}

/// Option lists come as a JSON object inside a string, and the server's key order is the display order.
/// JSONSerialization loses that order, so read the keys in sequence first.
enum OrderedJSONObject {
    static func parse(_ json: String) -> [(key: String, value: String)] {
        guard let data = json.data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        let pattern = try! NSRegularExpression(pattern: #""((?:[^"\\]|\\.)*)"\s*:"#)
        var seen = Set<String>()
        var result: [(key: String, value: String)] = []
        for match in pattern.matches(in: json, range: NSRange(json.startIndex..., in: json)) {
            guard let range = Range(match.range(at: 1), in: json),
                  let keyData = "\"\(json[range])\"".data(using: .utf8),
                  let key = try? JSONSerialization.jsonObject(with: keyData, options: .fragmentsAllowed) as? String,
                  let value = dictionary[key], !seen.contains(key) else { continue }
            seen.insert(key)
            result.append((key, value as? String ?? "\(value)"))
        }
        return result
    }
}

struct SubmitResponse: Decodable {
    let success: Bool
    struct SubmitData: Decodable {
        let hash: String?
        let message: String?
    }
    let data: SubmitData?
    let errors: [String]?
}

struct APIFileResult: Codable, Hashable {
    let url: String
    let download: String
}

struct StatusResponse: Decodable {
    let success: Bool
    let status: String
    struct StatusData: Decodable {
        let files: [APIFileResult]?
        let message: String?
        let queue_count: Int?
        let current_order: Int?
        let eta_seconds: Int?
        let finished_chunks: Int?
        let all_chunks: Int?
    }
    let data: StatusData?
}

struct UserInfo: Decodable {
    let name: String?
    let premium_minutes: Int
    let premium_enabled: Int

    var credits: Int { premium_minutes }
    var premiumEnabled: Bool { premium_enabled == 1 }
}

struct UserResponse: Decodable {
    let success: Bool
    let data: UserInfo?
}

struct SimpleResponse: Decodable {
    let success: Bool
    let message: String?
    let errors: [String]?
}

struct HistoryAlgorithm: Codable, Hashable {
    let name: String
}

struct HistoryJob: Codable, Identifiable, Hashable {
    let id: Int
    let hash: String
    let created_at: String
    let job_exists: Bool
    let credits: Int?
    let time_left: Int?
    let algorithm: HistoryAlgorithm
}

struct HistoryResponse: Codable {
    let success: Bool
    let data: [HistoryJob]
}
