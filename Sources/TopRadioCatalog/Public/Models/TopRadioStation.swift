import Foundation

/// Brand-level station: a web card and/or city locals sharing the same `slug`.
public struct TopRadioStation: Identifiable, Hashable, Sendable {
    public var id: String { slug }

    public let slug: String
    public let title: String
    public let web: WebStation?
    public let locals: [CityStation]
    public let votes: Int?
    public let genres: [String]
    public let citySlugs: [String]
    public let countrySlugs: [String]

    public init(
        slug: String,
        title: String,
        web: WebStation?,
        locals: [CityStation],
        votes: Int?,
        genres: [String],
        citySlugs: [String],
        countrySlugs: [String]
    ) {
        self.slug = slug
        self.title = title
        self.web = web
        self.locals = locals
        self.votes = votes
        self.genres = genres
        self.citySlugs = citySlugs
        self.countrySlugs = countrySlugs
    }
}
