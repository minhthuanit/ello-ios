////
///  StreamDataSourceSpec.swift
//

import Ello
import Quick
import Nimble
import Moya

public class FakeCollectionView: UICollectionView {

    public override func insertItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        // noop
    }

    public override func deleteItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        // noop
    }

    public override func reloadItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        // noop
    }
}

class StreamDataSourceSpec: QuickSpec {

    override func spec() {
        let indexPath0 = NSIndexPath(forItem: 0, inSection: 0)
        let indexPath1 = NSIndexPath(forItem: 1, inSection: 0)
        let indexPathOutOfBounds = NSIndexPath(forItem: 1000, inSection: 0)
        let indexPathInvalidSection = NSIndexPath(forItem: 0, inSection: 10)

        var vc: StreamViewController!
        var subject: StreamDataSource!
        var fakeCollectionView: FakeCollectionView!

        let webView = UIWebView(frame: CGRectMake(0, 0, 320, 640))
        let textSizeCalculator = FakeStreamTextCellSizeCalculator(webView: UIWebView(frame: webView.frame))
        let notificationSizeCalculator = FakeStreamNotificationCellSizeCalculator(webView: UIWebView(frame: webView.frame))
        let profileHeaderSizeCalculator = FakeProfileHeaderCellSizeCalculator(webView: UIWebView(frame: webView.frame))
        let imageSizeCalculator = StreamImageCellSizeCalculator()

        describe("StreamDataSourceSpec") {
            beforeEach {
                StreamKind.Following.setIsGridView(true)
                StreamKind.Starred.setIsGridView(false)
                vc = StreamViewController.instantiateFromStoryboard()
                vc.streamKind = StreamKind.Following
                subject = StreamDataSource(streamKind: .Following,
                    textSizeCalculator: textSizeCalculator,
                    notificationSizeCalculator: notificationSizeCalculator,
                    profileHeaderSizeCalculator: profileHeaderSizeCalculator,
                    imageSizeCalculator: imageSizeCalculator)

                subject.streamCollapsedFilter = { item in
                    if !item.type.collapsable {
                        return true
                    }
                    if let post = item.jsonable as? Post {
                        return !post.collapsed
                    }
                    return true
                }
                vc.dataSource = subject
                showController(vc)
                fakeCollectionView = FakeCollectionView(frame: vc.collectionView.frame, collectionViewLayout: vc.collectionView.collectionViewLayout)
            }

            afterEach {
                subject.removeAllCellItems()
            }

            describe("init(streamKind:textSizeCalculator:notificationSizeCalculator:profileHeaderSizeCalculator:)") {

                it("has streamKind") {
                    expect(subject.streamKind).toNot(beNil())
                }

                it("has textSizeCalculator") {
                    expect(subject.textSizeCalculator).toNot(beNil())
                }

                it("has notificationSizeCalculator") {
                    expect(subject.notificationSizeCalculator).toNot(beNil())
                }

                it("has profileHeaderSizeCalculator") {
                    expect(subject.profileHeaderSizeCalculator).toNot(beNil())
                }
            }

            context("appendUnsizedCellItems(_:, withWidth:, completion:)") {
                let post = Post.stub([:])
                let cellItems = [
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:])))
                ]

                beforeEach {
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in }
                }
                it("adds items") {
                    expect(subject.visibleCellItems.count) == cellItems.count
                }
                it("sizes the items") {
                    for item in cellItems {
                        expect(item.calculatedOneColumnCellHeight!) == AppSetup.Size.calculatorHeight
                    }
                }
            }

            context("appendStreamCellItems(_:)") {
                let post = Post.stub([:])
                let cellItems = [
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:])))
                ]

                beforeEach {
                    subject.appendStreamCellItems(cellItems)
                }
                it("adds items") {
                    expect(subject.visibleCellItems.count) == cellItems.count
                }
                it("does not size the items") {
                    for item in cellItems {
                        expect(item.calculatedOneColumnCellHeight).to(beNil())
                    }
                }
            }

            context("insertStreamCellItems(_:, startingIndexPath:)") {
                let post1 = Post.stub([:])
                let post2 = Post.stub([:])
                let firstCellItems = [
                    StreamCellItem(jsonable: post1, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post1, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post1, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post1, type: .Text(data: TextRegion.stub([:])))
                ]
                let secondCellItems = [
                    StreamCellItem(jsonable: post2, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post2, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post2, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post2, type: .Text(data: TextRegion.stub([:])))
                ]

                beforeEach {
                    subject.appendStreamCellItems(secondCellItems)
                    subject.insertStreamCellItems(firstCellItems, startingIndexPath: indexPath0)
                }
                it("inserts items") {
                    for (index, item) in (firstCellItems + secondCellItems).enumerate() {
                        expect(subject.visibleCellItems[index]) == item
                    }
                }
            }

            describe("collectionView(_:numberOfItemsInSection:)") {
                context("with posts") {
                    beforeEach {
                        // there should be 10 posts
                        // 10 * 3(number of cells for a post w/ 1 region) = 30
                        var posts = [Post]()
                        for index in 1...10 {
                            posts.append(Post.stub(["id": "\(index)"]))
                        }
                        let cellItems = StreamCellItemParser().parse(posts, streamKind: .Following)
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    it("returns the correct number of rows") {
                        expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 40
                    }
                }

                context("isValidIndexPath(_:)") {
                    beforeEach {
                        let item = StreamCellItem(jsonable: ElloComment.newCommentForPost(Post.stub([:]), currentUser: User.stub([:])), type: .CreateComment)
                        subject.appendStreamCellItems([item])
                    }
                    it("returns true for valid path (0, 0)") {
                        expect(subject.isValidIndexPath(NSIndexPath(forItem: 0, inSection: 0))) == true
                    }
                    it("returns true for valid path (items.count - 1, 0)") {
                        let idx = subject.visibleCellItems.count
                        expect(subject.isValidIndexPath(NSIndexPath(forItem: idx - 1, inSection: 0))) == true
                    }
                    it("returns false for invalid path (-1, 0)") {
                        expect(subject.isValidIndexPath(NSIndexPath(forItem: -1, inSection: 0))) == false
                    }
                    it("returns false for invalid path (items.count, 0)") {
                        let idx = subject.visibleCellItems.count
                        expect(subject.isValidIndexPath(NSIndexPath(forItem: idx, inSection: 0))) == false
                    }
                    it("returns false for invalid path (0, 1)") {
                        expect(subject.isValidIndexPath(NSIndexPath(forItem: 0, inSection: 1))) == false
                    }
                }

                context("with reposts") {
                    var posts = [Post]()
                    for index in 1...10 {
                        posts.append(Post.stub([
                            "id": "\(index)",
                            "repostContent": [TextRegion.stub([:]), TextRegion.stub([:])],
                            "content": [TextRegion.stub([:]), TextRegion.stub([:])]
                            ])
                        )
                    }
                    context("Following stream") {
                        beforeEach {
                            let cellItems = StreamCellItemParser().parse(posts, streamKind: .Following)
                            subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                                vc.collectionView.dataSource = subject
                                vc.collectionView.reloadData()
                            }
                        }
                        it("returns the correct number of rows") {
                            // there should be 10 reposts
                            // 10 * 4(number of cells for a repost w/ 2 regions) = 40
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 40
                        }
                    }

                    context("Starred stream") {
                        beforeEach {
                            let cellItems = StreamCellItemParser().parse(posts, streamKind: .Starred)
                            subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                                vc.collectionView.dataSource = subject
                                vc.collectionView.reloadData()
                            }
                        }

                        it("returns the correct number of rows") {
                            // there should be 10 reposts
                            // 10 * 7(number of cells for a repost w/ 2 regions) = 70
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 70
                        }
                    }
                }


                context("with collapsed and non collapsed posts") {
                    beforeEach {
                        var posts = [Post]()
                        // there should be 5 collapsed and 5 non collapsed
                        // 5 * 5(number of cells for non collapsed w/ 3 regions) = 25
                        // 5 * 3(number of cells for collapsed) = 15
                        // thus the 40
                        for index in 1...10 {
                            posts.append(Post.stub([
                                "id": "\(index)",
                                "contentWarning": index % 2 == 0 ? "" : "NSFW",
                                "summary": [TextRegion.stub([:]), TextRegion.stub([:]), TextRegion.stub([:])],
                                "content": [TextRegion.stub([:]), TextRegion.stub([:]), TextRegion.stub([:])],
                                ])
                            )
                        }
                        let cellItems = StreamCellItemParser().parse(posts, streamKind: .Starred)
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    it("returns the correct number of rows") {
                        expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 50
                    }
                }
            }

            describe("indexPathForItem(_:)") {
                var postItem: StreamCellItem!
                beforeEach {
                    let cellItems = StreamCellItemParser().parse([Post.stub([:])], streamKind: .Following)
                    postItem = cellItems[0]
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns an indexPath") {
                    expect(subject.indexPathForItem(postItem)).to(beAKindOf(NSIndexPath.self))
                }

                it("returns nil when cell doesn't exist") {
                    let anyItem = StreamCellItem(jsonable: ElloComment.stub([:]), type: .SeeMoreComments)
                    expect(subject.indexPathForItem(anyItem)).to(beNil())
                }

                it("returns nil when cell is hidden") {
                    subject.streamFilter = { postItem in return false }
                    expect(subject.indexPathForItem(postItem)).to(beNil())
                }

                it("returns the correct indexPath for same StreamCellItem Placeholder Types") {
                    let testItem = StreamCellItem(type: .Placeholder)
                    testItem.placeholderType = .PostHeader
                    let testItem2 = StreamCellItem(type: .Placeholder)
                    testItem2.placeholderType = .PostHeader

                    subject.removeAllCellItems()
                    subject.appendStreamCellItems([testItem])

                    expect(subject.indexPathForItem(testItem2)?.item) == 0
                }

                it("returns nil for same StreamCellItem Placeholder Types that are not the same") {
                    let testItem = StreamCellItem(type: .Placeholder)
                    testItem.placeholderType = .PostHeader
                    let testItem2 = StreamCellItem(type: .Placeholder)
                    testItem2.placeholderType = .CategoryList
                    subject.removeAllCellItems()
                    subject.appendStreamCellItems([testItem])

                    expect(subject.indexPathForItem(testItem2)).to(beNil())
                }
            }

            describe("indpexPathsForPlaceholderType(_:)") {

                beforeEach {
                    let user = User.stub([:])

                    let profileHeaderItems = [
                        StreamCellItem(jsonable: user, type: .ProfileHeader, placeholderType: .ProfileHeader),
                        StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 3), placeholderType: .ProfileHeader),
                        StreamCellItem(jsonable: user, type: .ColumnToggle, placeholderType: .ProfileHeader),
                        StreamCellItem(jsonable: user, type: .FullWidthSpacer(height: 5), placeholderType: .ProfileHeader),
                    ]

                    let postItems = [
                        StreamCellItem(type: .Header, placeholderType: .ProfilePosts),
                        StreamCellItem(type: .Footer, placeholderType: .ProfilePosts),
                    ]


                    subject.removeAllCellItems()
                    subject.appendStreamCellItems(profileHeaderItems + postItems)
                }

                it("returns the correct indexPaths for profile header") {
                    let headerIndexPaths = subject.indexPathsForPlaceholderType(.ProfileHeader)

                    expect(headerIndexPaths[0].item) == 0
                    expect(headerIndexPaths[1].item) == 1
                    expect(headerIndexPaths[2].item) == 2
                    expect(headerIndexPaths[3].item) == 3
                }

                it("returns the correct indexPaths for profile posts") {
                    let postIndexPaths = subject.indexPathsForPlaceholderType(.ProfilePosts)

                    expect(postIndexPaths[0].item) == 4
                    expect(postIndexPaths[1].item) == 5
                }
            }

            describe("postForIndexPath(_:)") {

                beforeEach {
                    let cellItems = StreamCellItemParser().parse([Post.stub([:])], streamKind: .Following)
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns a post") {
                    expect(subject.postForIndexPath(indexPath0)).to(beAKindOf(Post.self))
                }

                it("returns nil when out of bounds") {
                    expect(subject.postForIndexPath(indexPathOutOfBounds)).to(beNil())
                }

                it("returns nil when invalid section") {
                    expect(subject.postForIndexPath(indexPathInvalidSection)).to(beNil())
                }
            }

            describe("imageAssetForIndexPath(_:)") {

                beforeEach {
                    let asset = Asset.stub([:])
                    let region = ImageRegion.stub(["asset": asset])
                    let post = Post.stub([
                        "summary": [region],
                        "content": [region],
                    ])
                    let cellItems = StreamCellItemParser().parse([post], streamKind: .Following)
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns an image asset") {
                    expect(subject.imageAssetForIndexPath(NSIndexPath(forItem: 1, inSection: 0))).to(beAKindOf(Asset.self))
                }

                it("returns nil when out of bounds") {
                    expect(subject.imageAssetForIndexPath(indexPathOutOfBounds)).to(beNil())
                }

                it("returns nil when invalid section") {
                    expect(subject.imageAssetForIndexPath(indexPathInvalidSection)).to(beNil())
                }
            }

            describe("commentForIndexPath(_:)") {

                beforeEach {
                    let cellItems = StreamCellItemParser().parse([ElloComment.stub([:])], streamKind: .Following)
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns a comment") {
                    expect(subject.commentForIndexPath(indexPath0)).to(beAKindOf(ElloComment.self))
                }

                it("returns nil when out of bounds") {
                    expect(subject.commentForIndexPath(indexPathOutOfBounds)).to(beNil())
                }

                it("returns nil when invalid section") {
                    expect(subject.commentForIndexPath(indexPathInvalidSection)).to(beNil())
                }
            }

            describe("cellItemsForPost(_:)") {

                beforeEach {
                    let parser = StreamCellItemParser()
                    let postCellItems = parser.parse([Post.stub(["id": "666"])], streamKind: .Following)
                    let commentCellItems = parser.parse([ElloComment.stub(["parentPostId": "666"]), ElloComment.stub(["parentPostId": "666"])], streamKind: .Following)
                    let otherPostCellItems = parser.parse([Post.stub(["id": "777"])], streamKind: .Following)
                    let cellItems = postCellItems + commentCellItems + otherPostCellItems
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns an array of StreamCellItems") {
                    let post = subject.postForIndexPath(indexPath0)!
                    let items = subject.cellItemsForPost(post)
                    expect(items.count) == 4
                    for item in subject.visibleCellItems {
                        if items.contains(item) {
                            let itemPost = item.jsonable as! Post
                            expect(itemPost.id) == post.id
                        }
                        else {
                            if let itemPost = item.jsonable as? Post {
                                expect(itemPost.id) != post.id
                            }
                        }
                    }
                }

                it("returns empty array if post not found") {
                    let randomPost: Post = stub(["id": "notfound"])
                    let items = subject.cellItemsForPost(randomPost)
                    expect(items.count) == 0
                }

                it("does not return cell items for other posts") {
                    let post = subject.postForIndexPath(NSIndexPath(forItem: 9, inSection: 0))!
                    let items = subject.cellItemsForPost(post)
                    expect(post.id) == "777"
                    expect(items.count) == 4
                }

            }

            describe("userForIndexPath(_:)") {
                context("Returning a user-jsonable subject") {
                    beforeEach {
                        let userStreamKind = StreamKind.SimpleStream(endpoint: ElloAPI.UserStream(userParam: "42"), title: "yup")
                        let cellItems = StreamCellItemParser().parse([User.stub(["id": "42"])], streamKind: userStreamKind)
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    it("returns a user") {
                        expect(subject.userForIndexPath(indexPath0)).to(beAKindOf(User.self))
                    }
                    it("returns user 42") {
                        if let user = subject.userForIndexPath(indexPath0) {
                            expect(user.id) == "42"
                        }
                    }

                    it("returns nil when out of bounds") {
                        expect(subject.userForIndexPath(indexPathOutOfBounds)).to(beNil())
                    }

                    it("returns nil when invalid section") {
                        expect(subject.userForIndexPath(indexPathInvalidSection)).to(beNil())
                    }
                }
                context("Returning an author subject") {
                    beforeEach {
                        let cellItems = StreamCellItemParser().parse([Post.stub(["author": User.stub(["id": "42"])])], streamKind: .Following)
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    it("returns a user") {
                        expect(subject.userForIndexPath(indexPath0)).to(beAKindOf(User.self))
                    }
                    it("returns user 42") {
                        if let user = subject.userForIndexPath(indexPath0) {
                            expect(user.id) == "42"
                        }
                    }

                    it("returns nil when out of bounds") {
                        expect(subject.userForIndexPath(indexPathOutOfBounds)).to(beNil())
                    }

                    it("returns nil when invalid section") {
                        expect(subject.userForIndexPath(indexPathInvalidSection)).to(beNil())
                    }
                }
                context("Returning a repostAuthor subject") {
                    beforeEach {
                        let repost = Post.stub([
                                "id": "\(index)",
                                "repostAuthor": User.stub(["id": "42"]),
                                "repostContent": [TextRegion.stub([:]), TextRegion.stub([:])],
                                "content": [TextRegion.stub([:]), TextRegion.stub([:])]
                                ])

                        let cellItems = StreamCellItemParser().parse([repost], streamKind: .Following)
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    it("returns a user") {
                        expect(subject.userForIndexPath(indexPath0)).to(beAKindOf(User.self))
                    }
                    it("returns user 42") {
                        if let user = subject.userForIndexPath(indexPath0) {
                            expect(user.id) == "42"
                        }
                    }

                    it("returns nil when out of bounds") {
                        expect(subject.userForIndexPath(indexPathOutOfBounds)).to(beNil())
                    }

                    it("returns nil when invalid section") {
                        expect(subject.userForIndexPath(indexPathInvalidSection)).to(beNil())
                    }
                }
            }

            describe("commentIndexPathsForPost(_:)") {

                beforeEach {
                    var cellItems = [StreamCellItem]()
                    let parser = StreamCellItemParser()
                    // creates 4 cells
                    let post1CellItems = parser.parse([Post.stub(["id": "666"])], streamKind: .Following)
                    cellItems = post1CellItems
                    // creates 4 cells 2x2
                    let comment1CellItems = parser.parse([ElloComment.stub(["parentPostId": "666"]), ElloComment.stub(["parentPostId": "666"])], streamKind: .Following)
                    cellItems += comment1CellItems
                    // one cell
                    let seeMoreCellItem = StreamCellItem(jsonable: ElloComment.stub(["parentPostId": "666"]), type: .SeeMoreComments)
                    cellItems.append(seeMoreCellItem)
                    // creates 4 cells
                    let post2CellItems = parser.parse([Post.stub(["id": "777"])], streamKind: .Following)
                    cellItems += post2CellItems
                    // creates 2 cells
                    let comment2CellItems = parser.parse([ElloComment.stub(["parentPostId": "777"])], streamKind: .Following)
                    cellItems += comment2CellItems
                    // creates 5 cells
                    let post3CellItems = parser.parse([Post.stub(["id": "888", "contentWarning": "NSFW"])], streamKind: .Following)
                    cellItems += post3CellItems
                    // create 1 cell
                    let createCommentCellItem = StreamCellItem(jsonable: ElloComment.stub(["parentPostId": "888"]), type: .CreateComment)
                    cellItems.append(createCommentCellItem)
                    // creates 2 cells
                    let comment3CellItems = parser.parse([ElloComment.stub(["parentPostId": "888"])], streamKind: .Following)
                    cellItems += comment3CellItems
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns an array of comment index paths") {
                    let post = subject.postForIndexPath(indexPath0)
                    let indexPaths = subject.commentIndexPathsForPost(post!)

                    expect(indexPaths.count) == 5
                    expect(indexPaths[0].item) == 4
                    expect(indexPaths[1].item) == 5
                    expect(indexPaths[2].item) == 6
                    expect(indexPaths[3].item) == 7
                    expect(indexPaths[4].item) == 8
                }

                it("does not return index paths for comments from another post") {
                    let post = subject.postForIndexPath(NSIndexPath(forItem: 9, inSection: 0))
                    let indexPaths = subject.commentIndexPathsForPost(post!)

                    expect(indexPaths.count) == 2
                    expect(indexPaths[0].item) == 13
                    expect(indexPaths[1].item) == 14
                }

                it("returns an array of comment index paths when collapsed") {
                    let post = subject.postForIndexPath(NSIndexPath(forItem: 16, inSection: 0))
                    let indexPaths = subject.commentIndexPathsForPost(post!)

                    expect(indexPaths.count) == 3
                    expect(indexPaths[0].item) == 19
                    expect(indexPaths[1].item) == 20
                    expect(indexPaths[2].item) == 21
                }
            }

            describe("footerIndexPathForPost(_:)") {
                beforeEach {
                    let cellItems = StreamCellItemParser().parse([Post.stub(["id": "456"])], streamKind: .Following)
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns the index path of the footer associated with this post") {
                    let post = subject.postForIndexPath(indexPath0)
                    let indexPath = subject.footerIndexPathForPost(post!)

                    expect(indexPath!.item) == 2
                    expect(subject.visibleCellItems[indexPath!.item].type) == StreamCellType.Footer
                }
            }

           describe("modifyItems(_:change:collectionView:)") {

                context("with comments") {

                    let stubCommentCellItems: (commentsVisible: Bool) -> Void = { (commentsVisible: Bool) in
                        let parser = StreamCellItemParser()
                        let postCellItems = parser.parse([Post.stub(["id": "456"])], streamKind: .Following)
                        let commentButtonCellItem = [StreamCellItem(jsonable: ElloComment.stub(["parentPostId": "456"]), type: .CreateComment)]
                        let commentCellItems = parser.parse([ElloComment.stub(["parentPostId": "456", "id" : "111"])], streamKind: .Following)
                        var cellItems = postCellItems
                        if commentsVisible {
                            cellItems = cellItems + commentButtonCellItem + commentCellItems
                        }
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    describe(".Create") {

                        it("inserts the new comment") {
                            stubCommentCellItems(commentsVisible: true)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 7
                            subject.modifyItems(ElloComment.stub(["id": "new_comment", "parentPostId": "456"]), change: .Create, collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 9
                            expect(subject.commentForIndexPath(NSIndexPath(forItem: 5, inSection: 0))!.id) == "new_comment"
                        }

                        it("doesn't insert the new comment") {
                            stubCommentCellItems(commentsVisible: false)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 4
                            subject.modifyItems(ElloComment.stub(["id": "new_comment", "parentPostId": "456"]), change: .Create, collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 4
                        }

                    }

                    describe(".Delete") {

                        it("removes the deleted comment") {
                            stubCommentCellItems(commentsVisible: true)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 7
                            subject.modifyItems(ElloComment.stub(["id": "111", "parentPostId": "456"]), change: .Delete, collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 5

                        }

                        it("doesn't remove the deleted comment") {
                            stubCommentCellItems(commentsVisible: false)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 4
                            subject.modifyItems(ElloComment.stub(["id": "111", "parentPostId": "456"]), change: .Delete, collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 4
                        }

                    }
                }

                context("with posts") {

                    beforeEach {
                        var posts = [Post]()
                        for index in 1...5 {
                            posts.append(Post.stub([
                                "id": "\(index)",
                                "commentsCount" : 5,
                                "content": [TextRegion.stub([:])]
                                ])
                            )
                        }

                        let cellItems = StreamCellItemParser().parse(posts, streamKind: .Following)
                        subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    describe(".Create") {

                        context("StreamKind.Following") {

                            it("inserts the new post at 1, 0") {
                                subject.streamKind = .Following
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                                subject.modifyItems(Post.stub(["id": "new_post"]), change: .Create, collectionView: fakeCollectionView)
                                expect(subject.postForIndexPath(indexPath1)!.id) == "new_post"
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 24
                            }

                        }

                        context("StreamKind.Profile") {

                            it("inserts the new post at 4, 0") {
                                subject.streamKind = .CurrentUserStream
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                                subject.modifyItems(Post.stub(["id": "new_post"]), change: .Create, collectionView: fakeCollectionView)
                                expect(subject.postForIndexPath(indexPath0)!.id) == "1"
                                expect(subject.postForIndexPath(NSIndexPath(forItem: 4, inSection: 0))!.id) == "new_post"
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 24
                            }

                        }

                        context("StreamKind.UserStream") {

                            it("inserts the new post at 4, 0") {
                                subject.currentUser = User.stub(["id" : "user-id-here"])
                                subject.streamKind = .UserStream(userParam: "user-id-here")

                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20

                                subject.modifyItems(Post.stub(["id": "new_post"]), change: .Create, collectionView: fakeCollectionView)

                                expect(subject.postForIndexPath(indexPath0)!.id) == "1"
                                expect(subject.postForIndexPath(NSIndexPath(forItem: 4, inSection: 0))!.id) == "new_post"
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 24
                            }

                            it("does not insert a post in other user's profiles") {
                                subject.currentUser = User.stub(["id" : "not-current-user-id-here"])
                                subject.streamKind = .UserStream(userParam: "user-id-here")

                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20

                                subject.modifyItems(Post.stub(["id": "new_post"]), change: .Create, collectionView: fakeCollectionView)

                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                            }
                        }

                        context("StreamKind.Starred") {

                            it("does not insert a post") {
                                subject.streamKind = .Starred

                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20

                                subject.modifyItems(Post.stub(["id": "new_post"]), change: .Create, collectionView: fakeCollectionView)

                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                            }
                        }

                        context("StreamKind.Loves") {

                            it("adds the newly loved post") {
                                subject.streamKind = StreamKind.SimpleStream(endpoint: ElloAPI.Loves(userId: "fake-id"), title: "Loves")
                                let love: Love = stub(["id": "love1", "postId": "post1"])
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20

                                subject.modifyItems(love, change: .Create, collectionView: fakeCollectionView)

                                expect(subject.postForIndexPath(indexPath1)!.id) == "post1"
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 24
                            }
                        }
                    }

                    describe(".Delete") {

                        beforeEach {
                            subject.streamKind = .Following
                        }

                        it("removes the deleted post") {
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                            subject.modifyItems(Post.stub(["id": "1"]), change: .Delete, collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 16
                        }

                        it("doesn't remove the deleted comment") {
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                            subject.modifyItems(Post.stub(["id": "not-present"]), change: .Delete, collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                        }
                    }

                    describe(".Update") {

                        beforeEach {
                            subject.streamKind = .Following
                        }

                        it("updates the updated post") {
                            expect(subject.postForIndexPath(NSIndexPath(forItem: 4, inSection: 0))!.commentsCount) == 5
                            subject.modifyItems(Post.stub(["id": "2", "commentsCount" : 9]), change: .Update, collectionView: fakeCollectionView)
                            expect(subject.postForIndexPath(NSIndexPath(forItem: 4, inSection: 0))!.commentsCount) == 9
                        }

                        it("doesn't update the updated post") {
                            subject.modifyItems(Post.stub(["id": "not-present", "commentsCount" : 88]), change: .Update, collectionView: fakeCollectionView)

                            for item in subject.streamCellItems {
                                // this check gets around the fact that there are spacers in posts
                                if let post = item.jsonable as? Post {
                                    expect(post.commentsCount) == 5
                                }
                            }
                        }

                        context("StreamKind.Loves") {

                            beforeEach {
                                subject.streamKind = StreamKind.SimpleStream(endpoint: ElloAPI.Loves(userId: "fake-id"), title: "Loves")
                            }

                            it("removes the unloved post") {
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 20
                                subject.modifyItems(Post.stub(["id": "2", "commentsCount" : 9, "loved" : false]), change: .Update, collectionView: fakeCollectionView)
                                expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 16
                            }
                        }
                    }
                }
            }

            describe("modifyUserRelationshipItems(_:collectionView:)") {

                let stubCellItems: (streamKind: StreamKind) -> Void = { streamKind in
                    let user1: User = stub(["id": "user1"])
                    let post1: Post = stub(["id": "post1", "authorId" : "user1"])
                    let post1Comment1: ElloComment = stub([
                        "parentPost": post1,
                        "id" : "comment1",
                        "authorId": "user1"
                    ])
                    let post1Comment2: ElloComment = stub([
                        "parentPost": post1,
                        "id" : "comment2",
                        "authorId": "user2"
                    ])
                    let parser = StreamCellItemParser()
                    let userCellItems = parser.parse([user1], streamKind: streamKind)
                    let post1CellItems = parser.parse([post1], streamKind: streamKind)
                    let post1CommentCellItems = parser.parse([post1Comment1, post1Comment2], streamKind: streamKind)
                    let cellItems = userCellItems + post1CellItems + post1CommentCellItems
                    subject.streamKind = streamKind
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                describe("blocking a user") {

                    context("blocked user is the post author") {
                        it("removes blocked user, their post and all comments on that post") {
                            stubCellItems(streamKind: StreamKind.SimpleStream(endpoint: ElloAPI.FriendStream, title: "some title"))
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 9
                            subject.modifyUserRelationshipItems(User.stub(["id": "user1", "relationshipPriority": RelationshipPriority.Block.rawValue]), collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 0
                        }
                    }

                    context("blocked user is not the post author") {
                        it("removes blocked user's comments") {
                            stubCellItems(streamKind: StreamKind.SimpleStream(endpoint: ElloAPI.FriendStream, title: "some title"))
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 9
                            subject.modifyUserRelationshipItems(User.stub(["id": "user2", "relationshipPriority": RelationshipPriority.Block.rawValue]), collectionView: fakeCollectionView)
                            expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 7
                        }
                    }

                    it("does not remove cells tied to other users") {
                        stubCellItems(streamKind: StreamKind.SimpleStream(endpoint: ElloAPI.FriendStream, title: "some title"))
                        expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 9
                        subject.modifyUserRelationshipItems(User.stub(["id": "unrelated-user", "relationshipPriority": RelationshipPriority.Block.rawValue]), collectionView: fakeCollectionView)
                        expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 9
                    }

                }

                describe("friending/noising/inactivating a user") {

                    it("updates posts from that user") {
                        stubCellItems(streamKind: StreamKind.SimpleStream(endpoint: ElloAPI.FriendStream, title: "some title"))
                        var user1 = subject.userForIndexPath(indexPath0)!
                        expect(user1.followersCount) == "stub-user-followers-count"
                        expect(user1.relationshipPriority.rawValue) == RelationshipPriority.None.rawValue
                        subject.modifyUserRelationshipItems(User.stub(["id": "user1", "followersCount": "2", "followingCount": 2, "relationshipPriority": RelationshipPriority.Following.rawValue]), collectionView: fakeCollectionView)
                        user1 = subject.userForIndexPath(indexPath0)!
                        expect(user1.followersCount) == "2"
                        expect(user1.relationshipPriority.rawValue) == RelationshipPriority.Following.rawValue
                    }

                    it("shows the star on the avatarButton") {
                        stubCellItems(streamKind: StreamKind.SimpleStream(endpoint: ElloAPI.FriendStream, title: "some title"))
                        subject.modifyUserRelationshipItems(User.stub(["id": "user1", "followersCount": "2", "followingCount": 2, "relationshipPriority": RelationshipPriority.Starred.rawValue]), collectionView: fakeCollectionView)
                        let indexPath = NSIndexPath(forItem: 1, inSection: 0)
                        let headerCellItem = subject.visibleStreamCellItem(at: indexPath)!
                        let post = headerCellItem.jsonable as? Post
                        expect(post?.author?.relationshipPriority) == .Starred
                    }

                    xit("updates comments from that user") {
                        // comments are not yet affected by User.RelationshipPriority changes
                        // left intentionally empty for documentation
                    }

                    it("updates cells tied to that user") {

                    }
                }

                describe("muting a user") {

                    beforeEach {
                        let streamKind: StreamKind = .Notifications(category: nil)
                        let user1: User = stub(["id": "user1"])
                        let post1: Post = stub(["id": "post1", "authorId" : "other-user"])
                        let activity1: Activity = stub(["id": "activity1", "subject" : user1])
                        let activity2: Activity = stub(["id": "activity2", "subject" : post1])
                        let parser = StreamCellItemParser()
                        let notificationCellItems = parser.parse([activity1, activity2], streamKind: streamKind)
                        subject.streamKind = streamKind
                        subject.appendUnsizedCellItems(notificationCellItems, withWidth: webView.frame.width) { cellCount in
                            vc.collectionView.dataSource = subject
                            vc.collectionView.reloadData()
                        }
                    }

                    it("clears out notifications from that user when on notifications") {
                        expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 2
                        subject.modifyUserRelationshipItems(User.stub(["id": "user1", "relationshipPriority": RelationshipPriority.Mute.rawValue]), collectionView: fakeCollectionView)
                        expect(subject.collectionView(vc.collectionView, numberOfItemsInSection: 0)) == 1
                    }

                    it("does not clear out content from that user when elsewhere") {

                    }
                }

            }

            describe("modifyUserSettingsItems(_:collectionView:)") {

                let stubCellItems: (streamKind: StreamKind) -> Void = { streamKind in
                    let user1: User = stub(["id": "user1", "username": "sweet"])
                    let user2: User = stub(["id": "user2", "username": "unsweet"])
                    let userCellItems = StreamCellItemParser().parse([user1, user2], streamKind: streamKind)
                    let cellItems = userCellItems
                    subject.streamKind = streamKind
                    subject.appendUnsizedCellItems(cellItems, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                context("modifies a user when it is the currentUser") {
                    it("removes blocked user, their post and all comments on that post") {
                        stubCellItems(streamKind: StreamKind.SimpleStream(endpoint: ElloAPI.FriendStream, title: "some title"))
                        expect(subject.userForIndexPath(indexPath0)!.username) == "sweet"
                        subject.modifyUserSettingsItems(User.stub(["id": "user1", "username": "sweetness"]), collectionView: fakeCollectionView)
                        expect(subject.userForIndexPath(indexPath0)!.username) == "sweetness"
                    }
                }
            }

            describe("createCommentIndexPathForPost(_:)") {
                var post: Post!
                beforeEach {
                    var items = [StreamCellItem]()
                    let parser = StreamCellItemParser()
                    post = Post.stub(["id": "666"])
                    items += parser.parse([post], streamKind: .Following)
                    items.append(StreamCellItem(jsonable: ElloComment.newCommentForPost(post, currentUser: User.stub([:])), type: .CreateComment))
                    items += parser.parse([ElloComment.stub(["parentPostId": "666"]), ElloComment.stub(["parentPostId": "666"])], streamKind: .Following)
                    items += parser.parse([Post.stub(["id": "777"])], streamKind: .Following)
                    items += parser.parse([ElloComment.stub(["parentPostId": "777"])], streamKind: .Following)

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("points to a create-comment-item") {
                    if let path = subject.createCommentIndexPathForPost(post),
                        let item = subject.visibleStreamCellItem(at: path)
                    {
                            expect(item.type).to(equal(StreamCellType.CreateComment))
                    }
                    else {
                        fail("no CreateComment StreamCellItem found")
                    }
                }

            }

            describe("-removeCommentsForPost:") {
                var post: Post!
                beforeEach {
                    var items = [StreamCellItem]()
                    let parser = StreamCellItemParser()
                    post = Post.stub(["id": "666"])
                    items += parser.parse([post], streamKind: .Following)
                    items.append(StreamCellItem(jsonable: ElloComment.newCommentForPost(post, currentUser: User.stub([:])), type: .CreateComment))
                    items += parser.parse([ElloComment.stub(["parentPostId": "666"]), ElloComment.stub(["parentPostId": "666"])], streamKind: .Following)
                    items += parser.parse([Post.stub(["id": "777"])], streamKind: .Following)
                    items += parser.parse([ElloComment.stub(["parentPostId": "777"])], streamKind: .Following)

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("removes comment index paths") {
                    let indexPaths = subject.removeCommentsForPost(post)

                    expect(indexPaths.count) > 0
                    expect(subject.commentIndexPathsForPost(post)).to(beEmpty())
                }

            }

            describe("-updateHeightForIndexPath:") {
                beforeEach {
                    var items = [StreamCellItem]()
                    let parser = StreamCellItemParser()
                    items += parser.parse([Post.stub(["id": "666", "content": [TextRegion.stub([:])]])], streamKind: .Following)

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("updates the height of an existing StreamCellItem") {
                    let indexPath = NSIndexPath(forItem: 1, inSection: 0)
                    subject.updateHeightForIndexPath(indexPath, height: 256)

                    let cellItem = subject.visibleStreamCellItem(at: indexPath)
                    expect(cellItem!.calculatedOneColumnCellHeight!) == 256
                    expect(cellItem!.calculatedMultiColumnCellHeight!) == 256
                }

                it("handles non-existent index paths") {
                    expect(subject.updateHeightForIndexPath(indexPathOutOfBounds, height: 256))
                        .notTo(raiseException())
                }

                it("handles invalid section") {
                    expect(subject.updateHeightForIndexPath(indexPathInvalidSection, height: 256))
                        .notTo(raiseException())
                }
            }

            describe("-heightForIndexPath:numberOfColumns") {
                beforeEach {
                    var items = [StreamCellItem]()
                    items.append(StreamCellItem(jsonable: ElloComment.stub([:]), type: .CreateComment))

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }
                it("returns the correct height") {
                    expect(subject.heightForIndexPath(indexPath0, numberOfColumns: 1)) == 75.0
                    expect(subject.heightForIndexPath(indexPath0, numberOfColumns: 2)) == 75.0
                }

                it("returns 0 when out of bounds") {
                    expect(subject.heightForIndexPath(indexPathOutOfBounds, numberOfColumns: 0)) == 0
                }

                it("returns 0 when invalid section") {
                    expect(subject.heightForIndexPath(indexPathInvalidSection, numberOfColumns: 0)) == 0
                }
            }

            describe("removeItemAtIndexPath(_: NSIndexPath)") {
                let post = Post.stub([:])
                let items = [
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:])))
                ]
                beforeEach {
                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in }
                }
                it("should allow removing an item from the beginning") {
                    subject.removeItemAtIndexPath(indexPath0)
                    expect(subject.visibleCellItems.count) == items.count - 1
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index + 1]
                    }
                }
                it("should allow removing an item from the end") {
                    subject.removeItemAtIndexPath(NSIndexPath(forItem: items.count - 1, inSection: 0))
                    expect(subject.visibleCellItems.count) == items.count - 1
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index]
                    }
                }
                it("should ignore removing invalid index paths") {
                    subject.removeItemAtIndexPath(indexPathOutOfBounds)
                    expect(subject.visibleCellItems.count) == items.count
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index]
                    }
                }
            }

            describe("removeItemAtIndexPaths(_: [NSIndexPath])") {
                let post = Post.stub([:])
                let items = [
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:]))),
                    StreamCellItem(jsonable: post, type: .Text(data: TextRegion.stub([:])))
                ]
                beforeEach {
                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in }
                }
                it("sanity check") {
                    expect(items[0]) == items[0]
                    expect(items[0]) != items[1]
                    expect(items[1]) == items[1]
                    expect(items[1]) != items[2]
                    expect(items[2]) == items[2]
                    expect(items[2]) != items[3]
                    expect(items[3]) == items[3]
                    expect(items[3]) != items[0]
                }
                it("should allow removing items from the beginning") {
                    subject.removeItemAtIndexPaths([indexPath0, indexPath1])
                    expect(subject.visibleCellItems.count) == items.count - 2
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index + 2]
                    }
                }
                it("should allow removing items from the beginning, reverse order") {
                    subject.removeItemAtIndexPaths([indexPath1, indexPath0])
                    expect(subject.visibleCellItems.count) == items.count - 2
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index + 2]
                    }
                }
                it("should allow removing items from the end") {
                    subject.removeItemAtIndexPaths([NSIndexPath(forItem: items.count - 2, inSection: 0), NSIndexPath(forItem: items.count - 1, inSection: 0)])
                    expect(subject.visibleCellItems.count) == items.count - 2
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index]
                    }
                }
                it("should allow removing items from the end, reverse order") {
                    subject.removeItemAtIndexPaths([NSIndexPath(forItem: items.count - 1, inSection: 0), NSIndexPath(forItem: items.count - 2, inSection: 0)])
                    expect(subject.visibleCellItems.count) == items.count - 2
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index]
                    }
                }
                it("should allow removing items from the middle") {
                    subject.removeItemAtIndexPaths([indexPath1, NSIndexPath(forItem: 2, inSection: 0)])
                    expect(subject.visibleCellItems.count) == items.count - 2
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        if index == 0 {
                            expect(item) == items[index]
                        }
                        else {
                            expect(item) == items[index + 2]
                        }
                    }
                }
                it("should allow removing items from the middle, reverse order") {
                    subject.removeItemAtIndexPaths([NSIndexPath(forItem: 2, inSection: 0), indexPath1])
                    expect(subject.visibleCellItems.count) == items.count - 2
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        if index == 0 {
                            expect(item) == items[index]
                        }
                        else {
                            expect(item) == items[index + 2]
                        }
                    }
                }
                it("should ignore removing invalid index paths") {
                    subject.removeItemAtIndexPaths([indexPathOutOfBounds])
                    expect(subject.visibleCellItems.count) == items.count
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        expect(item) == items[index]
                    }
                }
            }

            describe("removeAllCellItems()") {

                beforeEach {
                    var items = [StreamCellItem]()
                    items.append(StreamCellItem(jsonable: ElloComment.stub([:]), type: .CreateComment))

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("sets the number of visible cell items to 0") {
                    expect(subject.visibleCellItems.count) > 0
                    subject.removeAllCellItems()
                    expect(subject.visibleCellItems.count) == 0
                }

                it("sets the number of cell items to 0") {
                    expect(subject.streamCellItems.count) > 0
                    subject.removeAllCellItems()
                    expect(subject.streamCellItems.count) == 0
                }
            }

            describe("-visibleStreamCellItem:") {

                beforeEach {
                    var items = [StreamCellItem]()
                    items.append(StreamCellItem(jsonable: ElloComment.stub([:]), type: .CreateComment))

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns the correct stream cell item") {
                    let item = subject.visibleStreamCellItem(at: NSIndexPath(forItem: 0, inSection:0))
                    expect(item?.type.name) == "StreamCreateCommentCell"
                }

                it("returns nil if indexpath does not exist") {
                    let item = subject.visibleStreamCellItem(at: NSIndexPath(forItem: 50, inSection:0))
                    expect(item).to(beNil())
                }

                it("returns nil if a filter (returns false) is active") {
                    subject.streamFilter = { _ in return false }
                    let itemExists = subject.streamCellItems.safeValue(0)
                    expect(itemExists?.type.name) == "StreamCreateCommentCell"
                    let itemHidden = subject.visibleStreamCellItem(at: NSIndexPath(forItem: 0, inSection:0))
                    expect(itemHidden).to(beNil())
                }

                it("returns item if a filter (returns true) is active") {
                    subject.streamFilter = { _ in return true }
                    let itemExists = subject.streamCellItems.safeValue(0)
                    expect(itemExists?.type.name) == "StreamCreateCommentCell"
                    let itemHidden = subject.visibleStreamCellItem(at: NSIndexPath(forItem: 0, inSection:0))
                    expect(itemHidden?.type.name) == "StreamCreateCommentCell"
                }
            }

            describe("-toggleCollapsedForIndexPath:") {
                var postToToggle: Post!
                var postNotToToggle: Post!

                beforeEach {
                    var items = [StreamCellItem]()
                    let parser = StreamCellItemParser()
                    postToToggle = Post.stub(["contentWarning" : "warning! b000000bs!", "content": [ImageRegion.stub([:])]])
                    postNotToToggle = Post.stub(["contentWarning" : "warning! b000000bs!", "content": [ImageRegion.stub([:])]])
                    items += parser.parse([postToToggle], streamKind: .Following)
                    items += parser.parse([postNotToToggle], streamKind: .Following)

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("toggles collapsed on the post at an indexPath") {
                    expect(postToToggle.collapsed).to(beTrue())
                    let toggledItems = subject.cellItemsForPost(postToToggle)
                    for item in toggledItems {
                        if item.type != .Footer {
                            expect(item.state) == StreamCellState.Collapsed
                        }
                    }
                    subject.toggleCollapsedForIndexPath(indexPath0)
                    for item in toggledItems {
                        if item.type != .Footer {
                            expect(item.state) == StreamCellState.Expanded
                        }
                    }
                }

                it("does not toggle collapsed on other posts") {
                    let indexPathToToggle = NSIndexPath(forItem: 0, inSection: 0)
                    let indexPathNotToToggle = NSIndexPath(forItem: 4, inSection: 0)

                    expect(postToToggle) == subject.postForIndexPath(indexPathToToggle)!
                    expect(postNotToToggle) == subject.postForIndexPath(indexPathNotToToggle)!

                    expect(postToToggle.collapsed).to(beTrue())
                    expect(postNotToToggle.collapsed).to(beTrue())

                    let toggledItems = subject.cellItemsForPost(postToToggle)
                    let notToggledItems = subject.cellItemsForPost(postNotToToggle)

                    for item in toggledItems + notToggledItems {
                        if item.type != .Footer {
                            expect(item.state) == StreamCellState.Collapsed
                        }
                    }
                    subject.toggleCollapsedForIndexPath(indexPathToToggle)
                    for item in toggledItems {
                        if item.type != .Footer {
                            expect(item.state) != StreamCellState.Collapsed
                        }
                    }
                    for item in notToggledItems {
                        if item.type != .Footer {
                            expect(item.state) == StreamCellState.Collapsed
                        }
                    }
                }
            }

            describe("-isFullWidthAtIndexPath:") {

                beforeEach {
                    let items = [
                        StreamCellItem(jsonable: ElloComment.stub([:]), type: .CreateComment),
                        StreamCellItem(jsonable: ElloComment.stub([:]), type: .CommentHeader)
                    ]
                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns true for Full Width items") {
                    let isFullWidth = subject.isFullWidthAtIndexPath(indexPath0)
                    expect(isFullWidth) == true
                }

                it("returns false for all other items") {
                    let indexPath = NSIndexPath(forItem: 1, inSection: 0)
                    let isFullWidth = subject.isFullWidthAtIndexPath(indexPath)
                    expect(isFullWidth) == false
                }

                it("returns true when out of bounds") {
                    expect(subject.isFullWidthAtIndexPath(indexPathOutOfBounds)) == true
                }

                it("returns true when invalid section") {
                    expect(subject.isFullWidthAtIndexPath(indexPathInvalidSection)) == true
                }

            }

            describe("-groupForIndexPath:") {
                var post: Post!
                beforeEach {
                    var items = [StreamCellItem]()
                    let parser = StreamCellItemParser()
                    post = Post.stub(["id": "666", "content": [TextRegion.stub([:])]])
                    items += parser.parse([post], streamKind: .Following)
                    items.append(StreamCellItem(jsonable: ElloComment.newCommentForPost(post, currentUser: User.stub([:])), type: .CreateComment))
                    items += parser.parse([ElloComment.stub(["parentPostId": "666"]), ElloComment.stub(["parentPostId": "666"])], streamKind: .Following)

                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("returns the same value for a post and it's comments") {
                    for (index, item) in subject.visibleCellItems.enumerate() {
                        let indexPath = NSIndexPath(forItem: index, inSection: 0)
                        let groupId = subject.groupForIndexPath(indexPath)
                        if item.jsonable is Post || item.jsonable is ElloComment {
                            expect(groupId) == post.id
                        }
                    }
                }

                it("does not return the same value for two different posts") {
                    let firstPostIndexPath = NSIndexPath(forItem: 0, inSection: 0)
                    let secondPostIndexPath = NSIndexPath(forItem: subject.visibleCellItems.count, inSection: 0)

                    let parser = StreamCellItemParser()
                    let post2 = Post.stub(["id": "555"])
                    let items = parser.parse([post2], streamKind: .Following)
                    subject.appendUnsizedCellItems(items, withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }

                    let firstGroupId = subject.groupForIndexPath(firstPostIndexPath)
                    let secondGroupId = subject.groupForIndexPath(secondPostIndexPath)

                    expect(firstGroupId) != secondGroupId
                }

                it("returns '0' if indexPath out of bounds") {
                    expect(subject.groupForIndexPath(indexPathOutOfBounds)) == "0"
                }

                it("returns '0' if invalid section") {
                    expect(subject.groupForIndexPath(indexPathInvalidSection)) == "0"
                }

                it("returns '0' if StreamCellItem's jsonable is not Groupable") {
                    let lastIndexPath = NSIndexPath(forItem: subject.visibleCellItems.count, inSection: 0)
                    let nonGroupable: Asset = stub(["id": "123"])

                    let item = StreamCellItem(jsonable: nonGroupable, type: .Image(data: ImageRegion.stub([:])))

                    subject.appendUnsizedCellItems([item], withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }

                    expect(subject.groupForIndexPath(lastIndexPath)) == "0"
                }
            }

            describe("insertUnsizedCellItems(_:, withWidth:, startingIndexPath:, completion:)") {
                var post: Post!
                var newCellItem: StreamCellItem!

                beforeEach {
                    post = Post.stub([:])
                    let toggleCellItem = StreamCellItem(jsonable: post, type: .Toggle)
                    let imageCellItem = StreamCellItem(jsonable: post, type: .Image(data: ImageRegion.stub([:])))
                    let anotherImageCellItem = StreamCellItem(jsonable: Post.stub([:]), type: .Image(data: ImageRegion.stub([:])))

                    let comment = ElloComment.newCommentForPost(post, currentUser: User.stub([:]))
                    newCellItem = StreamCellItem(jsonable: comment, type: .CreateComment)

                    subject.appendUnsizedCellItems([toggleCellItem, imageCellItem, anotherImageCellItem], withWidth: webView.frame.width) { cellCount in
                        vc.collectionView.dataSource = subject
                        vc.collectionView.reloadData()
                    }
                }

                it("inserts the new cellitems in the correct position") {
                    let countWas = subject.visibleCellItems.count
                    let startingIndexPath = NSIndexPath(forItem: 1, inSection: 0)

                    subject.insertUnsizedCellItems([newCellItem], withWidth: 10.0, startingIndexPath: startingIndexPath ){ _ in
                    }

                    let insertedCellItem = subject.visibleCellItems[1]

                    expect(subject.visibleCellItems.count) == countWas + 1
                    expect(insertedCellItem.type.name) == "StreamCreateCommentCell"
                }

                it("inserts the new cellitems in final position") {
                    let countWas = subject.visibleCellItems.count
                    let startingIndexPath = NSIndexPath(forItem: countWas, inSection: 0)

                    subject.insertUnsizedCellItems([newCellItem], withWidth: 10.0, startingIndexPath: startingIndexPath ){ _ in

                    }

                    let insertedCellItem = subject.visibleCellItems[countWas]

                    expect(subject.visibleCellItems.count) == countWas + 1
                    expect(insertedCellItem.type.name) == "StreamCreateCommentCell"
                }
            }

            context("elementsForJSONAble(_:, change:)") {
                let user1 = User.stub([:])
                let post1 = Post.stub([:])
                let comment1 = ElloComment.stub(["parentPost": post1])
                let user2 = User.stub([:])
                let post2 = Post.stub([:])
                let comment2 = ElloComment.stub(["parentPost": post2])
                beforeEach {
                    let cellItems = StreamCellItemParser().parseAllForTesting([
                        user1, post1, comment1,
                        user2, post2, comment2
                    ])
                    subject.appendUnsizedCellItems(cellItems, withWidth: 10.0) { (indexPaths) in
                    }
                }
                it("should return a post (object equality)") {
                    let items = subject.testingElementsForJSONAble(post1, change: .Create).1
                    for item in items {
                        expect(item.jsonable) == post1
                    }
                }
                it("should return a comment (object equality)") {
                    let items = subject.testingElementsForJSONAble(comment1, change: .Create).1
                    for item in items {
                        expect(item.jsonable) == comment1
                    }
                }
                it("should return post and comment (object equality, change = .Delete)") {
                    let items = subject.testingElementsForJSONAble(post1, change: .Delete).1
                    for item in items {
                        if item.jsonable is ElloComment {
                            expect(item.jsonable) == comment1
                        }
                        else {
                            expect(item.jsonable) == post1
                        }
                    }
                }
                it("should return a user (object equality)") {
                    let items = subject.testingElementsForJSONAble(user1, change: .Create).1
                    for item in items {
                        expect(item.jsonable) == user1
                    }
                }
                it("should return a post (id equality)") {
                    let items = subject.testingElementsForJSONAble(Post.stub(["id": post1.id]), change: .Create).1
                    for item in items {
                        expect(item.jsonable) == post1
                    }
                }
                it("should return a comment (id equality)") {
                    let items = subject.testingElementsForJSONAble(ElloComment.stub(["id": comment1.id]), change: .Create).1
                    for item in items {
                        expect(item.jsonable) == comment1
                    }
                }
                it("should return post and comment (id equality, change = .Delete)") {
                    let items = subject.testingElementsForJSONAble(Post.stub(["id": post1.id]), change: .Delete).1
                    for item in items {
                        if item.jsonable is ElloComment {
                            expect(item.jsonable) == comment1
                        }
                        else {
                            expect(item.jsonable) == post1
                        }
                    }
                }
                it("should return a user (id equality)") {
                    let items = subject.testingElementsForJSONAble(User.stub(["id": user1.id]), change: .Create).1
                    for item in items {
                        expect(item.jsonable) == user1
                    }
                }
                it("should return nothing (no matching post)") {
                    let items = subject.testingElementsForJSONAble(Post.stub([:]), change: .Create).1
                    expect(items) == []
                }
                it("should return nothing (no matching comment)") {
                    let items = subject.testingElementsForJSONAble(ElloComment.stub([:]), change: .Create).1
                    expect(items) == []
                }
                it("should return nothing (no matching user)") {
                    let items = subject.testingElementsForJSONAble(User.stub([:]), change: .Create).1
                    expect(items) == []
                }
            }
//
//            xdescribe("-collectionView:cellForItemAtIndexPath:") {
//
//                beforeEach {
//                    subject = StreamDataSource(streamKind: .Following,
//                        textSizeCalculator: textSizeCalculator,
//                        notificationSizeCalculator: notificationSizeCalculator,
//                        profileHeaderSizeCalculator: profileHeaderSizeCalculator)
//
//                    subject.appendUnsizedCellItems(ModelHelper.allCellTypes(), withWidth: webView.frame.width) { cellCount in
//                        vc.collectionView.dataSource = subject
//                        vc.collectionView.reloadData()
//                    }
//                }
//
//                describe("with posts") {
//                    it("returns a StreamHeaderCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(StreamHeaderCell.self))
//                    }
//
//                    it("returns a StreamTextCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 1, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(StreamToggleCell.self))
//                    }
//
//                    it("returns a StreamFooterCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 2, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(StreamTextCell.self))
//                    }
//                }
//
//                describe("with comments") {
//                    it("returns a StreamHeaderCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 3, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(StreamFooterCell.self))
//                    }
//
//                    it("returns a StreamTextCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 4, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(StreamHeaderCell.self))
//                    }
//                }
//
//                describe("with users") {
//                    it("returns a ProfileHeaderCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 5, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(StreamTextCell.self))
//                    }
//
//                    it("returns a UserListItemCell") {
//                        let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 6, inSection: 0))
//                        expect(cell).to(beAnInstanceOf(ProfileHeaderCell.self))
//                    }
//                }
//
//                it("returns a NotificationCell") {
//                    let notification: Notification = stub([:])
//                    let cellItem = StreamCellItem(jsonable: notification, type: .Notification)
//                    subject.appendUnsizedCellItems([cellItem], withWidth: webView.frame.width) { cellCount in
//                        vc.collectionView.dataSource = subject
//                        vc.collectionView.reloadData()
//                    }
//
//                    let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
//                    expect(cell).to(beAnInstanceOf(NotificationCell.self))
//                }
//
//                it("returns a StreamImageCell") {
//                    let post: Post = stub([:])
//                    let imageRegion: ImageRegion = stub([:])
//                    let cellItem = StreamCellItem(jsonable: post, type: .Image)
//                    subject.appendUnsizedCellItems([cellItem], withWidth: webView.frame.width) { cellCount in
//                        vc.collectionView.dataSource = subject
//                        vc.collectionView.reloadData()
//                    }
//
//                    let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
//                    expect(cell).to(beAnInstanceOf(StreamImageCell.self))
//                }
//
//                it("returns a StreamToggleCell") {
//                    // Xcode is unable to compile the specs with all the cell types that are generated by the "allCellTypes()" helper in Model Helper
//                    let post: Post = stub([:])
//                    let cellItem = StreamCellItem(jsonable: post, type: .Toggle)
//                    subject.appendUnsizedCellItems([cellItem], withWidth: webView.frame.width) { cellCount in
//                        vc.collectionView.dataSource = subject
//                        vc.collectionView.reloadData()
//                    }
//
//                    let cell = subject.collectionView(vc.collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
//                    expect(cell).to(beAnInstanceOf(StreamToggleCell.self))
//                }
//            }
        }
    }
}
