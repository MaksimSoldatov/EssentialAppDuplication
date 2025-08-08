//
// RemoteFeedLoader.swift created 31.03.25.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(data: Data, response: HTTPURLResponse), Swift.Error>
    
    func get(from url: URL, completion: @escaping (Result) -> Void)
}

public final class RemoteFeedLoader: FeedLoader {
    
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        client.get(from: url, completion: { [weak self] (result: HTTPClient.Result) in
            guard self != nil else { return }
            switch result {
            case let .success((data, response)):
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }
        })
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> FeedLoader.Result {
        do {
            let items = try FeedItemsMapper.map(data, response: response)
            return .success(items.toModels())
        } catch {
            return .failure(.invalidData)
        }
    }
}

extension HTTPURLResponse {
    var OK_200: Bool {
        statusCode == 200
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        map({ FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image)})
    }
}
