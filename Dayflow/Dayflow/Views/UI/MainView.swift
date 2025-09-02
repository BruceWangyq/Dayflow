//
//  MainView.swift
//  Dayflow
//
//  Timeline UI with transparent design
//

import SwiftUI
import AVKit
import AVFoundation

struct MainView: View {
    @State private var selectedIcon: SidebarIcon = .analytics
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var selectedActivity: TimelineActivity? = nil
    @State private var scrollToNowTick: Int = 0
    @ObservedObject private var inactivity = InactivityMonitor.shared
    
    // Animation states for orchestrated entrance - Emil Kowalski principles
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var timelineOffset: CGFloat = -20
    @State private var timelineOpacity: Double = 0
    @State private var sidebarOffset: CGFloat = -30
    @State private var sidebarOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    
    // Track if we've performed the initial scroll to current time
    @State private var didInitialScroll = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top row of 2x2 grid
            HStack(alignment: .center, spacing: 0) {
                // Top left: Logo (centered) — premium animation without SVG
                LogoBadgeView(imageName: "DayflowLogoMainApp", size: 45)
                    .frame(maxWidth: 100, maxHeight: .infinity)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Top right: Timeline text + Date navigation
                HStack {
                    Text("Timeline")
                        .font(.custom("InstrumentSerif-Regular", size: 42))
                        .foregroundColor(.primary)
                        .offset(x: timelineOffset)
                        .opacity(timelineOpacity)
                    
                    Spacer()
                    
                    // Date navigation
                    HStack(spacing: 12) {
                        DayflowCircleButton {
                            // Go to previous day
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } content: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        }
                        
                        Button(action: { showDatePicker = true }) {
                            DayflowPillButton(text: formatDateForDisplay(selectedDate))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        DayflowCircleButton {
                            // Go to next day
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            if tomorrow <= Date() {
                                selectedDate = tomorrow
                            }
                        } content: {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(tomorrow > Date() ? Color.gray.opacity(0.3) : Color(red: 0.3, green: 0.3, blue: 0.3))
                        }
                    }
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.leading, 10)
            .frame(height: 100)
            .layoutPriority(1)  // Keep this section fixed when window shrinks
            
            // Bottom row of 2x2 grid
            HStack(alignment: .top, spacing: 0) {
                // Bottom left: Sidebar in fixed-width gutter (prevents horizontal shift)
                VStack {
                    Spacer()
                    SidebarView(selectedIcon: $selectedIcon)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: sidebarOffset)
                        .opacity(sidebarOpacity)
                    Spacer()
                }
                .frame(width: 100)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxHeight: .infinity)
                .layoutPriority(1)
                
                // Bottom right: Main content area
                ZStack {
                    if selectedIcon == .settings {
                        // Settings view
                        SettingsView()
                    } else {
                        // Default timeline view
                        VStack(alignment: .leading, spacing: 20) {
                            // Tab filters
                            TabFilterBar()
                                .opacity(contentOpacity)
                            
                            // Content area with timeline and activity card (always side-by-side; both shrink)
                            GeometryReader { geo in
                                HStack(alignment: .top, spacing: 20) {
                                    // Timeline area - Canvas look wired to data
                                    CanvasTimelineDataView(selectedDate: $selectedDate, selectedActivity: $selectedActivity, scrollToNowTick: $scrollToNowTick)
                                        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                                        .opacity(contentOpacity)
                                    
                                    // Activity detail card — constrained height with internal scrolling for summary
                                    ActivityCard(activity: selectedActivity, maxHeight: geo.size.height, scrollSummary: true)
                                        .frame(minWidth: 260, idealWidth: 380, maxWidth: 420)
                                        .opacity(contentOpacity)
                                }
                                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                            }
                        }
                        .padding(30)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(14.72286)
                .overlay(
                    RoundedRectangle(cornerRadius: 14.72286)
                        .inset(by: 0.31)
                        .stroke(DayflowAngularGradient.gradient, lineWidth: 0.61771)
                )
            }
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate, isPresented: $showDatePicker)
        }
        .onAppear {
            // Orchestrated entrance animations following Emil Kowalski principles
            // Fast, under 300ms, natural spring motion
            
            // Logo appears first with scale and fade
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1
            }
            
            // Timeline text slides in from left
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
                timelineOffset = 0
                timelineOpacity = 1
            }
            
            // Sidebar slides up
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.15)) {
                sidebarOffset = 0
                sidebarOpacity = 1
            }
            
            // Main content fades in last
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.2)) {
                contentOpacity = 1
            }
            
            // Perform initial scroll to current time on cold start
            if !didInitialScroll {
                performInitialScrollIfNeeded()
            }
        }
        // Trigger reset when idle fired and timeline is visible
        .onChange(of: inactivity.pendingReset) { fired in
            if fired, selectedIcon != .settings {
                performIdleResetAndScroll()
                InactivityMonitor.shared.markHandledIfPending()
            }
        }
        // If user returns from Settings and a reset was pending, perform it once
        .onChange(of: selectedIcon) { newIcon in
            if newIcon != .settings, inactivity.pendingReset {
                performIdleResetAndScroll()
                InactivityMonitor.shared.markHandledIfPending()
            }
        }
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today,' MMM d"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday,' MMM d"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow,' MMM d"
        } else {
            formatter.dateFormat = "E, MMM d"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Sidebar
enum SidebarIcon: CaseIterable {
    case grid
    case analytics
    case document
    case settings
    case bug
    
    var systemName: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .document: return "doc"
        case .settings: return "gearshape"
        case .bug: return "ladybug"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedIcon: SidebarIcon
    
    var body: some View {
        VStack(alignment: .center, spacing: 10.501) {
            ForEach(SidebarIcon.allCases, id: \.self) { icon in
                SidebarIconButton(
                    icon: icon,
                    isSelected: selectedIcon == icon,
                    action: { selectedIcon = icon }
                )
                .frame(width: 40, height: 40)
            }
        }
        .padding(9.88329)
        .frame(width: 59.29975, alignment: .center)
        .background(.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 72, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 72, style: .continuous)
                .stroke(DayflowAngularGradient.gradient, lineWidth: 0.61771)
        )
        .shadow(
            color: Color.black.opacity(0.25),
            radius: 25.94,
            x: -7.74,
            y: 37.55
        )
    }
}

