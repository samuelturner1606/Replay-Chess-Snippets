enum Colour: Comparable {
    case white, black
    
    static prefix func !(colour: Colour) -> Colour {
        colour == .white ? .black : .white
    }
    
    init?(_ chessman: Substring) {
        switch chessman {
        case "♙", "♘", "♗", "♖", "♕", "♔", "P", "N", "B", "R", "Q", "K":
            self = .white
        case "♟", "♞", "♝", "♜", "♛", "♚", "p", "n", "b", "r", "q", "k":
            self = .black
        default: return nil
        }
    }
}

enum Role: Comparable {
    case pawn, knight, bishop, rook, queen, king
    
    init?(_ chessman: Substring) {
        switch chessman {
        case "♙", "♟", "P", "p": self = .pawn
        case "♘", "♞", "N", "n": self = .knight
        case "♗", "♝", "B", "b": self = .bishop
        case "♖", "♜", "R", "r": self = .rook
        case "♕", "♛", "Q", "q": self = .queen
        case "♔", "♚", "K", "k": self = .king
        default: return nil
        }
    }
    
    static let promotions: [Role] = [.knight, .bishop, .rook, .queen]
    
    func offsets(_ colour: Colour = .white) -> [Offset] {
        switch self {
        case .pawn:
            switch colour {
            case .white: [.upLeft, .upRight]
            case .black: [.downLeft, .downRight]
            }
        case .knight:
            [Offset(x: -2, y: -1), Offset(x: -2, y: 1), Offset(x: -1, y: -2), Offset(x: -1, y: 2), Offset(x: 1, y: -2), Offset(x: 1, y: 2), Offset(x: 2, y: -1), Offset(x: 2, y: 1)]
        case .bishop:
            [.upLeft, .downLeft, .upRight, .downRight]
        case .rook:
            [.left, .right, .up, .down]
        case .queen, .king:
            [.left, .right, .up, .down, .upLeft, .downLeft, .upRight, .downRight]
        }
    }
}

struct Piece: Identifiable {
    let colour: Colour
    var role: Role
    var square: Square
    var id: UUID = UUID()
    
    init(colour: Colour, role: Role, file: File, rank: Rank) {
        self.colour = colour
        self.role = role
        self.square = Square(file: file, rank: rank)
    }
    
    func shift(by offset: Offset) -> Piece? {
        if let file = File(x: square.file.x + offset.x),
            let rank = Rank(y: square.rank.y + offset.y) {
            var piece = self
            piece.square.file = file
            piece.square.rank = rank
            return piece
        }
        return nil
    }
}

extension Piece: Hashable {
    static func == (lhs: Piece, rhs: Piece) -> Bool {
        lhs.colour == rhs.colour
        && lhs.role == rhs.role
        && lhs.square == rhs.square
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(colour)
        hasher.combine(role)
        hasher.combine(square)
    }
}

extension Piece: LosslessStringConvertible {
    init?(_ description: String) {
        if let match = description.wholeMatch(of: /(?<chessman>[♙♘♗♖♕♔♟♞♝♜♛♚PNBRQKpnbrqk])(?<file>[a-hA-H])(?<rank>[1-8])/) {
            self.init(match: match)
        }
        return nil
    }
    
    init?(match: Regex<Regex<(Substring, chessman: Substring, file: Substring, rank: Substring)>.RegexOutput>.Match) {
        self.colour = Colour(match.output.chessman)!
        self.role = Role(match.output.chessman)!
        self.square = Square(file: match.output.file, rank: match.output.rank)!
    }
    
    var description: String {
        let chessman = switch (colour, role) {
        case (.white, .pawn): "♙"
        case (.white, .knight): "♘"
        case (.white, .bishop): "♗"
        case (.white, .rook): "♖"
        case (.white, .queen): "♕"
        case (.white, .king): "♔"
        case (.black, .pawn): "♟"
        case (.black, .knight): "♞"
        case (.black, .bishop): "♝"
        case (.black, .rook): "♜"
        case (.black, .queen): "♛"
        case (.black, .king): "♚"
        }
        return chessman + square.description
    }
}

extension Piece: Comparable {
    static func < (lhs: Piece, rhs: Piece) -> Bool {
        if lhs.colour != rhs.colour {
            return lhs.colour < rhs.colour
        } else {
            return lhs.square < rhs.square
        }
    }
}

extension Collection<Piece> {
    func sortedText(by turn: Colour) -> String {
        (turn == .white ? sorted(by: >) : sorted(by: <)).reduce("") { $0.description + $1.description }
    }
    
    subscript(square: Square) -> Piece? {
        first { $0.square == square }
    }
    
    subscript(file: File, rank: Rank) -> Piece? {
        first { $0.square.file == file && $0.square.rank == rank }
    }
    
    func king(colour: Colour) -> Piece {
        first { $0.role == .king && $0.colour == colour }!
    }
    
    func checks(on king: Piece, skip: Bool = true) -> UInt {
        var count: UInt = 0
        
        for jumper in [Role.pawn, Role.knight] {
            for offset in jumper.offsets(king.colour) {
                guard let to = king.shift(by: offset) else {
                    continue
                }
                if let capture = self[to.square],
                   capture.role == jumper, capture.colour != king.colour {
                    if skip { return 1 } else { count += 1 }
                }
            }
        }
        
        for slider in [Role.bishop, Role.rook] {
            for direction in slider.offsets() {
                for distance in 1...7 {
                    guard let to = king.shift(by: distance * direction) else {
                        break // not continue
                    }
                    if let capture = self[to.square] {
                        switch capture.role {
                        case slider, .queen,
                                .king where distance == 1:
                            if capture.colour != king.colour {
                                if skip { return 1 } else { count += 1 }
                            }
                        default:
                            break
                        }
                        break // sliding pieces cannot capture through others
                    }
                }
            }
        }
        
        return count
    }
    
    func isValidPosition(turn: Colour) -> Bool {
        guard count > 2 else {
            return false
        }
        let isPromotion = first { $0.role == .pawn && ($0.square.rank == .one || $0.square.rank == .eight) }
        guard isPromotion == nil else {
            return false
        }
        let whiteKings = filter { $0.role == .king && $0.colour == .white }
        guard whiteKings.count == 1 else {
            return false
        }
        let blackKings = filter { $0.role == .king && $0.colour == .black }
        guard blackKings.count == 1 else {
            return false
        }
        let enemyKing = turn == .white ? blackKings.first! : whiteKings.first!
        guard checks(on: enemyKing) == 0 else {
            return false // king can never be captured
        }
        return true
    }
}
