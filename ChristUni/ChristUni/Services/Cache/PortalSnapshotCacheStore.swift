import Foundation

struct PortalSnapshotCacheEnvelope: Codable {
    let snapshot: StudentPortalSnapshot
    let updatedAt: Date
}

struct PortalSnapshotCacheStore {
    private let key = "portal.snapshot.cache.v1"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(snapshot: StudentPortalSnapshot, updatedAt: Date = Date()) {
        let cacheable = StudentPortalSnapshot(
            student: snapshot.student,
            todayClasses: snapshot.todayClasses,
            academicOverview: snapshot.academicOverview,
            semesterRecords: snapshot.semesterRecords,
            attendanceBundles: snapshot.attendanceBundles,
            faculty: []
        )
        let envelope = PortalSnapshotCacheEnvelope(snapshot: cacheable, updatedAt: updatedAt)
        guard let data = try? encoder.encode(envelope) else { return }
        defaults.set(data, forKey: key)
    }

    func load() -> PortalSnapshotCacheEnvelope? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(PortalSnapshotCacheEnvelope.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
