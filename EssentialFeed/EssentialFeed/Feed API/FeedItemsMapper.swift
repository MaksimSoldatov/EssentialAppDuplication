//
// FeedItemsMapper.swift created 13.05.25.
//
import Foundation

enum FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    static func map(_ data: Data, response: HTTPURLResponse) -> FeedLoader.Result {
        guard response.OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        let items = root.items.compactMap({ $0.item })
        return .success(items)
    }
    
    static func throwsMap(_ data: Data, response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return try JSONDecoder().decode(Root.self, from: data).items.compactMap({ $0.item })
    }
}
