import Foundation
import CoreData

@objc(Puzzle)
public final class Puzzle: NSManagedObject, Identifiable {
    @NSManaged public private(set) var board: Chessboard!
    
    @NSManaged public var due: Date
    @NSManaged public var solved: Date
    @NSManaged public var strikes: Int16
    @NSManaged public var finished: Bool
    
    init(context: NSManagedObjectContext, board: Chessboard) {
        let entity = NSEntityDescription.entity(forEntityName: "Puzzle", in: context)!
        super.init(entity: entity, insertInto: context)
        self.due = .now
        self.solved = due - TimeInterval.day
        self.strikes = 0
        finished = false
        board.puzzle = self
        self.board = board
    }
    
    @objc
    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    @available(*, unavailable)
    public init() {
        fatalError("\(#function) not implemented")
    }
    
    @available(*, unavailable)
    public convenience init(context: NSManagedObjectContext) {
        fatalError("\(#function) not implemented")
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Puzzle> {
        return NSFetchRequest<Puzzle>(entityName: "Puzzle")
    }
    
    /// Updates the schedule; the lower the number of strikes, the longer the duration until the puzzle is next due.
    func reschedule() {
        let duration = solved.distance(to: due)
        due = switch strikes {
        case 0: .now + (duration * 2)
        case 1: .now + duration
        case 2: .now + max(TimeInterval.day, duration / 2)
        default: .now + TimeInterval.day
        }
        solved = .now
        finished = true
    }
    
    static var requestToday: NSFetchRequest<Puzzle> {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .init(day: 1), to: start) ?? start
        
        let request = Puzzle.fetchRequest()
        let dueBeforeTodaysEnd = NSPredicate(format: "due <= %@", end as NSDate)
        let solvedToday = NSPredicate(format: "(%@ <= solved AND solved <= %@)", start as NSDate, end as NSDate)
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [dueBeforeTodaysEnd, solvedToday])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Puzzle.due, ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["board"]
        return request
    }
    
    enum Phase { case solvable, editable, locked }
    
    var phase: Phase {
        let calendar = Calendar.autoupdatingCurrent
        if (due < .now) || calendar.isDateInToday(due) {
            return .solvable
        } else if calendar.isDateInToday(solved) {
            return .editable
        } else {
            return .locked
        }
    }
}

extension TimeInterval {
    static let day: TimeInterval = 24 * 60 * 60
}

/*
 extension NSManagedObjectContext {
     
     var puzzleCount: Int {
         ( try? count(for: Puzzle.fetchRequest()) ) ?? 0
     }
     
     func earliestPuzzleDate() -> Date? {
         let request = Puzzle.fetchRequest()
         request.sortDescriptors = [NSSortDescriptor(keyPath: \Puzzle.due, ascending: true)]
         request.propertiesToFetch = [\Puzzle.due]
         request.fetchLimit = 1
         let result = try? fetch(request)
         return result?.first?.due
     }
     
 }
*/
