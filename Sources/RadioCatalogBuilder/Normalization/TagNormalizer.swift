import Foundation
import RadioCatalog

/// Главный нормализатор.
/// Обрабатывает name + tags.
public enum TagNormalizer {

    /// Публичная точка входа
    public static func normalize(name: String, tags: String) -> NormalizedTags {
        var result = NormalizedTags()

        let combined = name + " " + tags
        let tokens = Tokenizer.tokenize(combined)

        for raw in tokens {
            let token = normalizeToken(raw)

            if StopWords.stopWords.contains(token) {
                continue
            }
            
            if let decade = parseDecade(token) {
                result.decades.insert(decade)
                continue
            }

            if let format = parseFormat(token, full: combined) {
                result.formats.insert(format)
                continue
            }

            if let genre = parseGenre(token) {
                result.genres.insert(genre)
                continue
            }

            if token.count > 2 {
                result.misc.insert(token)
            }
        }

        return result
    }
}

enum StopWords {
    // Стоп-лист (мусорные слова)
    static let stopWords: Set<String> = [
        // Технические термины
        "fm", "am", "radio", "stream", "online", "digital", "hd", "aac", "mp3",
        "kbps", "bitrate", "live", "web", "net", "tv", "channel", "station",
        "network", "broadcast",
        
        // Единицы измерения и форматы
        "hz", "khz", "mhz", "kbit", "kbit/s", "kbps", "bit", "bps", "mbps",
        "mp3", "aac", "aac+", "ogg", "flac", "wma", "wav", "m3u", "pls", "asx",
        "xspf", "stream", "live", "webcast", "podcast",
        
        // Общие слова на разных языках
        "radio",
        "station", "estación", "estacao", "sender", "chaîne", "canal", "kanal",
        "kanál", "csatorna", "kanal", "kanāls", "kanalas",
        "online",
        "streaming", "stream",
        "music", "musica", "música", "musique", "musik", "muzyka",
        "muziek", "musica", "müzik",
        
        // Бренды и сети
        "npr", "bbc", "iheart", "iheartradio", "mvs", "exa", "kiss", "hit",
        "energy", "nrj", "rtl", "rtv", "tv", "tele", "televisa", "azteca",
        "radio formula", "w radio", "imagen", "milenio", "elfm", "skyrock",
        "virgin", "capital", "heart", "smooth", "magic", "absolute",
        
        // Компании и группы
        "grupo", "group", "groupo", "acir", "radiorama", "multimedios",
        "nrm comunicaciones", "mvs radio", "cadena", "corporación",
        "comunicaciones", "comunicación", "medios", "prensa",
        
        // Технические термины на разных языках
        "kbit", "kbps", "bitrate", "calidad", "quality", "qualité", "qualität",
        "128", "192", "256", "320", "64", "32", "24", "16", "8",
        "stereo", "mono", "dolby", "surround", "hifi", "hi-fi",
        
        // Разделители и служебные символы
        "#", "##", "###", "@", "&", "-", "_", "/", "\\", "|", "•", "·",
        "...", "..", ".", ",", ";", ":", "!", "?", "(", ")", "[", "]",
        "{", "}", "<", ">", "+", "=", "*", "^", "%", "$", "€", "£", "¥",
        
        // Пустые строки и одиночные символы
        "", " ", "  ", "   ", "null", "nil", "none", "undefined",
        "test", "prueba", "testing", "demo", "sample", "ejemplo",
        
        // Интернет-протоколы
        "http", "https", "ftp", "sftp", "rtmp", "rtsp", "mms", "mmsh",
        "icecast", "shoutcast", "stream", "livestream",
        
        // Расширения файлов
        ".pls", ".m3u", ".asx", ".xspf", ".ram", ".smil", ".mp3", ".aac",
        ".ogg", ".flac", ".wma", ".wav", ".aiff", ".ape", ".m4a", ".m4b",
        
        // Случайные слова из логов
        "added by", "via", "from", "using", "with", "by", "for", "and", "or",
        "the", "of", "in", "on", "at", "to", "from", "with", "without",
        
        // Форматы вещания
        "public", "publica", "pública", "commercial", "comercial", "non-commercial",
        "no comercial", "sin fines de lucro", "community", "comunitaria",
        "universidad", "university", "college", "campus", "student",
        
        // Типы контента (если не нужны как жанр)
        "talk", "hablada", "spoken", "news", "noticias", "sports", "deportes",
        "comedy", "humor", "information", "informacion", "cultura", "culture",
        
        // Временные метки
        "now", "today", "yesterday", "tomorrow", "live", "directo", "envivo",
        "en vivo", "en directo", "en ligne", "online", "streaming",
        
        // Социальные сети
        "facebook", "twitter", "instagram", "youtube", "tiktok", "snapchat",
        "whatsapp", "telegram", "discord", "twitch", "spotify", "apple music",
        "deezer", "tidal", "amazon music", "google play", "yandex music",
        
        // Рекламные
        "ad", "ads", "publicidad", "propaganda", "sponsor", "patrocinio",
        "promo", "promocion", "comercial", "spot",
        
        // Ошибки и опечатки
        "musicaa", "musikc", "musiс", "muisc", "musc", "musik", "muzic",
        "rockk", "rockc", "rok", "roc", "rokc", "popo", "popp", "poop",
        "classica", "clasicaa", "clasic", "clasik", "clazz", "jazzc",
        "electonica", "electronicaa", "elektronica", "electronicc",
        
        // HTML и URL
        "html", "htm", "php", "asp", "jsp", "cgi", "pl", "cgi-bin",
        "index", "default", "home", "main", "page", "site", "website",
        "www", "web", "url", "link", "domain", "host", "server",
        
        // Пустые строки и NULL
        "", " ", "  ", "null", "nil", "none", "undefined", "unknown",
        "test", "prueba", "demo", "sample", "ejemplo", "example",
        
        // Специальные символы
        "#", "##", "###", "@", "&", "-", "_", "/", "\\", "|", "•", "·",
        "...", "..", ".", ",", ";", ":", "!", "?", "(", ")", "[", "]",
        "{", "}", "<", ">", "+", "=", "*", "^", "%", "$", "€", "£", "¥",
        
        // Числа и даты
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "2020", "2021", "2022", "2023", "2024", "2025", "2026", "2027",
        "24", "24/7", "24h", "24hs", "24hrs", "365",
        
        // Пустые строки и одиночные символы
        "", " ", "  ", "   ", "null", "nil", "none", "undefined",
        "test", "prueba", "testing", "demo", "sample", "ejemplo",
    ]
}

