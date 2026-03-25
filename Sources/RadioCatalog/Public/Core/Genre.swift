import Foundation

/// Основные жанры.
/// Минимально достаточный набор для нормализации.
public enum Genre: String, CaseIterable, Codable, Sendable {
    // Rock & Metal
    case rock
    case metal
    case punk
    case alternative
    
    // Electronic
    case electronic
    case house
    case trance
    case techno
    case dance
    case dubstep
    case drumAndBass = "drum-and-bass"
    case ambient
    case chillout
    
    // Pop
    case pop
    case indie
    case synthpop
    
    // Urban
    case hipHop = "hip-hop"
    case rnb
    case soul
    case funk
    case reggae
    case dancehall
    
    // Jazz & Blues
    case jazz
    case blues
    
    // World & Folk
    case folk
    case world
    case ethnic
    case celtic
    case latin
    case afro
    case reggaeton
    
    // Classical & Instrumental
    case classical
    case instrumental
    case soundtrack
    
    // Country
    case country
    case americana
    
    // Vocal & Easy Listening
    case vocal
    case easyListening = "easy-listening"
    case lounge
    
    case jPop = "j-pop"
    case kPop = "k-pop"
    
    // Miscellaneous
    case experimental
    case industrial
    case disco
    case retro
    case variety
    
    case salsa
    case bachata
    case flamenco
    case tango
    case samba
    
}

extension Genre: Comparable {
    public static func < (lhs: Genre, rhs: Genre) -> Bool {
        lhs.rawValue.caseInsensitiveCompare(rhs.rawValue) == .orderedAscending
    }
}

extension Genre: CustomStringConvertible {
    public var description: String {
        "\(rawValue)"
    }
}
