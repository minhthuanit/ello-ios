import Foundation

public protocol StreamGenerator {

    func bind()

    var currentUser: User? { get }
    var streamKind: StreamKind { get }
    var destination: StreamDestination? { get }
}

extension StreamGenerator {

    func parse(jsonables: [JSONAble]) -> [StreamCellItem] {
        return StreamCellItemParser().parse(jsonables, streamKind: self.streamKind, currentUser: self.currentUser)
    }
}

public protocol StreamDestination: class {
    func setPlaceholders(items: [StreamCellItem])
    func replacePlaceholder(type: StreamCellType.PlaceholderType, @autoclosure items: () -> [StreamCellItem])
    func setPrimaryJSONAble(jsonable: JSONAble)
    func primaryJSONAbleNotFound()
    func setPagingConfig(responseConfig: ResponseConfig)
}
