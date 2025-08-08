//
// RemoteFeedLoader.swift created 31.03.25.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(data: Data, response: HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
    
    func get(from url: URL) async throws -> (data: Data, response: HTTPURLResponse)
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
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data, response: response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
    
    public func load() async throws -> [FeedItem] {
        
        guard let result = try? await client.get(from: url) else {
            throw RemoteFeedLoader.Error.connectivity
        }

        if let items = try? FeedItemsMapper.throwsMap(result.data, response: result.response) {
            return items
        } else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
    }
}

extension HTTPURLResponse {
    var OK_200: Bool {
        statusCode == 200
    }
}

