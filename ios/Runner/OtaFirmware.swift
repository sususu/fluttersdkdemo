import Foundation

func otaError(_ message: String) -> NSError { NSError(domain: "OTA", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }


/// Server / local OTA package metadata (aligned with Android `OtaUpgradeInfo`).
struct OtaUpgradeInfo {
    var version: String?
    var build: Int64?
    var forceUpdate: Bool = false
    var updateContent: String?
    var firmwares: [OtaFirmwareItem] = []
    /// Optional diff-mode resource package (required when zip contains `diff_ctrl*.bin`).
    var resource: OtaResourceItem?
}

struct OtaFirmwareItem {
    var url: String
    var md5: String?
    var name: String?
    var id: String?
    /// Firmware type from server (`0x01` platform, picture types used by production apps).
    var type: Int = 0x01
}

struct OtaResourceItem {
    var name: String?
    var url: String?
    var md5: String?
    var fromVersion: String?
    var toVersion: String?
}


/// Parse / compare watch firmware version strings.
///
/// Device firmware is typically shaped like:
/// `V{major}R{…}T{…}H{…}B{build}…`
/// e.g. `V1.0.0RxxxTxxxHxxxB123`
///
/// Used by OTA check (aligned with Android `FirmwareVersionUtils`):
/// - Extract `V` / `B` for the server request body (`currentVersion` / `currentBuild`).
/// - Decide whether the server package is newer (`canUpgrade`).
enum FirmwareVersionUtils {
    private static let pattern = try! NSRegularExpression(
        pattern: #"V(.+?)R(.+?)T(.+?)H(.+?)B(\d+).*"#,
        options: [.caseInsensitive]
    )

    static func extractV(_ str: String?) -> String {
        extract(str, group: 1) ?? ""
    }

    static func extractB(_ str: String?) -> Int64? {
        guard let s = extract(str, group: 5) else { return nil }
        return Int64(s)
    }

    static func canUpgrade(currentVersion: String?, currentBuild: Int64?, destVersion: String?, destBuild: Int64?) -> Bool {
        guard let current = parts(currentVersion), let destination = parts(destVersion),
              let currentBuild = currentBuild, currentBuild >= 0,
              let destBuild = destBuild, destBuild >= 0 else { return false }
        for index in 0..<max(current.count, destination.count) {
            let old = index < current.count ? current[index] : 0
            let new = index < destination.count ? destination[index] : 0
            if old != new { return old < new }
        }
        return currentBuild < destBuild
    }

    private static func parts(_ version: String?) -> [Int]? {
        guard let version = version, !version.isEmpty else { return nil }
        let pieces = version.split(separator: ".", omittingEmptySubsequences: false)
        let numbers = pieces.compactMap { piece -> Int? in
            guard !piece.isEmpty, piece.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
            return Int(piece)
        }
        return numbers.count == pieces.count ? numbers : nil
    }

    private static func extract(_ str: String?, group: Int) -> String? {
        guard let str = str, !str.isEmpty else { return nil }
        let range = NSRange(str.startIndex..., in: str)
        guard let match = pattern.firstMatch(in: str, options: [], range: range),
              match.numberOfRanges > group,
              let r = Range(match.range(at: group), in: str) else { return nil }
        return String(str[r])
    }
}

enum OtaFirmware {
    static func parseUpgradeResponse(_ json: String) throws -> OtaUpgradeInfo {
        guard let data = json.data(using: .utf8),
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw otaError("invalid JSON")
        }
        let ok = (root["ok"] as? Bool) ?? ((root["code"] as? Int) == 0)
        if !ok {
            let msg = (root["msg"] as? String)?.nilIfEmpty
                ?? (root["message"] as? String)?.nilIfEmpty
                ?? "check upgrade failed"
            throw otaError(msg)
        }
        guard let obj = root["data"] as? [String: Any] else { return OtaUpgradeInfo() }
        return parseUpgradeInfoObject(obj)
    }

    private static func parseUpgradeInfoObject(_ obj: [String: Any]) -> OtaUpgradeInfo {
        var firmwares: [OtaFirmwareItem] = []
        let arr = (obj["firmwares"] as? [[String: Any]])
            ?? (obj["firmwareList"] as? [[String: Any]])
            ?? (obj["files"] as? [[String: Any]])
            ?? []
        for f in arr {
            let url = (f["url"] as? String)?.nilIfEmpty ?? (f["downloadUrl"] as? String)?.nilIfEmpty ?? ""
            if url.isEmpty { continue }
            firmwares.append(OtaFirmwareItem(
                url: url,
                md5: (f["md5"] as? String)?.nilIfEmpty ?? (f["fileMd5"] as? String)?.nilIfEmpty,
                name: (f["name"] as? String)?.nilIfEmpty,
                id: (f["id"] as? String)?.nilIfEmpty,
                type: (f["type"] as? Int) ?? 0x01
            ))
        }
        var resource: OtaResourceItem?
        if let r = obj["resource"] as? [String: Any] {
            resource = OtaResourceItem(
                name: (r["name"] as? String)?.nilIfEmpty,
                url: (r["url"] as? String)?.nilIfEmpty,
                md5: (r["md5"] as? String)?.nilIfEmpty,
                fromVersion: (r["fromVersion"] as? String)?.nilIfEmpty,
                toVersion: (r["toVersion"] as? String)?.nilIfEmpty
            )
        }
        let buildValue: Int64? = {
            if let n = obj["build"] as? NSNumber { return n.int64Value }
            if let s = obj["build"] as? String { return Int64(s) }
            return nil
        }()
        return OtaUpgradeInfo(
            version: (obj["version"] as? String)?.nilIfEmpty
                ?? (obj["firmwareVersion"] as? String)?.nilIfEmpty,
            build: buildValue,
            forceUpdate: (obj["forceUpdate"] as? Bool) ?? false,
            updateContent: (obj["updateContent"] as? String)?.nilIfEmpty
                ?? (obj["content"] as? String)?.nilIfEmpty
                ?? (obj["desc"] as? String)?.nilIfEmpty,
            firmwares: firmwares,
            resource: resource
        )
    }

}
private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }
