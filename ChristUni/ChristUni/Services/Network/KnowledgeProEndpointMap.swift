import Foundation

struct KnowledgeProEndpointMap {
    let baseURL: URL
    private let routes: [String: String]

    init(
        baseURL: URL = URL(string: "https://kp.christuniversity.in/KnowledgePro/")!,
        routes: [String: String] = [
            "login": "StudentLoginAction.do",
            "home": "StudentLoginNewAction.do?method=returnHomePage",
            "attendanceSummary": "studentWiseAttendanceSummary.do?method=getIndividualStudentWiseSubjectAndActivityAttendanceSummary",
            "attendance": "studentWiseAttendanceSummary.do?method=initPreviousStudentAttendanceSummeryChrist",
            "attendanceCurrentA": "studentWiseAttendanceSummary.do?method=initStudentWiseAttendanceSummeryChrist",
            "attendanceCurrentB": "studentWiseAttendanceSummary.do?method=initStudentAttendanceSummeryChrist",
            "attendancePreviousResult": "studentWiseAttendanceSummary.do",
            "academicsSelect": "StudentLoginNewAction.do?method=initMarksCard",
            "academicsResult": "StudentLoginNewAction.do",
            "academicsResultPrint": "StudentLoginNewAction.do?method=printMarksCard",
            "facultySelect": "facultyLocation.do?method=initFacultyLocation",
            "facultyInfo": "facultyLocation.do?method=searchDetails"
        ]
    ) {
        self.baseURL = baseURL
        self.routes = routes
    }

    func url(for key: String) -> URL? {
        guard let path = routes[key] else { return nil }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }
}
