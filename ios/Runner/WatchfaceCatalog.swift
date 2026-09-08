import Foundation

enum WatchfaceCatalog {
  static func fileURL(_ path: String) -> URL? {
    guard !path.isEmpty else { return nil }
    let value = path.lowercased().hasPrefix("http") ? path : "https://test.huawo-wear.com/files/" + path
    guard let url = URL(string: value), ["https", "http"].contains(url.scheme ?? ""), url.host != nil else { return nil }
    return url
  }

  static func parse(_ data: Data) throws -> [[String: Any]] {
    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          (root["ok"] as? Bool) ?? ((root["code"] as? Int) == 0) else {
      let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
      throw NSError(domain: "Watchface", code: 1, userInfo: [NSLocalizedDescriptionKey: root?["msg"] as? String ?? root?["message"] as? String ?? "获取表盘列表失败"])
    }
    guard let rows = root["rows"] as? [[String: Any]] else {
      throw NSError(domain: "Watchface", code: 2, userInfo: [NSLocalizedDescriptionKey: "未返回有效的表盘列表"])
    }
    var seen = Set<String>()
    return rows.compactMap { row in
      let id = (row["id"] as? String) ?? (row["id"] as? NSNumber)?.stringValue ?? ""
      let name = row["name"] as? String ?? ""
      let key = id.isEmpty ? name : id
      guard !key.isEmpty, seen.insert(key).inserted else { return nil }
      let size = (row["byteSize"] as? NSNumber)?.int64Value ?? Int64(row["byteSize"] as? String ?? "") ?? 0
      return ["id": key, "name": name.isEmpty ? id : name,
              "thumbnail": fileURL(row["thumbnail"] as? String ?? "")?.absoluteString ?? "",
              "bin": fileURL(row["bin"] as? String ?? "")?.absoluteString ?? "",
              "binMd5": row["binMd5"] as? String ?? "", "sizeKb": max(0, size)]
    }
  }

  static func installedMatch(name: String, installed: [String]) -> String? {
    // The watch reports a short name; the catalog uses a longer display name.
    let candidates = installed.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    if let exact = candidates.first(where: { $0 == name }) { return exact }
    return candidates.sorted { $0.count > $1.count }.first { name.contains($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
  }
}
