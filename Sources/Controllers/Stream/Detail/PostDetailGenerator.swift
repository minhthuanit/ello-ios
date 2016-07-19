////
///  PostDetailGenerator.swift
//

public final class PostDetailGenerator: StreamGenerator {

    public var currentUser: User?
    public var streamKind: StreamKind
    weak public var destination: StreamDestination?

    private var post: Post?
    private let postParam: String
    private var localToken: String!
    private var loadingToken = LoadingToken()
    private var hasPaddedSocial = false
    private let queue = NSOperationQueue()

    public init(currentUser: User?,
         postParam: String,
         post: Post?,
         streamKind: StreamKind,
         destination: StreamDestination
        ) {
        self.currentUser = currentUser
        self.post = post
        self.postParam = postParam
        self.streamKind = streamKind
        self.localToken = loadingToken.resetInitialPageLoadingToken()
        self.destination = destination
    }

    public func load(reload reload: Bool = false) {
        let doneOperation = AsyncOperation()
        queue.addOperation(doneOperation)

        hasPaddedSocial = false
        localToken = loadingToken.resetInitialPageLoadingToken()
        setPlaceHolders()
        setInitialPost(doneOperation)
        loadPost(doneOperation, reload: reload)
        displayCommentBar(doneOperation)
        loadPostComments(doneOperation)
        loadPostLovers(doneOperation)
        loadPostReposters(doneOperation)
    }

}

private extension PostDetailGenerator {

    func setPlaceHolders() {
        destination?.setPlaceholders([
            StreamCellItem(type: .Placeholder, placeholderType: .PostHeader),
            StreamCellItem(type: .Placeholder, placeholderType: .PostLovers),
            StreamCellItem(type: .Placeholder, placeholderType: .PostReposters),
            StreamCellItem(type: .Placeholder, placeholderType: .PostSocialPadding),
            StreamCellItem(type: .Placeholder, placeholderType: .PostCommentBar),
            StreamCellItem(type: .Placeholder, placeholderType: .PostComments)
        ])
    }

    func setInitialPost(doneOperation: AsyncOperation) {
        guard let post = post else { return }

        destination?.setPrimaryJSONAble(post)
        if post.content?.count > 0 || post.repostContent?.count > 0 {
            let postItems = parse([post])
            destination?.replacePlaceholder(.PostHeader, items: postItems)
            doneOperation.run()
        }
    }

    func loadPost(doneOperation: AsyncOperation, reload: Bool = false) {
        guard !doneOperation.finished || reload else { return }

        // load the post with no comments
        PostService().loadPost(
            postParam,
            needsComments: false,
            success: { [weak self] (post, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                sself.post = post
                sself.destination?.setPrimaryJSONAble(post)
                let postItems = sself.parse([post])
                sself.destination?.replacePlaceholder(.PostHeader, items: postItems)
                doneOperation.run()
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        })
    }

    func displayCommentBar(doneOperation: AsyncOperation) {

        let displayCommentBarOperation = AsyncOperation()
        displayCommentBarOperation.addDependency(doneOperation)
        queue.addOperation(displayCommentBarOperation)

        displayCommentBarOperation.run { [weak self] in
            guard let sself = self else { return }
            guard let post = sself.post else { return }
            let commentingEnabled = post.author?.hasCommentingEnabled ?? true
            guard let currentUser = sself.currentUser where commentingEnabled else { return }

            let barItems = [StreamCellItem(jsonable: ElloComment.newCommentForPost(post, currentUser: currentUser), type: .CreateComment)]
            sself.destination?.replacePlaceholder(.PostCommentBar, items: barItems)
        }
    }

    func displaySocialPadding() {
        let padding = [StreamCellItem(jsonable: JSONAble.fromJSON([:], fromLinked: false), type: .Spacer(height: 8.0))]
        destination?.replacePlaceholder(.PostSocialPadding, items: padding)
    }

    func loadPostComments(doneOperation: AsyncOperation) {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }

        let displayCommentsOperation = AsyncOperation()
        displayCommentsOperation.addDependency(doneOperation)
        queue.addOperation(displayCommentsOperation)

        PostService().loadPostComments(
            postParam,
            success: { [weak self] (comments, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                let commentItems = sself.parse(comments)
                displayCommentsOperation.run {
                    sself.destination?.setPagingConfig(responseConfig)
                    sself.destination?.replacePlaceholder(.PostComments, items: commentItems)
                }
            },
            failure: { _ in
                print("failed load post comments")
        })
    }

    func loadPostLovers(doneOperation: AsyncOperation) {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }

        let displayLoversOperation = AsyncOperation()
        displayLoversOperation.addDependency(doneOperation)
        queue.addOperation(displayLoversOperation)

        PostService().loadPostLovers(
            postParam,
            success: { [weak self] (users, _) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                guard users.count > 0 else { return }

                let loversItems = sself.userAvatarCellItems(
                    users,
                    icon: .Heart,
                    seeMoreTitle: InterfaceString.Post.LovedByList
                )
                displayLoversOperation.run {
                    sself.destination?.replacePlaceholder(.PostLovers, items: loversItems)
                }
            },
            failure: { _ in
                print("failed load post lovers")
        })
    }

    func loadPostReposters(doneOperation: AsyncOperation) {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }

        let displayRepostersOperation = AsyncOperation()
        displayRepostersOperation.addDependency(doneOperation)
        queue.addOperation(displayRepostersOperation)

        PostService().loadPostReposters(
            postParam,
            success: { [weak self] (users, _) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                guard users.count > 0 else { return }

                let repostersItems = sself.userAvatarCellItems(
                    users,
                    icon: .Repost,
                    seeMoreTitle: InterfaceString.Post.RepostedByList
                )
                displayRepostersOperation.run {
                    sself.destination?.replacePlaceholder(.PostReposters, items: repostersItems)
                }
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
        if !hasPaddedSocial {
            hasPaddedSocial = true
            displaySocialPadding()
        }

        return [
            StreamCellItem(jsonable: JSONAble.fromJSON([:], fromLinked: false), type: .Spacer(height: 4.0)),
            StreamCellItem(jsonable: model, type: .UserAvatars)
        ]
    }
}