// MARK: - Token normalize

private extension TagNormalizer {

    static func normalizeToken(_ token: String) -> String {
        Transliteration.latin(token)
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Decades

private extension TagNormalizer {

    static func parseDecade(_ token: String) -> Decade? {
        // 1980s
        if let year = Int(token.prefix(4)), (1930...2020).contains(year) {
            return Decade(rawValue: (year / 10) * 10)
        }

        // 80s / 80 / 80е / 80er
        if let num = Int(token.prefix(2)) {
            switch num {
            case 30: return .y1930
            case 40: return .y1940
            case 50: return .y1950
            case 60: return .y1960
            case 70: return .y1970
            case 80: return .y1980
            case 90: return .y1990
            default: break
            }
        }

        return nil
    }
}

// MARK: - Formats

private extension TagNormalizer {

    static func parseFormat(_ token: String, full: String) -> StationFormat? {

//        if full.contains("news talk") {
//            return .talkNews
//        }

        switch token {
        case "news": return .news
        case "talk": return .talk
        case "music": return .music
        case "public": return full.contains("public radio") ? .publicRadio : nil
        case "traffic": return .traffic
        case "comedy": return .comedy
        case "sport", "sports": return .sports
        case "christian", "religious": return .religious
        default: return nil
        }
    }
}

// MARK: - Genres

private extension TagNormalizer {

    static func parseGenre(_ token: String) -> Genre? {
        let genreAliases: [String: Genre] = [
            "hardrock": .rock,
            "hiphop": .hipHop,
            "r&b": .rnb,
            "ethno": .ethnic,
            "electonica": .electronic
        ]
        
        if let exact = Genre(rawValue: token) {
            return exact
        }

        if let alias = genreAliases[token] {
            return alias
        }

        return nil
    }
    
//    static func parseGenre(_ token: String) -> Genre? {
//
//        guard !token.isEmpty else { return nil }
//        
//        if let exact = Genre(rawValue: token) {
//            return exact
//        }
//
//        if let alias = genreAliases[token] {
//            return alias
//        }
//
//        guard token.count > 4 else { return nil }
//        
//        // fuzzy
//        for g in Genre.allCases {
//            let dist = Levenshtein.distance(token, g.rawValue)
//            let threshold = token.count <= 5 ? 1 : 2
//
//            if dist <= threshold {
//                return g
//            }
//        }
//
//        return nil
//    }
}
