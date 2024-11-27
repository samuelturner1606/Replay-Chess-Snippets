@Observable
final class Theme {
    var whiteOutline: Bool
    var blackOutline: Bool
    
    var whitePrimary: Color
    var whiteSecondary: Color
    var whiteTertiary: Color
    
    var blackPrimary: Color
    var blackSecondary: Color
    var blackTertiary: Color
    
    var lightSquare: Color
    var darkSquare: Color
    var highlightSquare: Color
    
    var correctBadge: Color
    var wrongBadge: Color
    
    func badgeColor(_ badge: Badge) -> Color {
        switch badge {
        case .correct: correctBadge
        case .wrong: wrongBadge
        }
    }
    
    init() {
        let userDefaults = UserDefaults.standard
        userDefaults.register(
            defaults: [
                "whiteOutline" : true,
                "blackOutline" : false,
                
                "whitePrimary" : Color.white.encodedData,
                "whiteSecondary" : Color(white: 0.2).encodedData,
                "whiteTertiary" : Color.white.encodedData,
                
                "blackPrimary" : Color.black.encodedData,
                "blackSecondary" : Color.white.opacity(0.2).encodedData,
                "blackTertiary" : Color.red.opacity(0.8).encodedData,
                
                "lightSquare" : Color(.displayP3, red: 210/255, green: 239/255, blue: 253/255).encodedData,
                "darkSquare" : Color(.displayP3, red: 120/255, green: 160/255, blue: 248/255).encodedData,
                "highlightSquare" : Color.pink.opacity(0.7).encodedData,
                
                "correctBadge" : Color.green.encodedData,
                "wrongBadge" : Color.red.encodedData
            ]
        )
        
        whiteOutline = userDefaults.bool(forKey: "whiteOutline")
        blackOutline = userDefaults.bool(forKey: "blackOutline")
        
        whitePrimary = userDefaults.data(forKey: "whitePrimary")!.decodedColor
        whiteSecondary = userDefaults.data(forKey: "whiteSecondary")!.decodedColor
        whiteTertiary = userDefaults.data(forKey: "whiteTertiary")!.decodedColor
        
        blackPrimary = userDefaults.data(forKey: "blackPrimary")!.decodedColor
        blackSecondary = userDefaults.data(forKey: "blackSecondary")!.decodedColor
        blackTertiary = userDefaults.data(forKey: "blackTertiary")!.decodedColor
        
        lightSquare = userDefaults.data(forKey: "lightSquare")!.decodedColor
        darkSquare = userDefaults.data(forKey: "darkSquare")!.decodedColor
        highlightSquare = userDefaults.data(forKey: "highlightSquare")!.decodedColor
        
        correctBadge = userDefaults.data(forKey: "correctBadge")!.decodedColor
        wrongBadge = userDefaults.data(forKey: "wrongBadge")!.decodedColor
    }
    
    func reset() {
        whiteOutline = true
        blackOutline = false
        
        whitePrimary = Color.white
        whiteSecondary = Color(white: 0.2)
        whiteTertiary = Color.white
        
        blackPrimary = Color.black
        blackSecondary = Color.white.opacity(0.2)
        blackTertiary = Color.red.opacity(0.8)
        
        lightSquare = Color(.displayP3, red: 210/255, green: 239/255, blue: 253/255)
        darkSquare = Color(.displayP3, red: 120/255, green: 160/255, blue: 248/255)
        highlightSquare = Color.pink.opacity(0.7)
        
        correctBadge = Color.green
        wrongBadge = Color.red
    }
    
    func save() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(whiteOutline, forKey: "whiteOutline")
        userDefaults.set(blackOutline, forKey: "blackOutline")
        
        userDefaults.set(whitePrimary.encodedData, forKey: "whitePrimary")
        userDefaults.set(whiteSecondary.encodedData, forKey: "whiteSecondary")
        userDefaults.set(whiteTertiary.encodedData, forKey: "whiteTertiary")
        
        userDefaults.set(blackPrimary.encodedData, forKey: "blackPrimary")
        userDefaults.set(blackSecondary.encodedData, forKey: "blackSecondary")
        userDefaults.set(blackTertiary.encodedData, forKey: "blackTertiary")
        
        userDefaults.set(lightSquare.encodedData, forKey: "lightSquare")
        userDefaults.set(darkSquare.encodedData, forKey: "darkSquare")
        userDefaults.set(highlightSquare.encodedData, forKey: "highlightSquare")
        
        userDefaults.set(correctBadge.encodedData, forKey: "correctBadge")
        userDefaults.set(wrongBadge.encodedData, forKey: "wrongBadge")
    }
    
}

extension Color {
    var encodedData: Data {
        try! JSONEncoder().encode(self.resolve(in: EnvironmentValues()))
    }
}

extension Data {
    var decodedColor: Color {
        return Color(try! JSONDecoder().decode(Color.Resolved.self, from: self))
    }
}
