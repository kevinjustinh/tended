import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \TendedTask.dueDate) private var allTasks: [TendedTask]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth: Date = Date()
    @State private var taskVM = TaskViewModel()
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    private var tasksForSelectedDate: [TendedTask] {
        let cal = Calendar.current
        // Start with tasks/occurrences that have a matching dueDate
        var result = allTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: selectedDate)
        }
        // Add recurring templates that fire on selectedDate but have no occurrence for it yet
        let representedGroupIDs = Set(result.compactMap(\.recurrenceGroupID))
        for task in allTasks where task.isRecurring {
            guard let rule = task.recurrenceRule,
                  let start = task.recurrenceStartDate,
                  let groupID = task.recurrenceGroupID,
                  rule.fires(on: selectedDate, startingFrom: start),
                  !representedGroupIDs.contains(groupID) else { continue }
            result.append(task)
        }
        return result.sorted { ($0.dueTimeSeconds ?? 0) < ($1.dueTimeSeconds ?? 0) }
    }

    private var datesWithTasks: Set<String> {
        let cal = Calendar.current
        var keys = Set(allTasks.compactMap { $0.dueDate }.map { dateKey($0) })
        // Mark dates where recurring templates fire within the displayed month
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)) else {
            return keys
        }
        for task in allTasks where task.isRecurring {
            guard let rule = task.recurrenceRule,
                  let start = task.recurrenceStartDate else { continue }
            for d in range {
                if let date = cal.date(byAdding: .day, value: d - 1, to: firstDay),
                   rule.fires(on: date, startingFrom: start) {
                    keys.insert(dateKey(date))
                }
            }
        }
        return keys
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamWhite.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Month strip
                    monthStrip

                    // Calendar grid
                    calendarGrid
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.md)

                    Divider()
                        .background(Color.warmSand)

                    // Day's tasks
                    dayTaskList
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $taskVM.showSheet) {
            AddTaskSheet(taskVM: taskVM, pets: pets)
        }
    }

    // MARK: - Month navigation strip

    private var monthStrip: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(displayedMonth, format: .dateTime.month(.wide))
                    .font(.sectionHeader())
                    .foregroundStyle(Color.deepForest)
                Text(displayedMonth, format: .dateTime.year())
                    .font(.caption())
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        let weeks = monthWeeks(for: displayedMonth)
        let dayNames = ["S","M","T","W","T","F","S"]

        return VStack(spacing: Spacing.xs) {
            // Day name headers
            HStack(spacing: 0) {
                ForEach(dayNames, id: \.self) { d in
                    Text(d)
                        .font(.caption())
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(weeks.indices, id: \.self) { wi in
                HStack(spacing: 0) {
                    ForEach(weeks[wi].indices, id: \.self) { di in
                        if let date = weeks[wi][di] {
                            DayCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                isToday: Calendar.current.isDateInToday(date),
                                hasTasks: datesWithTasks.contains(dateKey(date)),
                                action: {
                                    withAnimation(.springPop) { selectedDate = date }
                                    HapticStyle.navigation.trigger()
                                }
                            )
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day task list

    private var dayTaskList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text(selectedDate, format: .dateTime.weekday(.wide).month().day())
                        .font(.cardTitle())
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button {
                        taskVM.openAddSheet()
                        taskVM.formDueDate = selectedDate
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.sageGreen)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)

                if tasksForSelectedDate.isEmpty {
                    Text("No tasks for this day.")
                        .font(.bodyText())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, Spacing.lg)
                } else {
                    ForEach(tasksForSelectedDate) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                // Time left border
                                Rectangle()
                                    .fill(task.category.accentColor)
                                    .frame(width: 3)
                                    .cornerRadius(2)

                                CategoryIconView(category: task.category, size: 26)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.cardTitle(size: 14))
                                        .foregroundStyle(task.isCompleted ? Color.textSecondary : Color.textPrimary)
                                        .strikethrough(task.isCompleted)
                                    if let petName = task.pet?.name {
                                        Text(petName)
                                            .font(.caption())
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                }

                                Spacer()

                                if !task.formattedDueTime.isEmpty {
                                    Text(task.formattedDueTime)
                                        .font(.monoText())
                                        .foregroundStyle(Color.textSecondary)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(Color.softLinen)
                        }
                        .buttonStyle(.plain)

                        if task.id != tasksForSelectedDate.last?.id {
                            Divider().padding(.leading, Spacing.lg + 3 + Spacing.md + 26)
                        }
                    }
                }

                Spacer(minLength: 80)
            }
        }
    }

    // MARK: - Helpers

    private func changeMonth(by delta: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
    }

    private func dateKey(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    /// Returns a 2D array of optional Dates representing the calendar grid for the given month.
    private func monthWeeks(for date: Date) -> [[Date?]] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let firstWeekday = cal.component(.weekday, from: firstDay) - 1  // 0-indexed Sunday
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in range {
            days.append(cal.date(byAdding: .day, value: d - 1, to: firstDay))
        }
        // Pad to complete rows
        while days.count % 7 != 0 { days.append(nil) }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0+7]) }
    }
}

// MARK: - Day cell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTasks: Bool
    let action: () -> Void

    private var dayNumber: String {
        Calendar.current.component(.day, from: date).description
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(dayNumber)
                    .font(.system(size: 15, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(
                        isSelected ? .white :
                        isToday ? Color.sageGreen :
                        Color.textPrimary
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        isSelected ? Color.sageGreen :
                        isToday ? Color.sageGreen.opacity(0.1) :
                        Color.clear,
                        in: Circle()
                    )

                Circle()
                    .fill(isSelected ? Color.white.opacity(0.8) : Color.warmTan)
                    .frame(width: 4, height: 4)
                    .opacity(hasTasks ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CalendarView()
        .modelContainer(PersistenceController.preview)
}
