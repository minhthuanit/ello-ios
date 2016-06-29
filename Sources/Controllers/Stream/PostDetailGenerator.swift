public final class PostDetailGenerator: StreamGenerator {

    public let currentUser: User?
    public var streamKind: StreamKind
    // TODO: make destination weak
    weak public var destination: StreamDestination?

    private var post: Post?
    private let postParam: String

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
        destination?.setPlaceholders([
            StreamCellItem(type: .Placeholder(.PostHeader)),
            StreamCellItem(type: .Placeholder(.PostLovers)),
            StreamCellItem(type: .Placeholder(.PostReposters)),
            StreamCellItem(type: .Placeholder(.PostComments)),
        ])

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

        destination?.setPrimaryJSONAble(post)
        if post.content?.count > 0 {
            let postItems = parse([post])
            destination?.replacePlaceholder(.PostHeader, items: postItems)
        }
    }

    func loadPost() {
        // load the post with no comments
        PostService().loadPost(
            postParam,
            needsComments: false,
            success: { [weak self] (post, responseConfig) in
                print("loaded post: \(post.id)")
                guard let sself = self else { return }
                sself.post = post
                // TODO: make sure this responseConfig is what we want. We might want to use the comments response config
                sself.destination?.setPagingConfig(responseConfig)
                sself.destination?.setPrimaryJSONAble(post)
                let postItems = sself.parse([post])
                sself.destination?.replacePlaceholder(.PostHeader, items: postItems)
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
        })
    }

    func loadPostComments() {
        PostService().loadPostComments(
            postParam,
            success: { [weak self] (comments, responseConfig) in
                guard let sself = self else { return }
                print("loaded comments: \(comments.count)")
                let commentItems = sself.parse(comments)
                sself.destination?.replacePlaceholder(.PostComments, items: commentItems)
            },
            failure: { _ in
                print("failed load post comments")
        })
    }

    func loadPostLovers() {
        PostService().loadPostLovers(
            postParam,
            success: { [weak self] (users, _) in
                print("loaded lovers: \(users.count)")
                guard let sself = self else { return }
                guard users.count > 0 else { return }

                let loversItems = sself.userAvatarCellItems(
                    users,
                    icon: .Heart,
                    seeMoreTitle: InterfaceString.Post.LovedByList
                )
                sself.destination?.replacePlaceholder(.PostLovers, items: loversItems)
            },
            failure: { _ in
                print("failed load post lovers")
        })
    }

    func loadPostReposters() {
        PostService().loadPostReposters(
            postParam,
            success: { [weak self] (users, _) in
                print("loaded reposters: \(users.count)")
                guard let sself = self else { return }
                guard users.count > 0 else { return }

                let repostersItems = sself.userAvatarCellItems(
                    users,
                    icon: .Repost,
                    seeMoreTitle: InterfaceString.Post.RepostedByList
                )
                sself.destination?.replacePlaceholder(.PostReposters, items: repostersItems)
            },
            failure: { _ in
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
