import Foundation
import SwiftUI

enum Badge: Int16, Identifiable, CaseIterable {
    case correct = 0
    case wrong = 1
    
    var id: Badge { self }
    
    var displayName: String {
        switch self {
        case .correct: "Correct"
        case .wrong: "Wrong"
        }
    }
    
    var imageName: String {
        switch self {
        case .correct: "checkmark.circle.fill"
        case .wrong: "xmark.circle.fill"
        }
    }
}
