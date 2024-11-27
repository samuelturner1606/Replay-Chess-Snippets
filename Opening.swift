import Foundation
import CoreData

extension Chessboard {
    static let startPosition =
        "♜h8♟h7♞g8♟g7♝f8♟f7♚e8♟e7♛d8♟d7♝c8♟c7♞b8♟b7♜a8♟a7♙h2♖h1♙g2♘g1♙f2♗f1♙e2♔e1♙d2♕d1♙c2♗c1♙b2♘b1♙a2♖a1"
    
    /// Recursively graft unique descendants onto another game tree.
    func graft(onto other: Chessboard) {
        for child in children {
            if let clone = other.children.first(where: {$0.pieces == child.pieces}) {
                clone.comment.append("\n" + child.comment)
                child.graft(onto: clone)
            } else {
                child.parent = other
            }
        }
    }
}

extension NSManagedObjectContext {
    
    func opening() -> Chessboard {
        let request = NSFetchRequest<Chessboard>(entityName: "Chessboard")
        request.predicate = NSPredicate(format: "parent == nil AND puzzle == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Chessboard.visited, ascending: true)]
        let openings = ( try? fetch(request) ) ?? []
        switch openings.count {
        case 0:
            let new = Chessboard(context: self, pieces: Chessboard.startPosition)
            return new
        case 1:
            return openings.first!
        default:
            let original = openings.first!
            for duplicate in openings.dropFirst() {
                duplicate.graft(onto: original)
                delete(duplicate)
            }
            return original
        }
    }
    
}
