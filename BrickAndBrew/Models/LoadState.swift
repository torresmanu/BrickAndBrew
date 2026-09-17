import Foundation

enum LoadState<Value: Sendable>: Sendable {
    case loading
    case loaded(Value)
    case empty
    case failed(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
