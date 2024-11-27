import Foundation
import CoreData

@Observable
final class Game {
    var board: Chessboard
    
    var position: Set<Piece>
    var king: Piece
    var lastMove: Move?
    
    var moves = [Move]()
    var inCheck = false
    
    var viewing: Colour = .white
    var tapped: Piece? = nil
    var promoting: Move? = nil
    var computer: Colour? = nil
    
    init(board: Chessboard) {
        self.board = board
        let position = board.position
        self.position = position
        self.king = position.king(colour: board.turn)
        self.lastMove = board.lastMove(with: position)
        moveGenerator()
    }
    
    func play(move: Move, context: NSManagedObjectContext) {
        let description = move.description
        if let clone = board.children.first(where: { $0.pieces == description }) {
            board = clone
        } else {
            let new = Chessboard(
                context: context,
                pieces: description,
                badge: computer == nil ? .correct : .wrong,
                parent: board
            )
            board = new
        }
        apply(move: move)
        
        if computer == king.colour {
            switch Badge(rawValue: board.badge) {
            case .correct:
                if computerMove() == false {
                    computer = nil
                    if let puzzle = board.puzzle {
                        puzzle.reschedule()
                    }
                }
            case .wrong:
                if let puzzle = board.puzzle {
                    puzzle.strikes += 1
                    if puzzle.strikes == 3 {
                        computer = nil
                        if let puzzle = board.puzzle {
                            puzzle.reschedule()
                        }
                    }
                }
            default:
                break
            }
        }
        
    }
    
    /// Attempts to play a computer move.
    /// - Returns: true if a move was made
    @discardableResult
    func computerMove() -> Bool {
        let correct = Badge.correct.rawValue
        let candidates = board.children.filter { child in
            child.children.contains { $0.badge == correct }
        }
        guard !candidates.isEmpty else { return false }
        
        computer = king.colour
        board = candidates.min { $0.visited < $1.visited }! // returns the oldest chessboard
        let move = board.lastMove(with: position)!
        apply(move: move)
        return true
    }
    
    func apply(move: Move) {
        board.visited = .now
        tapped = nil
        position.formSymmetricDifference(move.set)
        king = position.king(colour: !king.colour)
        lastMove = board.lastMove(with: position) // apply can go in reverse so this isn't always the same as `move`
        moveGenerator()
    }
    
    func forward() {
        board = board.children.max { $0.visited < $1.visited }!
        apply(move: board.lastMove(with: position)!)
    }
    
    func backward() {
        let move = lastMove!
        board = board.parent!
        apply(move: move)
    }
}

// MARK: Move generation
extension Game {
    private func moveGenerator() {
        moves = []
        
        let count = position.checks(on: king, skip: false)
        inCheck = count != 0
        
        switch count {
        case 0:
            castling()
            fallthrough
        case 1:
            for piece in position where piece.colour == king.colour {
                switch piece.role {
                case .pawn:
                    pawn(from: piece)
                case .knight, .king:
                    jumping(from: piece)
                case .bishop, .rook, .queen:
                    sliding(from: piece)
                }
            }
        default: // only the king can move in double check
            jumping(from: king)
        }
        removeIllegalMoves()
    }
    
    private func removeIllegalMoves() {
        moves.removeAll { move in
            let nextPosition = position.symmetricDifference(move.set)
            if move.p2.role == .king {
                if nextPosition.checks(on: move.p2) == 0 {
                    return false
                }
            } else if nextPosition.checks(on: king) == 0 {
                return false
            }
            return true
        }
    }
    
    private func pawn(from: Piece) {
        let pushOffset: Offset = from.colour == .white ? .up : .down
        // MARK: single pawn push
        let to1 = from.shift(by: pushOffset)
        if let to1, position[to1.square] == nil {
            moves.append(Move(p1: from, p2: to1))
            // MARK: double pawn push
            if from.square.rank == (from.colour == .white ? .two : .seven),
               let to2 = to1.shift(by: pushOffset), position[to2.square] == nil {
                moves.append(Move(p1: from, p2: to2))
            }
        }
        // MARK: pawn capture moves
        for attack in Role.pawn.offsets(from.colour) {
            guard let to = from.shift(by: attack) else {
                continue
            }
            if let capture = position[to.square] {
                if capture.colour != from.colour {
                    moves.append(Move(p1: from, p2: to, p3: capture))
                }
            } else if let lastMove, lastMove.p2.role == .pawn
                        && abs(lastMove.p1.square.rank.y - lastMove.p2.square.rank.y) == 2
                        && lastMove.p2.square.rank == from.square.rank
                        && lastMove.p2.square.file == to.square.file {
                // MARK: en passant
                moves.append(Move(p1: from, p2: to, p3: lastMove.p2))
            }
        }
    }
    
    private func jumping(from: Piece) {
        for offset in from.role.offsets() {
            guard let to = from.shift(by: offset) else {
                continue
            }
            if let capture = position[to.square] {
                if capture.colour != from.colour {
                    moves.append(Move(p1: from, p2: to, p3: capture))
                }
            } else {
                moves.append(Move(p1: from, p2: to))
            }
        }
    }
    
    private func sliding(from: Piece) {
        for direction in from.role.offsets() {
            for distance in 1...7 {
                guard let to = from.shift(by: distance * direction) else {
                    break
                }
                if let capture = position[to.square] {
                    if capture.colour != from.colour {
                        moves.append(Move(p1: from, p2: to, p3: capture))
                    }
                    break
                } else {
                    moves.append(Move(p1: from, p2: to))
                }
            }
        }
    }
    
    private func castling() {
        let rank = king.colour == .white ? Rank.one : Rank.eight
        guard king.square.file == .e && king.square.rank == rank else {
            return
        }
        let history = board.history
        guard !history.contains(king.description) else {
            return
        }
        var kingTo = king
        // MARK: king side castle
        if position[.f, rank] == nil && position[.g, rank] == nil {
            if let corner = position[.h, rank], corner.role == .rook && corner.colour == king.colour {
                kingTo.square.file = .g
                var rookTo = corner
                rookTo.square.file = .f
                if !history.contains(corner.description) && position.checks(on: rookTo) == 0 {
                    moves.append(Move(p1: king, p2: kingTo, p3: corner, p4: rookTo))
                }
            }
        }
        // MARK: queen side castle
        if position[.b, rank] == nil && position[.c, rank] == nil && position[.d, rank] == nil {
            if let corner = position[.a, rank], corner.role == .rook && corner.colour == king.colour {
                kingTo.square.file = .c
                var rookTo = corner
                rookTo.square.file = .d
                if !history.contains(corner.description) && position.checks(on: rookTo) == 0 {
                    moves.append(Move(p1: king, p2: kingTo, p3: corner, p4: rookTo))
                }
            }
        }
    }
    
}

extension Game: Hashable { // Required for navigation paths
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension Game {
    func deepCopy(other: Game) {
        board = other.board
        position = other.position
        king = other.king
        lastMove = other.lastMove
        moves = other.moves
        inCheck = other.inCheck
        viewing = other.viewing
        tapped = other.tapped
        promoting = other.promoting
        computer = other.computer
    }
}
