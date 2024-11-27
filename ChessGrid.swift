import SwiftUI

struct ChessGrid: Layout {
    let viewing: Colour
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions()
        let min = min(size.width, size.height) / 1.2 // 1.2 is based on svg images
        return CGSize(width: min, height: min)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let length = bounds.width / 8
        for subview in subviews {
            if let square = subview[Square.self] {
                
                var x = square.file.x
                var y = square.rank.y
                var size = ProposedViewSize(width: length, height: length)
                
                if viewing == .black {
                    x = 8 - x
                    y = 8 - y
                }
                
                if subview[BadgeKey.self] {
                    x += 0.4
                    y -= 0.4
                    size = .init(width: length / 2, height: length / 2)
                }
                
                subview.place(
                    at: CGPoint(
                        x: x * length + bounds.minX,
                        y: y * length + bounds.minY
                    ),
                    anchor: .center,
                    proposal: size
                )
            }
        }
    }
}
