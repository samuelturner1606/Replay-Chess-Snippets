struct Move: Identifiable {
    var p1: Piece
    var p2: Piece
    
    var p3: Piece?
    var p4: Piece?
    
    let id = UUID()
    
    init(p1: Piece, p2: Piece, p3: Piece? = nil, p4: Piece? = nil) {
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        self.p4 = p4
    }
    
    var promoting: Bool {
        p1.role == .pawn && (p2.square.rank == .one || p2.square.rank == .eight)
    }
    
    var set: Set<Piece> {
        var move: Set<Piece> = [p1, p2]
        if let p3 { move.insert(p3) }
        if let p4 { move.insert(p4) }
        return move
    }
    
    mutating func matchIDs(with position: Set<Piece>) {
        let fromID = position.first { $0 == p1 || $0 == p2 }!.id
        p1.id = fromID
        p2.id = fromID
        if let p3, let p4 {
            let toID = position.first { $0 == p3 || $0 == p4 }!.id
            self.p3!.id = toID
            self.p4!.id = toID
        }
    }
}

extension Move: LosslessStringConvertible {
    init?(_ description: String) {
        let matches = description.matches(of: /(?<chessman>[♙♘♗♖♕♔♟♞♝♜♛♚])(?<file>[a-h])(?<rank>[1-8])/)
        
        switch matches.count {
        case 4: // castling
            self.p4 = Piece(match: matches[3])
            fallthrough
        case 3: // captures
            self.p3 = Piece(match: matches[2])
            fallthrough
        case 2: // standard
            self.p2 = Piece(match: matches[1])!
            self.p1 = Piece(match: matches[0])!
        default:
            return nil
        }
    }
    
    var description: String {
        p1.description + p2.description + (p3?.description ?? "") + (p4?.description ?? "")
    }
}
