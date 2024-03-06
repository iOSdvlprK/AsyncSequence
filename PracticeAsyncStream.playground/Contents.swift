import Foundation

struct Event {
    let title: String
    let date: Date
}

class EventScheduler {
    var events: [Event] = []
    var timer: Timer?
    var eventHandler: (Event) -> Void = { _ in }
    
    func scheduleEvent(_ event: Event) {
        events.append(event)
    }
    
    func startScheduling() {
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(generateReminder), userInfo: nil, repeats: true)
    }
    
    func stopScheduling() {
        timer?.invalidate()
    }
    
    @objc func generateReminder() {
        guard let nextEvent = events.first else {
            // No more events to schedule
            timer?.invalidate()
            return
        }
        eventHandler(nextEvent)
        events.removeFirst()
    }
}

let eventReminderStream = AsyncStream<Event> { continuation in
    let eventScheduler = EventScheduler()
    eventScheduler.eventHandler = {
        continuation.yield($0)
    }
    
    continuation.onTermination = { @Sendable termination in
        switch termination {
        case .finished:
            // Clean up resources (e.g., stop scheduling events)
            eventScheduler.stopScheduling()
            print("Event reminder stream finished.")
        case .cancelled:
            // Handle cancellation (optional)
            print("Event reminder stream cancelled.")
        }
    }
    
    // Simulate scheduling some events
    eventScheduler.scheduleEvent(Event(title: "Meeting", date: Date()))
    eventScheduler.scheduleEvent(Event(title: "Birthday Party", date: Date().addingTimeInterval(3600)))
    
    eventScheduler.startScheduling()
}

Task {
    for await reminder in eventReminderStream {
        print("Reminder: \(reminder.title) at \(reminder.date)")
    }
}
