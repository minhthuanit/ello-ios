import Foundation

public protocol StreamGenerator {

    mutating func bind()

    var items: [StreamCellItem] { get }
    var currentUser: User? { get }
    var streamKind: StreamKind { get }
    var destination: StreamDestination { get }
}

extension StreamGenerator {

    func parse(jsonables: [JSONAble]) -> [StreamCellItem] {
        return StreamCellItemParser().parse(jsonables, streamKind: self.streamKind, currentUser: self.currentUser)
    }
}

public protocol StreamDestination {
    func setItems(items: [StreamCellItem])
    func setPrimaryJSONAble(jsonable: JSONAble)
    func primaryJSONAbleNotFound()
    func setPagingConfig(responseConfig: ResponseConfig)
}
