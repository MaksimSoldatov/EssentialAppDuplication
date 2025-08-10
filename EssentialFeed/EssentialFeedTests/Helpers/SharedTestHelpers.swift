//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Maxim Soldatov on 9.08.25.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}
