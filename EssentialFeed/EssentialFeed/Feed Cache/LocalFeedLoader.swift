//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Maxim Soldatov on 8.08.25.
//

import Foundation

public final class LocalFeedLoader {
    
    public typealias SaveResult = (Result<Void, Error>) -> Void
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore,
                currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping SaveResult) {
        store.deleteCacheFeed() { [weak self] result in
            guard let self else { return }
            switch result {
            case .success():
                cache(items, with: completion)
            case .failure(let deletionError):
                completion(.failure(deletionError))
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping SaveResult) {
        store.insert(items, timestamp: currentDate(), completion: { [weak self] result in
            guard self != nil else { return }
            completion(result)
        })
    }
}
