public final class PostDetailGenerator: StreamGenerator {

    public let currentUser: User?
    public var streamKind: StreamKind
    // TODO: make destination weak
    public var destination: StreamDestination

    private var post: Post?
    private let postParam: String
    private var postItems = [StreamCellItem]()
    private var loversItems = [StreamCellItem]()
    private var repostersItems = [StreamCellItem]()
    private var commentItems = [StreamCellItem]()

    private var staticItems: [StreamCellItem] {
        get {
            var staticItems = [StreamCellItem]()
            if loversItems.count + repostersItems.count > 0 {
                staticItems.append(StreamCellItem(jsonable: JSONAble.fromJSON([:], fromLinked: false), type: .Spacer(height: 8.0)))
            }
            // add in the comment button if we have a current user
            let commentingEnabled = self.post?.author?.hasCommentingEnabled ?? true
            if let currentUser = currentUser where commentingEnabled, let post = post {
                staticItems.append(StreamCellItem(jsonable: ElloComment.newCommentForPost(post, currentUser: currentUser), type: .CreateComment))
            }
            return staticItems
        }
    }

    public var items: [StreamCellItem] {
        get {
            guard postItems.count > 0 else {
                return []
            }

            return [
                postItems,
                loversItems,
                repostersItems,
                staticItems,
                commentItems
            ].flatMap { $0 }
        }
    }

    init(currentUser: User?,
         postParam: String,
         post: Post?,
         streamKind: StreamKind,
         destination: StreamDestination
        ) {
        self.currentUser = currentUser
        self.post = post
        self.postParam = postParam
        self.streamKind = streamKind
        self.destination = destination
    }

    public func bind() {
        setInitialPost()
        loadPost()
        loadPostComments()
        loadPostLovers()
        loadPostReposters()
    }

}

private extension PostDetailGenerator {
    func setInitialPost() {
        guard let post = post else { return }

        destination.setPrimaryJSONAble(post)
        if post.content?.count > 0 {
            postItems = parse([post])
            destination.setItems(items)
        }
    }

    func loadPost() {
        // load the post with no comments
        PostService().loadPost(
            postParam,
            needsComments: false,
            success: { (post, responseConfig) in
                print("loaded post: \(post.id)")
                self.post = post
                // TODO: make sure this responseConfig is what we want. We might want to use the comments response config
                self.destination.setPagingConfig(responseConfig)
                self.destination.setPrimaryJSONAble(post)
                self.postItems = self.parse([post])
                self.destination.setItems(self.items)
            },
            failure: { _ in
                self.destination.primaryJSONAbleNotFound()
        })
    }

    func loadPostComments() {
        PostService().loadPostComments(
            postParam,
            success: { (comments, responseConfig) in
                print("loaded comments: \(comments.count)")
                self.commentItems = self.parse(comments)
                self.destination.setItems(self.items)
            },
            failure: { (error, statusCode) in
                print("failed load post comments")
        })
    }

    func loadPostLovers() {
        PostService().loadPostLovers(
            postParam,
            success: { (users, _) in
                print("loaded lovers: \(users.count)")
                guard users.count > 0 else { return }

                self.loversItems = self.userAvatarCellItems(
                    users,
                    icon: .Heart,
                    seeMoreTitle: InterfaceString.Post.LovedByList
                )
                self.destination.setItems(self.items)
            },
            failure: { (error, statusCode) in
                print("failed load post lovers")
        })
    }

    func loadPostReposters() {
        PostService().loadPostReposters(
            postParam,
            success: { (users, _) in
                print("loaded reposters: \(users.count)")
                guard users.count > 0 else { return }

                self.repostersItems = self.userAvatarCellItems(
                    users,
                    icon: .Repost,
                    seeMoreTitle: InterfaceString.Post.RepostedByList
                )
                self.destination.setItems(self.items)
            },
            failure: { (error, statusCode) in
                print("failed load post reposters")
        })
    }

    func userAvatarCellItems(
        users: [User],
        icon: InterfaceImage,
        seeMoreTitle: String) -> [StreamCellItem]
    {
        let model = UserAvatarCellModel(icon: icon, seeMoreTitle: seeMoreTitle)
        model.users = users

        return [
            StreamCellItem(jsonable: JSONAble.fromJSON([:], fromLinked: false), type: .Spacer(height: 4.0)),
            StreamCellItem(jsonable: model, type: .UserAvatars)
        ]
    }
}
