////
///  OnboardingUserListViewController.swift
//

public class OnboardingUserListViewController: StreamableViewController, OnboardingStep, FollowAllButtonResponder, RelationshipControllerDelegate {
    weak var onboardingViewController: OnboardingViewController?
    var onboardingData: OnboardingData?

    var headerItem: StreamCellItem?
    var followAllItem: StreamCellItem?
    var users: [User]?

    override func setupStreamController() {
        super.setupStreamController()

        streamViewController.pullToRefreshEnabled = false
        streamViewController.allOlderPagesLoaded = true
        streamViewController.initialLoadClosure = self.loadUsers
        streamViewController.relationshipController?.delegate = self
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        streamViewController.loadInitialPage()
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateCanGoNextButton()

        ElloHUD.showLoadingHudInView(streamViewController.view)
    }

    override func viewForStream() -> UIView {
        return view
    }

    override public func didSetCurrentUser() {
        if isViewLoaded() {
            streamViewController.currentUser = currentUser
        }
        super.didSetCurrentUser()
    }

    func appendHeaderCellItem(header header: String, message: String) {
        let headerItem = StreamCellItem(type: .OnboardingHeader(data: (header, message)))
        self.headerItem = headerItem
        streamViewController.appendStreamCellItems([headerItem])
    }

    func appendFollowAllCellItem(userCount userCount: Int) {
        let data = FollowAllCounts(userCount: userCount, followedCount: 0)
        let followAllItem = StreamCellItem(type: .FollowAll(data: data))
        self.followAllItem = followAllItem
        streamViewController.appendStreamCellItems([followAllItem])
    }

    public func onboardingStepBegin() {
        print("implemented but intentionally left blank")
    }

    public func onboardingWillProceed(proceed: (OnboardingData?) -> Void) {
        let users = userItems().map { $0.jsonable as! User }
        let friendUserIds = users.filter { (user: User) -> Bool in return user.relationshipPriority == .Following }.map { $0.id }

        if self.users?.count == friendUserIds.count {
            Tracker.sharedTracker.followedAllFeatured()
        }
        else if friendUserIds.count > 0 {
            Tracker.sharedTracker.followedSomeFeatured()
        }

        if friendUserIds.count > 0 {
            ElloHUD.showLoadingHud()
            RelationshipService().bulkUpdateRelationships(userIds: friendUserIds, relationshipPriority: .Following,
                success: { data in
                    ElloHUD.hideLoadingHud()
                    proceed(self.onboardingData)
                },
                failure: { _ in
                    ElloHUD.hideLoadingHud()
                    self.showRelationshipFailureAlert()
                })
        }
        else {
            proceed(self.onboardingData)
        }
    }

    private func showRelationshipFailureAlert() {
        let message = InterfaceString.Onboard.RelationshipFailed
        let alertController = AlertViewController(message: message)

        let action = AlertAction(title: InterfaceString.OK, style: .Dark, handler: nil)
        alertController.addAction(action)

        logPresentingAlert("OnboardingUserListViewController")
        self.presentViewController(alertController, animated: true, completion: nil)
    }

// MARK: RelationshipControllerDelegate

    public func shouldSubmitRelationship(userId: String, relationshipPriority: RelationshipPriority) -> Bool {
        let jsonables = streamViewController.dataSource.streamCellItems.map { (item: StreamCellItem) in return item.jsonable }
        for jsonable in jsonables {
            if let user = jsonable as? User where user.id == userId {
                user.relationshipPriority = relationshipPriority
                break
            }
        }

        updateFollowAllItem()
        updateCanGoNextButton()
        return false
    }

    public func relationshipChanged(userId: String, status: RelationshipRequestStatus, relationship: Relationship?) {
    }

}

extension OnboardingUserListViewController {

    private func userItems() -> [StreamCellItem] {
        return streamViewController.dataSource.streamCellItems.filter { (item: StreamCellItem) in return item.type == .UserListItem }
    }

    func followedCount() -> Int {
        if let users = users {
            return users.reduce(0) { (followedCount: Int, user: User) -> Int in
                if user.relationshipPriority == .Following || user.relationshipPriority == .Starred {
                    return followedCount + 1
                }
                return followedCount
            }
        }
        return 0
    }

    func updateFollowAllItem() {
        updateFollowAllItem(userCount: (users ?? []).count, followedCount: followedCount())
    }

    func updateFollowAllItem(userCount userCount: Int, followedCount: Int) {
        followAllItem?.type = .FollowAll(data: FollowAllCounts(userCount: userCount, followedCount: followedCount))
        streamViewController.reloadCells()
    }

    func updateCanGoNextButton() {
        updateCanGoNextButton(followedCount: followedCount())
    }

    func updateCanGoNextButton(followedCount followedCount: Int) {
        onboardingViewController?.canGoNext = followedCount > 0
    }

    func onFollowAll() {
        if let users = users {
            if users.count == followedCount() {
                friendNone(users)
            }
            else {
                friendAll(users)
            }
        }
    }

    func friendAll(users: [User]) {
        setAllRelationships(users, relationship: .Following)
    }

    func friendNone(users: [User]) {
        setAllRelationships(users, relationship: .None)
    }

    func setAllRelationships(users: [User], relationship: RelationshipPriority) {
        for user in users {
            user.relationshipPriority = relationship
        }

        let userCount = users.count
        let followedCount: Int
        if relationship == .None {
            followedCount = 0
        }
        else {
            followedCount = userCount
        }

        updateFollowAllItem(userCount: userCount, followedCount: followedCount)
        updateCanGoNextButton(followedCount: followedCount)
    }

}

extension OnboardingUserListViewController {

    func loadUsers() {
        let localToken = streamViewController.loadingToken.resetInitialPageLoadingToken()

        streamViewController.streamService.loadStream(
            streamViewController.streamKind.endpoint,
            streamKind: streamViewController.streamKind,
            success: { (jsonables, responseConfig) in
                if !self.streamViewController.loadingToken.isValidInitialPageLoadingToken(localToken) { return }

                if let users = jsonables as? [User] {
                    self.usersLoaded(users)
                }
                else {
                    self.streamViewController.doneLoading()
                }
            },
            failure: { (error, statusCode) in
                self.streamViewController.doneLoading()
                self.onboardingViewController?.canGoNext = true
            })
    }

    func usersLoaded(users: [User]) {
        self.users = users
        let items: [StreamCellItem] = StreamCellItemParser().parse(users, streamKind: streamViewController.streamKind, currentUser: currentUser)
        // this calls doneLoading when cells are added
        streamViewController.appendUnsizedCellItems(items, withWidth: view.frame.width)
    }

}
