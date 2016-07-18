////
///  AddFriendsViewController.swift
//

public class AddFriendsViewController: StreamableViewController {

    let addressBook: ContactList

    public let inviteService = InviteService()
    public var allContacts: [(LocalPerson, User?)] = []
    public var userTappedDelegate: UserTappedDelegate?

    var _mockScreen: SearchScreenProtocol?
    public var screen: SearchScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return _mockScreen ?? self.view as! SearchScreen }
    }
    public var searchScreen: SearchScreen!

    required public init(addressBook: ContactList) {
        self.addressBook = addressBook
        super.init(nibName: nil, bundle: nil)
        streamViewController.initialLoadClosure = findFriendsFromContacts
        streamViewController.pullToRefreshEnabled = false
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        searchScreen = SearchScreen(frame: UIScreen.mainScreen().bounds,
            isSearchView: false,
            navBarTitle: InterfaceString.Friends.FindAndInvite,
            fieldPlaceholderText: InterfaceString.Friends.SearchPrompt)
        self.view = searchScreen
        searchScreen.delegate = self
        searchScreen.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: .Search, target: self, action: #selector(BaseElloViewController.searchButtonTapped)),
        ]
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        screen.hasBackButton = (navigationController != nil)
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if isMovingToParentViewController() || presentingViewController != nil {
            showNavBars(false)
            updateInsets()
            ElloHUD.showLoadingHudInView(streamViewController.view)
            streamViewController.loadInitialPage()
        }
    }

    override func viewForStream() -> UIView {
        return screen.viewForStream()
    }

    override func showNavBars(scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        if let ss = self.view as? SearchScreen {
            positionNavBar(ss.navigationBar, visible: true)
            ss.showNavBars()
        }
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override func hideNavBars() {
        super.hideNavBars()
        if let ss = self.view as? SearchScreen {
            positionNavBar(ss.navigationBar, visible: false)
            ss.hideNavBars()
        }
        updateInsets()
    }

    private func updateInsets() {
        if let ss = self.view as? SearchScreen {
            updateInsets(navBar: ss.navigationBar, streamController: streamViewController, navBarsVisible: false)
        }
    }

    public func setContacts(contacts: [(LocalPerson, User?)]) {
        allContacts = contacts
        var foundItems = [StreamCellItem]()
        var inviteItems = [StreamCellItem]()
        for contact in allContacts {
            let (person, user): (LocalPerson, User?) = contact
            if user != nil {
                foundItems.append(StreamCellItem(jsonable: user!, type: .UserListItem))
            }
            else {
                if let currentUser = currentUser, profile = currentUser.profile {
                    if !person.emails.contains(profile.email) {
                        inviteItems.append(StreamCellItem(jsonable: person, type: .InviteFriends))
                    }

                }
            }
        }
        foundItems.sortInPlace { ($0.jsonable as! User).username.lowercaseString < ($1.jsonable as! User).username.lowercaseString }
        inviteItems.sortInPlace { ($0.jsonable as! LocalPerson).name.lowercaseString < ($1.jsonable as! LocalPerson).name.lowercaseString }
        // this calls doneLoading when cells are added
        streamViewController.appendUnsizedCellItems(foundItems + inviteItems, withWidth: self.view.frame.width)
    }

    // MARK: - Private

    private func findFriendsFromContacts() {
        let localToken = streamViewController.loadingToken.resetInitialPageLoadingToken()

        var contacts = [String: [String]]()
        for person in addressBook.localPeople {
            contacts[person.identifier] = person.emails
        }
        InviteService().find(contacts,
            currentUser: self.currentUser,
            success: { users in
                if !self.streamViewController.loadingToken.isValidInitialPageLoadingToken(localToken) { return }

                self.streamViewController.clearForInitialLoad()
                let userIdentifiers = users.map { $0.identifiableBy ?? "" }
                let mixed: [(LocalPerson, User?)] = self.addressBook.localPeople.map {
                    if let index = userIdentifiers.indexOf($0.identifier) {
                        return ($0, users[index])
                    }
                    return ($0, .None)
                }
                self.setContacts(mixed)
            },
            failure: { _ in
                let contacts: [(LocalPerson, User?)] = self.addressBook.localPeople.map { ($0, .None) }
                self.setContacts(contacts)
                self.streamViewController.doneLoading()
            })
    }
}

extension AddFriendsViewController: SearchScreenDelegate {

    public func searchCanceled() {
        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(true)
        }
        else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    public func searchFieldCleared() {
        streamViewController.streamFilter = nil
    }

    public func searchFieldChanged(text: String, isPostSearch: Bool) {
        if text.characters.count < 2 { return }
        if text.isEmpty {
            streamViewController.streamFilter = nil
        } else {
            streamViewController.streamFilter = { item in
                if let user = item.jsonable as? User {
                    return user.name.contains(text) || user.username.contains(text)
                }
                else if let person = item.jsonable as? LocalPerson {
                    return person.name.contains(text) || person.emails.any { $0.contains(text) }
                }
                return false
            }
        }
    }

    public func searchFieldWillChange() {
        // noop
    }

    public func toggleChanged(text: String, isPostSearch: Bool) {
        // do nothing as this should not be visible
    }

    public func findFriendsTapped() {
        // noop
    }

}
