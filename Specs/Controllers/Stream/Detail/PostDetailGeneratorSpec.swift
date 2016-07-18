////
///  PostDetailGeneratorSpec.swift
//

import Ello
import Quick
import Nimble

class PostDetailGeneratorSpec: QuickSpec {
    override func spec() {
        describe("PostDetailGenerator") {
            let destination = PostDetailDestination()

            beforeEach {
                destination.reset()
            }

            let currentUser: User = stub(["id": "42"])
            let post: Post = stub(["id": "123"])
            let streamKind: StreamKind = .CurrentUserStream

            let subject = PostDetailGenerator(
                currentUser: currentUser,
                postParam: "123",
                post: post,
                streamKind: streamKind,
                destination: destination
            )
            
            fdescribe("bind()") {

                it("sets 4 placeholders") {
                    subject.bind()
                    expect(destination.placeholderItems.count) == 4
                }

                it("replaces only PostHeader, PostLovers, PostReposters and PostComment") {
                    subject.bind()
                    expect(destination.headerItems.count) > 0
                    expect(destination.postLoverItems.count) > 0
                    expect(destination.postReposterItems.count) > 0
                    expect(destination.postCommentItems.count) > 0
                    expect(destination.otherPlaceHolderLoaded) == false
                }

                it("sets the primary jsonable") {
                    subject.bind()
                    expect(destination.post).toNot(beNil())
                }

                it("sets the config response") {
                    subject.bind()
                    expect(destination.responseConfig).toNot(beNil())
                }
            }
        }
    }
}

class PostDetailDestination: NSObject, StreamDestination {

    var placeholderItems: [StreamCellItem] = []
    var headerItems: [StreamCellItem] = []
    var postLoverItems: [StreamCellItem] = []
    var postReposterItems: [StreamCellItem] = []
    var postCommentItems: [StreamCellItem] = []
    var otherPlaceHolderLoaded = false
    var post: Post?
    var responseConfig: ResponseConfig?

    override init(){ super.init() }

    func reset() {
        placeholderItems = []
        headerItems = []
        postLoverItems = []
        postReposterItems = []
        postCommentItems = []
        otherPlaceHolderLoaded = false
        post = nil
        responseConfig = nil
    }

    func setPlaceholders(items: [StreamCellItem]) {
        placeholderItems = items
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, @autoclosure items: () -> [StreamCellItem]) {
        switch type {
        case .PostHeader:
            headerItems = items()
        case .PostLovers:
            postLoverItems = items()
        case .PostReposters:
            postReposterItems = items()
        case .PostComments:
            postCommentItems = items()
        default:
            otherPlaceHolderLoaded = true
        }
    }

    func setPrimaryJSONAble(jsonable: JSONAble) {
        guard let post = jsonable as? Post else { return }
        self.post = post
    }

    func primaryJSONAbleNotFound() {

    }

    func setPagingConfig(responseConfig: ResponseConfig) {
        self.responseConfig = responseConfig
    }
}
