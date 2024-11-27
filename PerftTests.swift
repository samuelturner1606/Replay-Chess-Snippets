import XCTest
@testable import ReplayChess
import CoreData

fileprivate extension Game {
    /// A Depth-Limited Search algorithm helpful in debugging the move generator.
    /// - Parameters:
    ///   - depth: Maximum number of move plies.
    ///   - divide: Displays the legal moves at depth 1 and their total number of child moves.
    /// - Returns: The total number of legal moves possible from the starting position.
    func perft(depth: Int, divide: Bool = false, context: NSManagedObjectContext) -> UInt {
        if depth == 0 {
            return 1
        } else {
            var total: UInt = 0
            for var move in moves {
                
                func f() {
                    play(move: move, context: context)
                    let n = perft(depth: depth - 1, context: context)
                    if divide {
                        print(move.description, n)
                    }
                    total += n
                    backward()
                }
                
                if move.promoting { // UI handles promotions but perft needs it
                    for promotion in Role.promotions {
                        move.p2.role = promotion
                        f()
                    }
                } else {
                    f()
                }
            }
            return total
        }
    }
}

final class PerftTests: XCTestCase {
    
    /// Depth | Nodes    | Captures | Checks | Mates
    /// -------- | ----------- | ------------ | ----------- | --------
    /// 4        | 197,281 |     1576   |     469    |     8
    func testStart() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let board = Chessboard(context: context, pieces: Chessboard.startPosition)
        let game = Game(board: board)
        let result = game.perft(depth: 4, divide: true, context: context)
        XCTAssertEqual(result, 197_281)
    }

    /// position fen r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1
    /// Depth | Nodes | Captures | En Passant | Castles | Checks | Mates
    /// -------- | --------- | ------------ | --------------- | ---------- | ---------- | --------
    /// 3        | 97,862 |   17102    |       45        |   3162    |   993     |    1
    func testPosition2() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let board = Chessboard(context: context, pieces: "♜h8♟h3♝g7♟g6♟f7♞f6♚e8♛e7♟e6♟d7♟c7♞b6♟b4♜a8♟a7♝a6♙h2♖h1♙g2♕f3♙f2♘e5♙e4♗e2♔e1♙d5♗d2♘c3♙c2♙b2♙a2♖a1")
        let game = Game(board: board)
        let result = game.perft(depth: 3, divide: true, context: context)
        XCTAssertEqual(result, 97_862)
    }
    
    /// position fen 8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1
    /// Depth | Nodes | Captures | En Passant | Checks | Discoverd Checks | Mates
    /// -------- | --------- | ------------ | --------------- | ---------- | ------------------------ | --------
    /// 4        | 43,238  |   3348     |     123        |   1680   |            106             |    17
    func testPosition3() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let board = Chessboard(context: context, pieces: "♜h5♚h4♟f4♟d6♟c7♙g2♙e2♙b5♖b4♔a5")
        let game = Game(board: board)
        let result = game.perft(depth: 4, divide: true, context: context)
        XCTAssertEqual(result, 43_238)
    }
    
    /// position fen r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1
    /// Depth | Nodes    | Captures  | Castles | Promotions | Checks | Mates
    /// -------- | ----------- | ------------- | ---------- | --------------- | ---------- | --------
    /// 4         | 422,333 |   131393  |   7795   |     60032     |  15492  |    5
    func testPosition4() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let board = Chessboard(context: context, pieces: "♜h8♟h7♟g7♝g6♟f7♞f6♚e8♟d7♟c7♟b7♝b6♟b2♜a8♞a5♛a3♘h6♙h2♙g2♔g1♘f3♖f1♙e4♙d2♕d1♙c4♙b5♗b4♙a7♗a4♙a2♖a1")
        let game = Game(board: board)
        let result = game.perft(depth: 4, divide: true, context: context)
        XCTAssertEqual(result, 422_333)
    }
    
    /// position fen rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8
    /// Depth | Nodes
    /// -------- | ---------
    /// 3        | 62,379
    func testPosition5() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let board = Chessboard(context: context, pieces: "♜h8♟h7♟g7♚f8♟f7♞f2♝e7♛d8♝c8♟c6♞b8♟b7♜a8♟a7♙h2♖h1♙g2♘e2♔e1♙d7♕d1♗c4♙c2♗c1♙b2♘b1♙a2♖a1")
        let game = Game(board: board)
        let result = game.perft(depth: 3, divide: true, context: context)
        XCTAssertEqual(result, 62_379)
    }
}
