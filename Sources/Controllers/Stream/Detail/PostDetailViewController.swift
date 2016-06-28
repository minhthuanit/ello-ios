////
///  PostDetailViewController.swift
//

    var post: Post?
    var postParam: String!
    var scrollToComment: ElloComment?

    var navigationBar: ElloNavigationBar!
    var localToken: String!
    var deeplinkPath: String?
    var generator: PostDetailGenerator!

    required public init(postParam: String) {
        self.postParam = postParam
        super.init(nibName: nil, bundle: nil)
        self.localToken = streamViewController.resetInitialPageLoadingToken()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        streamViewController.streamKind = .PostDetail(postParam: postParam)
        view.backgroundColor = .whiteColor()
        self.generator = PostDetailGenerator(
            currentUser: self.currentUser,
            postParam: postParam,
            post: self.post,
            streamKind: self.streamViewController.streamKind,
            destination: self
        )
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.initialLoadClosure = reloadEntirePostDetail
        streamViewController.loadInitialPage()
    }

    // used to provide StreamableViewController access to the container it then
    // loads the StreamViewController's content into
    override func viewForStream() -> UIView {
        return view
    }

    private func updateInsets() {
        updateInsets(navBar: navigationBar, streamController: streamViewController)
    }

    override public func showNavBars(scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(navigationBar, visible: true)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override public func hideNavBars() {
        super.hideNavBars()
        positionNavBar(navigationBar, visible: false)
        updateInsets()
    }

    // MARK : private

    private func reloadEntirePostDetail() {
        generator.bind()
    }

    private func showPostLoadFailure() {
        let message = InterfaceString.GenericError
        let alertController = AlertViewController(message: message)
        let action = AlertAction(title: InterfaceString.OK, style: .Dark) { _ in
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    private func setupNavigationBar() {
        navigationBar = ElloNavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: ElloNavigationBar.Size.height))
        navigationBar.autoresizingMask = [.FlexibleBottomMargin, .FlexibleWidth]
        view.addSubview(navigationBar)
        let item = UIBarButtonItem.backChevronWithTarget(self, action: #selector(StreamableViewController.backTapped(_:)))
        elloNavigationItem.leftBarButtonItems = [item]
        elloNavigationItem.fixNavBarItemPadding()
        navigationBar.items = [elloNavigationItem]
        assignRightButtons()
    }

    private func assignRightButtons() {
        guard post != nil else {
            elloNavigationItem.rightBarButtonItems = []
            return
        }

        if isOwnPost() {
            elloNavigationItem.rightBarButtonItems = [
                UIBarButtonItem(image: .XBox, target: self, action: #selector(PostDetailViewController.deletePost)),
                UIBarButtonItem(image: .Pencil, target: self, action: #selector(PostDetailViewController.editPostAction)),
            ]
        }
        else {
            elloNavigationItem.rightBarButtonItems = [
                UIBarButtonItem(image: .Search, target: self, action: #selector(BaseElloViewController.searchButtonTapped)),
                UIBarButtonItem(image: .Dots, target: self, action: #selector(PostDetailViewController.flagPost)),
            ]
        }
    }

    private func scrollToComment(comment: ElloComment) {
        let commentItem = streamViewController.dataSource.visibleCellItems.find { item in
            return (item.jsonable as? ElloComment)?.id == comment.id
        } ?? streamViewController.dataSource.visibleCellItems.last

        if let commentItem = commentItem, indexPath = self.streamViewController.dataSource.indexPathForItem(commentItem) {
            self.streamViewController.collectionView.scrollToItemAtIndexPath(
                indexPath,
                atScrollPosition: .Top,
                animated: true
            )
        }
    }

    override public func postTapped(post: Post) {
        if let selfPost = self.post where post.id != selfPost.id {
            super.postTapped(post)
        }
    }

    private func isOwnPost() -> Bool {
        guard let post = post, currentUser = currentUser else {
            return false
        }
        return currentUser.isOwnPost(post)
    }

    public func flagPost() {
        guard let post = post else { return }

        let flagger = ContentFlagger(presentingController: self,
            flaggableId: post.id,
            contentType: .Post)
        flagger.displayFlaggingSheet()
    }

    public func editPostAction() {
        guard let post = post where isOwnPost() else {
            return
        }

        // This is a bit dirty, we should not call a method on a compositionally held
        // controller's createPostDelegate. Can this use the responder chain when we have
        // parameters to pass?
        editPost(post, fromController: self)
    }

    public func deletePost() {
        guard let post = post, currentUser = currentUser where isOwnPost() else {
            return
        }

        let message = InterfaceString.Post.DeletePostConfirm
        let alertController = AlertViewController(message: message)

        let yesAction = AlertAction(title: InterfaceString.Yes, style: .Dark) { _ in
            if let userPostCount = currentUser.postsCount {
                currentUser.postsCount = userPostCount - 1
                postNotification(CurrentUserChangedNotification, value: currentUser)
            }

            postNotification(PostChangedNotification, value: (post, .Delete))
            PostService().deletePost(post.id,
                success: nil,
                failure: { (error, statusCode)  in
                    // TODO: add error handling
                    print("failed to delete post, error: \(error.elloErrorMessage ?? error.localizedDescription)")
                })
        }
        let noAction = AlertAction(title: InterfaceString.No, style: .Light, handler: .None)

        alertController.addAction(yesAction)
        alertController.addAction(noAction)

        logPresentingAlert("PostDetailViewController")
        self.presentViewController(alertController, animated: true, completion: .None)
    }

}

// MARK: PostDetailViewController: StreamDestination
extension PostDetailViewController: StreamDestination {

    public func setItems(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad()
        streamViewController.appendUnsizedCellItems(items, withWidth: view.frame.width) { _ in
            if let scrollToComment = self.scrollToComment {
                // nextTick didn't work, the collection view hadn't shown its
                // cells or updated contentView.  so this.
                delay(0.1) {
                    self.scrollToComment(scrollToComment)
                }
            }
        }
    }

    public func setPrimaryJSONAble(jsonable: JSONAble) {
        guard let post = jsonable as? Post else { return }

        if self.post == nil {
            Tracker.sharedTracker.postViewed(post.id)
        }

        self.post = post

        // need to reassign the userParam to the id for paging
        self.postParam = post.id

        /*
         - need to reassign the streamKind so that the comments
         can page based off the post.id from the ElloAPI.path

         - same for when tapping on a post token in a post this
         will replace '~CRAZY-TOKEN' with the correct id for
         paging to work
         */

        streamViewController.streamKind = .PostDetail(postParam: postParam)

        self.title = post.author?.atName ?? InterfaceString.Post.DefaultTitle

        assignRightButtons()

        if isOwnPost() {
            showNavBars(false)
        }

        Tracker.sharedTracker.postLoaded(post.id)
    }

    public func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }

    public func primaryJSONAbleNotFound() {
        if let deeplinkPath = self.deeplinkPath,
            deeplinkURL = NSURL(string: deeplinkPath)
        {
            UIApplication.sharedApplication().openURL(deeplinkURL)
            self.deeplinkPath = nil
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.showPostLoadFailure()
        }
        self.streamViewController.doneLoading()
    }
}