struct SidebarIconButton: View {
    let icon: SidebarIcon
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color(red: 1, green: 0.85, blue: 0.7).opacity(0.3))
                        .frame(width: 40, height: 40)
                }
                
                Image(systemName: icon.systemName)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Color(red: 1, green: 0.54, blue: 0.02) : Color(red: 0.6, green: 0.4, blue: 0.3))
                    .frame(width: 40, height: 40)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tab Filter Bar
struct TabFilterBar: View {
    @State private var selectedTab = "All tasks"
    
    var body: some View {
        HStack(spacing: 8) {
            TabButton(
                title: "All tasks",
                icon: "hourglass",
                gradient: LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.67, green: 0.67, blue: 0.67), location: 0.00),
                        Gradient.Stop(color: Color(red: 1, green: 0.98, blue: 0.95).opacity(0), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 1.15, y: 3.61),
                    endPoint: UnitPoint(x: 0.02, y: 0)
                ),
                isSelected: selectedTab == "All tasks",
                action: { selectedTab = "All tasks" }
            )
            
            TabButton(
                title: "Work",
                icon: "person.crop.rectangle",
                gradient: LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 1, green: 0.77, blue: 0.34), location: 0.00),
                        Gradient.Stop(color: Color(red: 1, green: 0.98, blue: 0.95).opacity(0), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 1.15, y: 3.61),
                    endPoint: UnitPoint(x: 0.02, y: 0)
                ),
                isSelected: selectedTab == "Core tasks",
                action: { selectedTab = "Core tasks" }
            )
            
            TabButton(
                title: "Personal",
                icon: "eyes",
                gradient: LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.54, green: 0.88, blue: 1), location: 0.00),
                        Gradient.Stop(color: Color(red: 1, green: 0.98, blue: 0.95).opacity(0), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 1.15, y: 3.61),
                    endPoint: UnitPoint(x: 0.02, y: 0)
                ),
                isSelected: selectedTab == "Personal tasks",
                action: { selectedTab = "Personal tasks" }
            )
            
            TabButton(
                title: "Distractions",
                icon: "face.dashed",
                gradient: LinearGradient(
                    stops: [
                        Gradient.Stop(color: .white.opacity(0.8), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.99, green: 0.69, blue: 0.69), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0, y: 0.5),
                    endPoint: UnitPoint(x: 1.08, y: 1.73)
                ),
                isSelected: selectedTab == "Distractions",
                action: { selectedTab = "Distractions" }
            )
            
            TabButton(
                title: "Idle",
                icon: "face.smiling",
                gradient: LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.67, green: 0.67, blue: 0.67), location: 0.00),
                        Gradient.Stop(color: Color(red: 1, green: 0.98, blue: 0.95).opacity(0), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 1.15, y: 3.61),
                    endPoint: UnitPoint(x: 0.02, y: 0)
                ),
                isSelected: selectedTab == "Idle time",
                action: { selectedTab = "Idle time" }
            )
            
            Spacer()
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .padding(.trailing, 6)
                Text(title)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 8.3318)
            .padding(.vertical, 5.55453)
            .background(
                gradient
                    .background(.white.opacity(0.69))
            )
            .foregroundColor(isSelected ? Color(red: 0.4, green: 0.2, blue: 0) : .secondary)
            .cornerRadius(693.62213)
            .shadow(color: Color(red: 0.57, green: 0.57, blue: 0.57).opacity(0.05), radius: 2.91304, x: -1.16522, y: 2.33043)
            .shadow(color: Color(red: 0.57, green: 0.57, blue: 0.57).opacity(0.04), radius: 5.24348, x: -4.07826, y: 9.90435)
            .shadow(color: Color(red: 0.57, green: 0.57, blue: 0.57).opacity(0.03), radius: 6.9913, x: -8.73913, y: 21.55652)
            .shadow(color: Color(red: 0.57, green: 0.57, blue: 0.57).opacity(0.01), radius: 8.44783, x: -15.73043, y: 38.45218)
            .shadow(color: Color(red: 0.57, green: 0.57, blue: 0.57).opacity(0), radius: 9.03043, x: -24.46956, y: 60.00869)
            .overlay(
                isSelected ? 
                RoundedRectangle(cornerRadius: 693.62213)
                    .inset(by: 0.29)
                    .stroke(Color(red: 1, green: 0.54, blue: 0.02).opacity(0.5), lineWidth: 0.58261)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Idle Reset Helpers
extension MainView {
    private func performIdleResetAndScroll() {
        // Switch to today
        selectedDate = Date()
        // Clear selection
        selectedActivity = nil
        // Nudge timeline to scroll to now after it reloads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.35)) {
                scrollToNowTick &+= 1
            }
        }
    }
    
    private func performInitialScrollIfNeeded() {
        // Check all conditions for initial scroll:
        // 1. Timeline is visible (not in settings)
        // 2. No modal is open
        // 3. Selected date is today
        guard selectedIcon != .settings,
              !showDatePicker,
              Calendar.current.isDateInToday(selectedDate) else {
            return
        }
        
        // Mark that we've attempted initial scroll
        didInitialScroll = true
        
        // Wait for layout to settle after animations complete
        // (0.2s for content opacity + 0.5s buffer for layout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.35)) {
                scrollToNowTick &+= 1
            }
        }
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: TimelineActivity?
    var maxHeight: CGFloat? = nil
    var scrollSummary: Bool = false
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        if let activity = activity {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: iconForActivity(activity))
                        .foregroundColor(colorForActivity(activity))
                        .font(.title2)
                    Text(activity.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text("\(timeFormatter.string(from: activity.startTime)) to \(timeFormatter.string(from: activity.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Video thumbnail placeholder
                if let videoURL = activity.videoSummaryURL {
                    VideoThumbnailView(videoURL: videoURL)
                        .id(videoURL)
                        .frame(height: 200)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "video.slash")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No video available")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        )
                }
                
                // Summary section (scrolls internally when constrained)
                Group {
                    if scrollSummary {
                        ScrollView(.vertical, showsIndicators: false) {
                            summaryContent(for: activity)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        summaryContent(for: activity)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .if(maxHeight != nil) { view in
                view.frame(maxHeight: maxHeight!)
            }
        } else {
            // Empty state
            VStack {
                Spacer()
                Image(systemName: "hand.tap")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.3))
                Text("Select an activity to view details")
                    .font(.headline)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.top)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .if(maxHeight != nil) { view in
                view.frame(maxHeight: maxHeight!)
            }
        }
    }

    @ViewBuilder
    private func summaryContent(for activity: TimelineActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUMMARY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(activity.summary)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            if !activity.detailedSummary.isEmpty && activity.detailedSummary != activity.summary {
                Text("DETAILS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                Text(activity.detailedSummary)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func iconForActivity(_ activity: TimelineActivity) -> String {
        switch activity.category.lowercased() {
        case "productive work", "work":
            return "laptopcomputer" // valid SF Symbol
        case "research", "learning":
            return "book"
        case "personal", "hobbies":
            return "person"
        case "distraction", "entertainment":
            return "play.rectangle.fill"
        default:
            return "circle"
        }
    }
    
    private func colorForActivity(_ activity: TimelineActivity) -> Color {
        switch activity.category.lowercased() {
        case "productive work", "work":
            return .blue
        case "research", "learning":
            return .purple
        case "personal", "hobbies":
            return .green
        case "distraction", "entertainment":
            return .red
        default:
            return .gray
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(value)%")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(value) / 100, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

// Background view moved to separate file: MainUIBackgroundView.swift
