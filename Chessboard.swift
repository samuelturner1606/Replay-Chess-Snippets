import Foundation
import CoreData

@objc(Chessboard)
public final class Chessboard: NSManagedObject, Identifiable {
    @NSManaged public private(set) var pieces: String
    @NSManaged public var visited: Date
    @NSManaged public var badge: Int16
    @NSManaged public var comment: String
    
    @NSManaged public var parent: Chessboard?
    @NSManaged public var children: Set<Chessboard>
    @NSManaged public var puzzle: Puzzle?
    
    init(
        context: NSManagedObjectContext,
        pieces: String,
        badge: Badge = .correct,
        parent: Chessboard? = nil
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "Chessboard", in: context)!
        super.init(entity: entity, insertInto: context)
        self.pieces = pieces
        self.visited = .now
        self.badge = badge.rawValue
        self.comment = ""
        self.parent = parent
        self.children = []
        self.puzzle = parent?.puzzle
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
    
    var turn: Colour {
        !Colour(pieces.prefix(1))!
    }
    
    var history: String {
        var board = self
        var moves = ""
        while let parent = board.parent {
            moves += board.pieces
            board = parent
        }
        return moves
    }
    
    var tokens: Set<String> {
        Set(pieces.matches(of: /[♙♘♗♖♕♔♟♞♝♜♛♚][a-h][1-8]/).map { String($0.output) })
    }
    
    var positionTokens: Set<String> {
        var tokens: Set<String> = []
        for board in sequence(first: self, next: { $0.parent }) {
            tokens.formSymmetricDifference(board.tokens)
        }
        return tokens
    }
    
    var position: Set<Piece> {
        var output: Set<Piece> = []
        for board in sequence(first: self, next: { $0.parent }) {
            let pieces = board.pieces
                .matches(of: /(?<chessman>[♙♘♗♖♕♔♟♞♝♜♛♚])(?<file>[a-h])(?<rank>[1-8])/)
                .compactMap { Piece(match: $0) }
            output.formSymmetricDifference(Set(pieces))
        }
        return output
    }
    
    func lastMove(with position: Set<Piece>) -> Move? {
        guard parent != nil else { return nil }
        var move = Move(pieces)!
        move.matchIDs(with: position)
        return move
    }
}

extension Chessboard {
    func isAncestor(of other: Chessboard) -> Bool {
        guard puzzle === other.puzzle else {
            return false
        }
        for board in sequence(first: other, next: { $0.parent }) where board === self {
            return true
            
        }
        return false
    }
}
