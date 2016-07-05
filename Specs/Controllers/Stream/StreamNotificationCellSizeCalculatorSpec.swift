//
//  StreamNotificationCellSizeCalculatorSpec.swift
//  Ello
//
//  Created by Colin Gray on 2/19/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Ello
import Quick
import Nimble


class StreamNotificationCellSizeCalculatorSpec : QuickSpec {
    class MockUIWebView: UIWebView {
        var mockHeight: CGFloat = 50

        override func loadHTMLString(html: String, baseURL: NSURL?) {
            delegate?.webViewDidFinishLoad?(self)
        }

        override func stringByEvaluatingJavaScriptFromString(js: String) -> String? {
            if js.contains("post-container") { return "\(frame.size.width)" }
            if js.contains("window.contentHeight") { return "\(mockHeight)" }
            return super.stringByEvaluatingJavaScriptFromString(js)
        }
    }

    override func spec() {
        describe("StreamNotificationCellSizeCalculator") {
            let user: User = stub([:])
            let text: TextRegion = stub(["content": "Lorem ipsum dolor sit amet."])
            let image: ImageRegion = stub(["asset": Asset.stub(["attachment": Attachment.stub(["width": 2000, "height": 2000])])])
            let postWithText: Post = stub(["summary": [text], "content": [text], "author": user])
            let postWithImage: Post = stub(["summary": [image], "content": [image], "author": user])
            let postWithTextAndImage: Post = stub(["summary": [text, image], "content": [text, image], "author": user])
            var subject: StreamNotificationCellSizeCalculator!
            beforeEach {
                subject = StreamNotificationCellSizeCalculator(webView: MockUIWebView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 568))))
            }

            it("should return minimum size") {
                let activity: Activity = stub(["kind": "new_follower_post", "subject": user])
                let notification: Notification = stub(["activity": activity])
                let item = StreamCellItem(jsonable: notification, type: .Notification)
                subject.processCells([item], withWidth: 320, columnCount: 1) {
                }
                expect(item.calculatedWebHeight) == 0
                expect(item.calculatedOneColumnCellHeight) == 67
                expect(item.calculatedMultiColumnCellHeight) == 67
            }
            it("should return size that accounts for a message") {
                let activity: Activity = stub(["kind": "repost_notification", "subject": postWithText])
                let notification: Notification = stub(["activity": activity])
                let item = StreamCellItem(jsonable: notification, type: .Notification)
                subject.processCells([item], withWidth: 320, columnCount: 1) {
                }
                expect(item.calculatedWebHeight) == 50
                expect(item.calculatedOneColumnCellHeight) == 112
                expect(item.calculatedMultiColumnCellHeight) == 112
            }
            it("should return size that accounts for an image") {
                let activity: Activity = stub(["kind": "repost_notification", "subject": postWithImage])
                let notification: Notification = stub(["activity": activity])
                let item = StreamCellItem(jsonable: notification, type: .Notification)
                subject.processCells([item], withWidth: 320, columnCount: 1) {
                }
                expect(item.calculatedOneColumnCellHeight) == 129
                expect(item.calculatedMultiColumnCellHeight) == 129
            }
            it("should return size that accounts for an image with text") {
                let activity: Activity = stub(["kind": "repost_notification", "subject": postWithTextAndImage])
                let notification: Notification = stub(["activity": activity])
                let item = StreamCellItem(jsonable: notification, type: .Notification)
                subject.processCells([item], withWidth: 320, columnCount: 1) {
                }
                expect(item.calculatedWebHeight) == 50
                expect(item.calculatedOneColumnCellHeight) == 129
                expect(item.calculatedMultiColumnCellHeight) == 129
            }
            xit("should return size that accounts for a follow button") {
                // title and text and follow buton
            }
            it("should return size that accounts for a reply button") {
                let activity: Activity = stub(["kind": "comment_notification", "subject": postWithText])
                let notification: Notification = stub(["activity": activity])
                let item = StreamCellItem(jsonable: notification, type: .Notification)
                subject.processCells([item], withWidth: 320, columnCount: 1) {
                }
                expect(item.calculatedWebHeight) == 50
                expect(item.calculatedOneColumnCellHeight) == 157
                expect(item.calculatedMultiColumnCellHeight) == 157
            }
        }
    }
}
