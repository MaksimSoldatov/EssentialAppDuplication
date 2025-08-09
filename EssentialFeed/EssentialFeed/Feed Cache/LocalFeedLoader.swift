//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Maxim Soldatov on 8.08.25.
//

import Foundation

public final class LocalFeedLoader {
    
    public typealias SaveResult = (Result<Void, Error>) -> Void
    public typealias RetrieveResult = (Result<[FeedImage], Error>) -> Void
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore,
                currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping SaveResult) {
        store.deleteCacheFeed() { [weak self] result in
            guard let self else { return }
            switch result {
            case .success():
                cache(feed, with: completion)
            case .failure(let deletionError):
                completion(.failure(deletionError))
            }
        }
    }
    
    public func load(completion: @escaping RetrieveResult) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success((feed, timestamp)) where CachePolicy.isValid(timestamp, against: currentDate()):
                completion(.success(feed.toModel()))
            case let .failure(error):
                cleanCache()
                completion(.failure(error))
            case .success:
                cleanCache()
                completion(.success([]))
            }
        }
    }
   
    private func cleanCache() {
        store.deleteCacheFeed { _ in }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping SaveResult) {
        store.insert(feed.toLocal(),
                     timestamp: currentDate(),
                     completion: { [weak self] result in
            guard self != nil else { return }
            completion(result)
        })
    }
}

private extension LocalFeedLoader {
    struct CachePolicy {
        private static let maxCacheAgeInDays: Int = 7
        static func isValid(_ timestamp: Date, against date: Date) -> Bool {
            guard let maxCacheAge = Calendar.current.date(byAdding: .day,
                                                          value: maxCacheAgeInDays,
                                                          to: timestamp) else {
                return false
            }
            return date < maxCacheAge
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map({ LocalFeedImage(id: $0.id,
                            description: $0.description,
                            location: $0.location,
                            url: $0.url) })
    }
}

private extension Array where Element == LocalFeedImage {
    func toModel() -> [FeedImage] {
        map({ FeedImage(id: $0.id,
                        description: $0.description,
                        location: $0.location,
                        url: $0.url) })
    }
}
