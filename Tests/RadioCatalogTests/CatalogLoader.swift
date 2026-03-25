import Foundation
import RadioCatalog

public enum CatalogLoader {
    public static func load() throws -> [Station] {
        guard let url = Bundle.module.url(forResource: "stations", withExtension: "json") else {
            fatalError()
        }
        
        let data = try Data(contentsOf: url)

        let stations = try JSONDecoder().decode([Station].self, from: data)

        return stations
    }
}
