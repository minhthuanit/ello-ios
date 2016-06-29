public final class ProfileGenerator: StreamGenerator {

    public let currentUser: User?
    public var streamKind: StreamKind
    weak public var destination: StreamDestination?

    private var user: User?
    private let userParam: String

    func headerItems() -> [StreamCellItem] {
        guard let user = user else { return [] }

        return [
            StreamCellItem(jsonable: user, type: .ProfileHeader),
            StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 3)),
            StreamCellItem(jsonable: user, type: .ColumnToggle),
            StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 5))
        ]
    }

    init(currentUser: User?,
         userParam: String,
         user: User?,
         streamKind: StreamKind,
         destination: StreamDestination?
        ) {
        self.currentUser = currentUser
        self.user = user
        self.userParam = userParam
        self.streamKind = streamKind
        self.destination = destination
    }

    public func bind() {
        destination?.setPlaceholders([
            StreamCellItem(type: .Placeholder(.ProfileHeader)),
            StreamCellItem(type: .Placeholder(.ProfilePosts)),
        ])

        setInitialUser()
        loadUser()
        loadUserPosts()
    }

}

private extension ProfileGenerator {
    func setInitialUser() {
        guard let user = user else { return }

        destination?.setPrimaryJSONAble(user)
        destination?.replacePlaceholder(.ProfileHeader, items: headerItems())
    }

    func loadUser() {
        // load the user with no posts
        StreamService().loadUser(
            streamKind.endpoint,
            streamKind: streamKind,
            success: { [weak self] (user, responseConfig) in
                guard let sself = self else { return }
                sself.user = user
                sself.destination?.setPagingConfig(responseConfig)
                sself.destination?.setPrimaryJSONAble(user)
                sself.destination?.replacePlaceholder(.ProfileHeader, items: sself.headerItems())
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
        })
    }

    func loadUserPosts() {
        StreamService().loadUserPosts(
            userParam,
            success: { [weak self] (posts, responseConfig) in
                guard let sself = self else { return }
                let userPostItems = sself.parse(posts)
                sself.destination?.replacePlaceholder(.ProfilePosts, items: userPostItems)
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
        })
    }
}
