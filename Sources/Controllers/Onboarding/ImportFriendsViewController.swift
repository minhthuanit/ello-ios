////
///  ImportFriendsViewController.swift
//

public class ImportFriendsViewController: OnboardingUserListViewController {
    let addressBook: ContactList

    required public init(addressBook: ContactList) {
        self.addressBook = addressBook
        super.init(nibName: nil, bundle: NSBundle(forClass: ImportFriendsViewController.self))
        self.title = "Onboarding Find Friends"
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Onboarding Import Friends"
    }

    override func setupStreamController() {
        super.setupStreamController()
        let noResultsTitle = InterfaceString.Onboard.FindYourFriends.NoResultsTitle
        let noResultsBody = InterfaceString.Onboard.FindYourFriends.NoResultsBody
        streamViewController.noResultsMessages = (title: noResultsTitle, body: noResultsBody)
        streamViewController.initialLoadClosure = findFriendsFromContacts
    }

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

    public func setContacts(contacts: [(LocalPerson, User?)]) {
        var foundItems = [StreamCellItem]()
        var inviteItems = [StreamCellItem]()
        for contact in contacts {
            let (person, user): (LocalPerson, User?) = contact
            if let user = user {
                foundItems.append(StreamCellItem(jsonable: user, type: .UserListItem))
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
        users = foundItems.map { $0.jsonable as! User }
        let filteredUsers = InviteService.filterUsers(users!, currentUser: currentUser)
        let header = InterfaceString.Onboard.FindYourFriends.Title
        let message = InterfaceString.Onboard.FindYourFriends.Description
        appendHeaderCellItem(header: header, message: message)
        appendFollowAllCellItem(userCount: filteredUsers.count)
        // this calls doneLoading when cells are added
        streamViewController.appendUnsizedCellItems(foundItems + inviteItems, withWidth: self.view.frame.width)
    }

}
