import SwiftUI

struct SemesterRecordDetailView: View {
    let record: SemesterRecord
    @State private var selectedSubject: SemesterSubjectMark?
    @State private var heroReady = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                if let detail = record.detail {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject Breakdown")
                            .font(DesignTokens.FontStyle.headline(20, weight: .bold))
                            .foregroundStyle(Color.appPrimary)
                        ForEach(detail.subjectRows) { row in
                            subjectRow(row)
                        }
                    }
                } else {
                    Text("Detailed marks are unavailable for this semester.")
                        .font(DesignTokens.FontStyle.body(14, weight: .medium))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.appSurface.ignoresSafeArea())
        .onAppear {
            heroReady = false
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                    heroReady = true
                }
            }
        }
        .sheet(item: $selectedSubject) { subject in
            SemesterSubjectDetailSheet(subject: subject)
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(record.displayTitle)
                .font(DesignTokens.FontStyle.headline(28, weight: .heavy))
                .foregroundStyle(Color.appPrimary)
            if let detail = record.detail {
                Text(detail.examLabel.uppercased())
                    .font(DesignTokens.FontStyle.label(10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                if let result = detail.resultText, !result.isEmpty {
                    Text(result)
                        .font(DesignTokens.FontStyle.body(13, weight: .semibold))
                        .foregroundStyle(Color.appSecondary)
                }
            }

            HStack(spacing: 12) {
                featuredMetricPill(title: "GPA", value: String(format: "%.2f", record.gpa))
                featuredMetricPill(title: "Percentage", value: String(format: "%.2f%%", record.percentage))
                if let credits = record.detail?.totalCreditsAwarded {
                    subduedMetricPill(title: "Credits", value: String(format: "%.0f", credits))
                }
            }

            if let maxMarks = record.detail?.totalMarksMaximum,
               let earned = record.detail?.totalMarksAwarded {
                Text("Marks: \(Int(earned))/\(Int(maxMarks))")
                    .font(DesignTokens.FontStyle.body(12, weight: .medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
        .scaleEffect(heroReady ? 1 : 0.98)
        .opacity(heroReady ? 1 : 0)
    }

    private func featuredMetricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(DesignTokens.FontStyle.label(9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Color.appOnSurfaceVariant)
            Text(value)
                .font(DesignTokens.FontStyle.headline(26, weight: .heavy))
                .foregroundStyle(Color.appPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.appSurfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func subduedMetricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(DesignTokens.FontStyle.label(9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Color.appOnSurfaceVariant)
            Text(value)
                .font(DesignTokens.FontStyle.headline(15, weight: .semibold))
                .foregroundStyle(Color.appOnSurfaceVariant)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appSurfaceLow.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func subjectRow(_ row: SemesterSubjectMark) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(row.serialNumber)
                    .font(DesignTokens.FontStyle.label(11, weight: .bold))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .frame(width: 20, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.subject)
                        .font(DesignTokens.FontStyle.body(14, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                    Text(row.type)
                        .font(DesignTokens.FontStyle.label(10, weight: .medium))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                Spacer()
                Text(row.grade)
                    .font(DesignTokens.FontStyle.body(14, weight: .bold))
                    .foregroundStyle(Color.appSecondary)
            }

            HStack {
                infoCell("Total", "\(row.totalMarksAwarded)/\(row.totalMaxMarks)")
                infoCell("Credits", row.credits)
            }
        }
        .padding(14)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appSurfaceHigh, lineWidth: 1)
        )
        .onTapGesture {
            selectedSubject = row
        }
    }

    private func infoCell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(DesignTokens.FontStyle.label(9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Color.appOnSurfaceVariant)
            Text(value)
                .font(DesignTokens.FontStyle.body(12, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SemesterSubjectDetailSheet: View {
    let subject: SemesterSubjectMark

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.subject)
                        .font(DesignTokens.FontStyle.headline(20, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                    Text(subject.type.uppercased())
                        .font(DesignTokens.FontStyle.label(10, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text("GRADE")
                        .font(DesignTokens.FontStyle.label(9, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Color.appOnSurfaceVariant)
                    Text(subject.grade)
                        .font(DesignTokens.FontStyle.headline(28, weight: .heavy))
                        .foregroundStyle(Color.appSecondary)
                }
                .padding(12)
                .background(Color.appSurfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(spacing: 10) {
                marksRow("CIA", max: subject.ciaMaxMarks, min: nil, awarded: subject.ciaMarksAwarded)
                marksRow("Attendance", max: subject.attendanceMaxMarks, min: nil, awarded: subject.attendanceMarksAwarded)
                marksRow("ESE", max: subject.eseMaxMarks, min: subject.eseMinMarks, awarded: subject.eseMarksAwarded)
                marksRow("Total", max: subject.totalMaxMarks, min: nil, awarded: subject.totalMarksAwarded, emphasized: true)
            }

            HStack {
                Text("Credits: \(subject.credits)")
                    .font(DesignTokens.FontStyle.body(13, weight: .semibold))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                Spacer()
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.appSurface)
    }

    private func marksRow(_ title: String, max: String?, min: String?, awarded: String?, emphasized: Bool = false) -> some View {
        HStack {
            Text(title.uppercased())
                .font(DesignTokens.FontStyle.label(10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.appOnSurfaceVariant)
                .frame(width: 96, alignment: .leading)
            Text("Max: \(normalized(max))")
                .font(DesignTokens.FontStyle.body(12, weight: .medium))
                .foregroundStyle(Color.appPrimary)
            if let min, !normalized(min).isEmpty, normalized(min) != "-" {
                Text("Min: \(normalized(min))")
                    .font(DesignTokens.FontStyle.body(12, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }
            Spacer()
            Text("Awarded: \(normalized(awarded))")
                .font(DesignTokens.FontStyle.body(12, weight: emphasized ? .bold : .semibold))
                .foregroundStyle(emphasized ? Color.appSecondary : Color.appPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(emphasized ? Color.appSecondaryContainer.opacity(0.35) : Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func normalized(_ value: String?) -> String {
        let cleaned = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return cleaned.isEmpty ? "-" : cleaned
    }
}

#Preview {
    SemesterRecordDetailView(
        record: SemesterRecord(
            id: UUID(),
            displayTitle: "Semester V",
            gpa: 3.96,
            percentage: 87.83,
            detail: SemesterRecordDetail(
                examLabel: "NOVEMBER 2023",
                resultText: "First Class with Distinction",
                totalCreditsAwarded: 30,
                totalMarksAwarded: 795,
                totalMarksMaximum: 900,
                subjectRows: [
                    SemesterSubjectMark(
                        id: UUID(),
                        serialNumber: "1",
                        subject: "LINEAR ALGEBRA",
                        type: "Theory",
                        ciaMaxMarks: "45",
                        ciaMarksAwarded: "42",
                        attendanceMaxMarks: "5",
                        attendanceMarksAwarded: "5",
                        eseMaxMarks: "50",
                        eseMinMarks: "20",
                        eseMarksAwarded: "42",
                        totalMaxMarks: "100",
                        totalMarksAwarded: "89",
                        credits: "3",
                        grade: "O",
                        status: ""
                    )
                ]
            )
        )
    )
}
