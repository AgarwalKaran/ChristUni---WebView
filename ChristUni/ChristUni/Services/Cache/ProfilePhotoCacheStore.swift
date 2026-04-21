import Foundation

struct ProfilePhotoCacheStore {
    private let dataKey = "portal.profile.photo.data.v1"
    private let urlKey = "portal.profile.photo.url.v1"
    private let defaults = UserDefaults.standard

    func loadData() -> Data? {
        defaults.data(forKey: dataKey)
    }

    func loadURLString() -> String? {
        defaults.string(forKey: urlKey)
    }

    func save(data: Data, urlString: String) {
        defaults.set(data, forKey: dataKey)
        defaults.set(urlString, forKey: urlKey)
    }

    func clear() {
        defaults.removeObject(forKey: dataKey)
        defaults.removeObject(forKey: urlKey)
    }
}
