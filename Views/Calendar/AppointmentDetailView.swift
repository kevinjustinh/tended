import SwiftUI
import EventKit
import MapKit

/// Appointment detail view for vet/grooming appointments.
/// An "appointment" in Phase 1 is simply a TendedTask with category == .vet or .grooming.
struct AppointmentDetailView: View {
    @Bindable var task: TendedTask
    @Environment(\.modelContext) private var context

    @State private var eventKitError: String?
    @State private var showAddedToCalendar = false

    var body: some View {
        ZStack {
            Color.creamWhite.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    HStack(spacing: Spacing.md) {
                        CategoryIconView(category: task.category, size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.displayTitle(size: 22))
                                .foregroundStyle(Color.textPrimary)
                            if let petName = task.pet?.name {
                                Text(petName)
                                    .font(.bodyText())
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Date/time card
                    VStack(spacing: 0) {
                        if let due = task.dueDate {
                            DetailRow(label: "Date", value: due.formatted(.dateTime.weekday(.wide).month().day().year()))
                        }
                        if !task.formattedDueTime.isEmpty {
                            Divider().padding(.leading, Spacing.lg)
                            DetailRow(label: "Time", value: task.formattedDueTime)
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, Spacing.lg)

                    // Notes
                    if !task.notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Notes")
                                .font(.cardTitle())
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, Spacing.lg)
                            Text(task.notes)
                                .font(.bodyText())
                                .foregroundStyle(Color.textPrimary)
                                .padding(Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardStyle()
                                .padding(.horizontal, Spacing.lg)
                        }
                    }

                    // Actions
                    VStack(spacing: Spacing.md) {
                        Button {
                            addToCalendar()
                        } label: {
                            Label("Add to Apple Calendar", systemImage: "calendar.badge.plus")
                                .font(.cardTitle())
                                .foregroundStyle(Color.deepForest)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                                .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                        }

                        if !task.notes.isEmpty {
                            // Map search using clinic name from notes (Phase 2: dedicated clinic field)
                            Button {
                                openMaps()
                            } label: {
                                Label("Get Directions", systemImage: "map.fill")
                                    .font(.cardTitle())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.lg)
                                    .background(Color.sageGreen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)

                    if let error = eventKitError {
                        Text(error)
                            .font(.caption())
                            .foregroundStyle(Color.alertAmber)
                            .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.vertical, Spacing.lg)
            }
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if showAddedToCalendar {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text("Added to Calendar")
                        .font(.cardTitle(size: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.successMoss, in: Capsule())
                .padding(.bottom, Spacing.xxl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - EventKit

    private func addToCalendar() {
        let store = EKEventStore()
        Task {
            do {
                let granted = try await store.requestFullAccessToEvents()
                guard granted else {
                    await MainActor.run { eventKitError = "Calendar access denied. Enable in Settings." }
                    return
                }
                let event = EKEvent(eventStore: store)
                event.title = task.title + (task.pet.map { " — \($0.name)" } ?? "")
                event.notes = task.notes
                event.calendar = store.defaultCalendarForNewEvents

                if let due = task.dueDate, let time = task.dueTime {
                    event.startDate = time
                    event.endDate = time.addingTimeInterval(3600)
                } else if let due = task.dueDate {
                    event.startDate = due
                    event.endDate = due
                    event.isAllDay = true
                }

                // Add 24hr and 1hr alarms
                event.addAlarm(EKAlarm(relativeOffset: -86400))
                event.addAlarm(EKAlarm(relativeOffset: -3600))

                try store.save(event, span: .thisEvent)
                await MainActor.run {
                    withAnimation { showAddedToCalendar = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showAddedToCalendar = false }
                    }
                }
            } catch {
                await MainActor.run { eventKitError = "Could not add to calendar: \(error.localizedDescription)" }
            }
        }
    }

    private func openMaps() {
        let query = task.notes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyText())
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.cardTitle(size: 15))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}
