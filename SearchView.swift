import SwiftUI
import CoreData
import TipKit

extension Sequence<Chessboard> {
    func filterBoards(with pieces: [Piece]) -> [Chessboard] {
        let pieceTokens = Set( pieces.map { $0.description })
        return filter { board in
            board.isSupersetOf(pieceTokens: pieceTokens)
        }
    }
}

struct SearchView: View {
    @Bindable var tabController: TabController
    @State private var comment = ""
    @State private var pieces: [Piece] = []
    
    @FetchRequest(fetchRequest: Chessboard.allComments)
    private var boards: FetchedResults<Chessboard>
    
    private let tokensTip = TokensTip()
    
    var body: some View {
        NavigationStack(path: $tabController.searched) {
            TipView(tokensTip, arrowEdge: .top)
            
            let filteredBoards = boards.filterBoards(with: pieces)
            
            List(filteredBoards) { board in
                let game = Game(board: board)
                NavigationLink(value: game) {
                    ThumbnailView(game: game)
                }
            }
            .navigationDestination(for: Game.self) { game in
                GameView(game: game)
            }
            
        }
        .onChange(of: comment) {
            if let match = comment.firstMatch(of: /(?<chessman>[♙♘♗♖♕♔♟♞♝♜♛♚PNBRQKpnbrqk])(?<file>[a-hA-H])(?<rank>[1-8])/) {
                let piece = Piece(match: match)!
                pieces.append(piece)
                comment.removeSubrange(match.range)
                tokensTip.invalidate(reason: .actionPerformed)
            }
        }
        .searchable(
            text: $comment,
            tokens: $pieces,
            placement: .navigationBarDrawer,
            prompt: "Comments, moves and positions"
        ) { token in
            Label {
                Text(token.square.description)
            } icon: {
                Image("\(token.role)")
                    .symbolVariant(token.colour == .white ? .none : .fill)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) {
            boards.nsPredicate = Chessboard.search(comment: comment, pieces: pieces)
        }
    }
}

extension Chessboard {
    
    @MainActor
    static let allComments: NSFetchRequest<Chessboard> = {
        let request = NSFetchRequest<Chessboard>(entityName: "Chessboard")
        request.fetchBatchSize = 100
        //request.relationshipKeyPathsForPrefetching = ["parent"]
        request.predicate = NSPredicate(format: "comment != ''")
        request.sortDescriptors = [NSSortDescriptor(key: "visited", ascending: true)]
        return request
    }()
    
    @nonobjc class func search(comment: String, pieces: [Piece]) -> NSPredicate {
        switch (comment.isEmpty, pieces.isEmpty) {
        case (true, true):
            NSPredicate(format: "comment != ''")
        case (true, false):
            NSCompoundPredicate(
                type: .or,
                subpredicates: pieces.map { NSPredicate(format: "pieces CONTAINS %@" , $0.description) }
            )
        case(false, _):
            NSPredicate(format: "comment CONTAINS[cd] %@", comment)
        }
    }
    
    func isSupersetOf(pieceTokens: Set<String>) -> Bool {
        if pieceTokens.isEmpty {
            true
        } else if pieceTokens.isSubset(of: tokens) {
            true
        } else if pieceTokens.isSubset(of: positionTokens) {
            true
        } else {
            false
        }
    }
    
}

struct TokensTip: Tip {
    var title: Text {
        Text("Enter piece tokens")
    }
    
    var message: Text? {
        Text("For example, the tokens \"Pe4 pe6\" will search for all your french defense positions.")
    }
    
    var image: Image? {
        Image(systemName: "magnifyingglass")
    }
}
