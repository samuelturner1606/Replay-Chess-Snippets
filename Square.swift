import SwiftUI

struct Square: LayoutValueKey, Hashable, Comparable {
    static let defaultValue: Square? = nil
    
    var file: File
    var rank: Rank
    
    static func < (lhs: Square, rhs: Square) -> Bool {
        if lhs.file != rhs.file {
            return lhs.file < rhs.file
        } else {
            return lhs.rank < rhs.rank
        }
    }
}

extension View {
    func place(on square: Square) -> some View {
        layoutValue(key: Square.self, value: square)
    }
}

extension Square: CustomStringConvertible {
    var description: String {
        file.description + rank.description
    }
    
    init?(file: Substring, rank: Substring) {
        self.file = File(file)!
        self.rank = Rank(rank)!
    }
}

enum File: Comparable, CaseIterable {
    case a, b, c, d, e, f, g, h
    
    var x: Double {
        switch self {
        case .a: 0.5
        case .b: 1.5
        case .c: 2.5
        case .d: 3.5
        case .e: 4.5
        case .f: 5.5
        case .g: 6.5
        case .h: 7.5
        }
    }
    
    init?(x: Double) {
        switch x {
        case 0 ..< 1: self = .a
        case 1 ..< 2: self = .b
        case 2 ..< 3: self = .c
        case 3 ..< 4: self = .d
        case 4 ..< 5: self = .e
        case 5 ..< 6: self = .f
        case 6 ..< 7: self = .g
        case 7 ... 8: self = .h
        default: return nil
        }
    }
}

enum Rank: Comparable, CaseIterable {
    case one, two, three, four, five, six, seven, eight
    
    var y: Double {
        switch self {
        case .one:   7.5
        case .two:   6.5
        case .three: 5.5
        case .four:  4.5
        case .five:  3.5
        case .six:   2.5
        case .seven: 1.5
        case .eight: 0.5
        }
    }
    
    init?(y: Double) {
        switch y {
        case 0 ..< 1: self = .eight
        case 1 ..< 2: self = .seven
        case 2 ..< 3: self = .six
        case 3 ..< 4: self = .five
        case 4 ..< 5: self = .four
        case 5 ..< 6: self = .three
        case 6 ..< 7: self = .two
        case 7 ... 8: self = .one
        default: return nil
        }
    }
}

extension File: CustomStringConvertible {
    var description: String {
        switch self {
        case .a: "a"
        case .b: "b"
        case .c: "c"
        case .d: "d"
        case .e: "e"
        case .f: "f"
        case .g: "g"
        case .h: "h"
        }
    }
    
    init?(_ file: Substring) {
        switch file {
        case "a", "A": self = .a
        case "b", "B": self = .b
        case "c", "C": self = .c
        case "d", "D": self = .d
        case "e", "E": self = .e
        case "f", "F": self = .f
        case "g", "G": self = .g
        case "h", "H": self = .h
        default: return nil
        }
    }
}

extension Rank: CustomStringConvertible {
    var description: String {
        switch self {
        case .one:   "1"
        case .two:   "2"
        case .three: "3"
        case .four:  "4"
        case .five:  "5"
        case .six:   "6"
        case .seven: "7"
        case .eight: "8"
        }
    }
    
    init?(_ rank: Substring) {
        switch rank {
        case "1": self = .one
        case "2": self = .two
        case "3": self = .three
        case "4": self = .four
        case "5": self = .five
        case "6": self = .six
        case "7": self = .seven
        case "8": self = .eight
        default: return nil
        }
    }
}

struct Offset {
    let x: Double
    let y: Double
    
    static func * (lhs: Int, rhs: Offset) -> Offset {
        let multiplier = Double(lhs)
        return Offset(x: multiplier * rhs.x, y: multiplier * rhs.y)
    }
    
    static let up = Offset(x: 0, y: -1)
    static let down = Offset(x: 0, y: 1)
    static let left = Offset(x: -1, y: 0)
    static let right = Offset(x: 1, y: 0)
    
    static let upLeft = Offset(x: -1, y: -1)
    static let upRight = Offset(x: 1, y: -1)
    static let downLeft = Offset(x: -1, y: 1)
    static let downRight = Offset(x: 1, y: 1)
}
