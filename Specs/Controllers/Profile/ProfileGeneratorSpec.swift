////
///  ProfileGeneratorSpec.swift
//

import Ello
import Quick
import Nimble

class ProfileGeneratorSpec: QuickSpec {
    override func spec() {
        describe("ProfileGenerator") {
            let destination = ProfileDestination()

            beforeEach {
                destination.reset()
            }

            let currentUser: User = stub(["id": "42"])
            let streamKind: StreamKind = .CurrentUserStream

            let subject = ProfileGenerator(
                currentUser: currentUser,
                userParam: "42",
                user: currentUser,
                streamKind: streamKind,
                destination: destination
            )

            describe("load()") {

                it("sets 2 placeholders") {
                    subject.load()
                    expect(destination.placeholderItems.count) == 2
                }

                it("replaces only ProfileHeader and ProfilePosts") {
                    subject.load()
                    expect(destination.headerItems.count) > 0
                    expect(destination.postItems.count) > 0
                    expect(destination.otherPlaceHolderLoaded) == false
                }

                it("sets the primary jsonable") {
                    subject.load()
                    expect(destination.user).toNot(beNil())
                }

                it("sets the config response") {
                    subject.load()
                    expect(destination.responseConfig).toNot(beNil())
                }
            }
        }
    }
}

class ProfileDestination: NSObject, StreamDestination {

    var placeholderItems: [StreamCellItem] = []
    var headerItems: [StreamCellItem] = []
    var postItems: [StreamCellItem] = []
    var otherPlaceHolderLoaded = false
    var user: User?
    var responseConfig: ResponseConfig?

    override init(){ super.init() }

    func reset() {
        placeholderItems = []
        headerItems = []
        postItems = []
        otherPlaceHolderLoaded = false
        user = nil
        responseConfig = nil
    }

    func setPlaceholders(items: [StreamCellItem]) {
        placeholderItems = items
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, @autoclosure items: () -> [StreamCellItem]) {
        switch type {
        case .ProfileHeader:
            headerItems = items()
        case .ProfilePosts:
            postItems = items()
        default:
            otherPlaceHolderLoaded = true
        }
    }

    func setPrimaryJSONAble(jsonable: JSONAble) {
        guard let user = jsonable as? User else { return }
        self.user = user
    }

    func primaryJSONAbleNotFound() {

    }

    func setPagingConfig(responseConfig: ResponseConfig) {
        self.responseConfig = responseConfig
    }
}
