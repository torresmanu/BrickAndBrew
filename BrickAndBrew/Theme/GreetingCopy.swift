import Foundation

/// Short club greetings. Functional screens stay functional; this is the Home/Crew opener.
enum GreetingCopy {
    static func headline(name: String, now: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: now)
        let first = name.split(separator: " ").first.map(String.init) ?? name
        let time: String
        switch hour {
        case 5..<12:
            time = "GOOD MORNING"
        case 12..<18:
            time = "GOOD AFTERNOON"
        default:
            time = "GOOD EVENING"
        }
        return "\(time), \(first.uppercased())"
    }
}
