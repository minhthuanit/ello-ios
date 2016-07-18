////
///  LoadingToken.swift
//

import Foundation

public struct LoadingToken {
    private var loadInitialPageLoadingToken: String = ""
    public var cancelLoadingClosure: ElloEmptyCompletion = {}

    public mutating func resetInitialPageLoadingToken() -> String {
        let newToken = NSUUID().UUIDString
        loadInitialPageLoadingToken = newToken
        return newToken
    }

    public func isValidInitialPageLoadingToken(token: String) -> Bool {
        return loadInitialPageLoadingToken == token
    }

    public mutating func cancelInitialPage() {
        resetInitialPageLoadingToken()
        self.cancelLoadingClosure()
    }
}
