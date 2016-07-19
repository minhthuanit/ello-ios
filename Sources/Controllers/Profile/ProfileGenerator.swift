////
///  ProfileGenerator.swift
//

public final class ProfileGenerator: StreamGenerator {

    public var currentUser: User?
    public var streamKind: StreamKind
    weak public var destination: StreamDestination?

    private var user: User?
    private let userParam: String
    private var posts: [Post]?
    private var localToken: String!
    private var loadingToken = LoadingToken()

    private let queue = NSOperationQueue()

    func headerItems() -> [StreamCellItem] {
        guard let user = user else { return [] }

        return [
            StreamCellItem(jsonable: user, type: .ProfileHeader),
            StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 3)),
            StreamCellItem(jsonable: user, type: .ColumnToggle),
            StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 5))
        ]
    }

    public init(currentUser: User?,
         userParam: String,
         user: User?,
         streamKind: StreamKind,
         destination: StreamDestination?
        ) {
        self.currentUser = currentUser
        self.user = user
        self.userParam = userParam
        self.streamKind = streamKind
        self.localToken = loadingToken.resetInitialPageLoadingToken()
        self.destination = destination
    }

    public func load(reload reload: Bool = false) {
        let doneOperation = AsyncOperation()
        queue.addOperation(doneOperation)

        localToken = loadingToken.resetInitialPageLoadingToken()
        setPlaceHolders()
        setInitialUser(doneOperation)
        loadUser(doneOperation, reload: reload)
        loadUserPosts(doneOperation)
    }

    public func toggleGrid() {
        guard let posts = posts else { return }
        destination?.replacePlaceholder(.ProfilePosts, items: parse(posts))
    }

}

private extension ProfileGenerator {

    func setPlaceHolders() {
        destination?.setPlaceholders([
            StreamCellItem(type: .Placeholder, placeholderType: .ProfileHeader),
            StreamCellItem(type: .Placeholder, placeholderType: .ProfilePosts)
        ])
    }

    func setInitialUser(doneOperation: AsyncOperation) {
        guard let user = user else { return }

        destination?.setPrimaryJSONAble(user)
        destination?.replacePlaceholder(.ProfileHeader, items: headerItems())
        doneOperation.run()
    }

    func loadUser(doneOperation: AsyncOperation, reload: Bool = false) {
        guard !doneOperation.finished || reload else { return }

        // load the user with no posts
        StreamService().loadUser(
            streamKind.endpoint,
            streamKind: streamKind,
            success: { [weak self] (user, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                sself.user = user
                sself.destination?.setPrimaryJSONAble(user)
                sself.destination?.replacePlaceholder(.ProfileHeader, items: sself.headerItems())
                doneOperation.run()
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        })
    }

    func loadUserPosts(doneOperation: AsyncOperation) {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }
        let displayPostsOperation = AsyncOperation()
        displayPostsOperation.addDependency(doneOperation)
        queue.addOperation(displayPostsOperation)

        StreamService().loadUserPosts(
            userParam,
            success: { [weak self] (posts, responseConfig) in
                guard let sself = self else { return }

                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                sself.destination?.setPagingConfig(responseConfig)
                sself.posts = posts
                let userPostItems = sself.parse(posts)
                displayPostsOperation.run {
                    sself.destination?.replacePlaceholder(.ProfilePosts, items: userPostItems)
                }
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        })
    }
}
