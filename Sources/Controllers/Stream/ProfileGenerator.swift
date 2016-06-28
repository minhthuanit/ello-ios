public final class ProfileGenerator: StreamGenerator {

    public let currentUser: User?
    public var streamKind: StreamKind
    public var destination: StreamDestination

    private var user: User?
    private let userParam: String
    private var userPostItems = [StreamCellItem]()
    private var parser = StreamCellItemParser()

    func headerItems() -> [StreamCellItem] {
        guard let user = user else { return [] }

        return [
            StreamCellItem(jsonable: user, type: .ProfileHeader),
            StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 3)),
            StreamCellItem(jsonable: user, type: .ColumnToggle),
            StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 5))
        ]
    }

    public var items: [StreamCellItem] {
        get {
            return [
                headerItems(),
                userPostItems
            ].flatMap { $0 }
        }
    }

    init(currentUser: User?,
         userParam: String,
         user: User?,
         streamKind: StreamKind,
         destination: StreamDestination
        ) {
        self.currentUser = currentUser
        self.user = user
        self.userParam = userParam
        self.streamKind = streamKind
        self.destination = destination
    }

    public func bind() {
        setInitialUser()
        loadUser()
        loadUserPosts()
    }

}

private extension ProfileGenerator {
    func setInitialUser() {
        guard let user = user else { return }

        destination.setPrimaryJSONAble(user)
        destination.setItems(items)
    }

    func loadUser() {
        // load the user with no posts
        StreamService().loadUser(
            streamKind.endpoint,
            streamKind: streamKind,
            success: { (user, responseConfig) in
                self.user = user
                self.destination.setPagingConfig(responseConfig)
                self.destination.setPrimaryJSONAble(user)
                self.destination.setItems(self.items)
            },
            failure: { _ in
                self.destination.primaryJSONAbleNotFound()
        })
    }

    func loadUserPosts() {
        StreamService().loadUserPosts(
            userParam,
            success: { (posts, responseConfig) in
                self.userPostItems = self.parse(self.parser, jsonables: posts)
                self.destination.setItems(self.items)
            },
            failure: { _ in
                self.destination.primaryJSONAbleNotFound()
        })
    }
}
