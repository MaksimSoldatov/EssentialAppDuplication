//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Maxim Soldatov on 10.08.25.
//

import Foundation

public final class CodableFeedStore: FeedStore {
    
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func deleteCachedFeed(_ completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(.success(()))
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, _ completion: @escaping InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func retrieve(_ completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.success(([], nil)))
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.success((cache.localFeed, cache.timestamp)))
        } catch {
            completion(.failure(error))
        }
    }
    
    private struct CodableFeedImage: Codable {
        
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
    }
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map({ $0.local })
        }
    }
}
