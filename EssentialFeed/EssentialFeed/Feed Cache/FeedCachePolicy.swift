//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Maxim Soldatov on 9.08.25.
//

import Foundation

enum FeedCachePolicy {
    
    private static let maxCacheAgeInDays: Int = 7
    
    static func isValid(_ timestamp: Date?, against date: Date) -> Bool {
        guard let timestamp = timestamp else { return false }
        guard let maxCacheAge = Calendar.current.date(byAdding: .day,
                                                      value: maxCacheAgeInDays,
                                                      to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
