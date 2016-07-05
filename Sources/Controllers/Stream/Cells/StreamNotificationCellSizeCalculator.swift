//
//  StreamNotificationCellSizeCalculator.swift
//  Ello
//
//  Created by Colin Gray on 2/17/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//


private let textViewForSizing = ElloTextView(frame: CGRectZero, textContainer: nil)

public class StreamNotificationCellSizeCalculator: NSObject, UIWebViewDelegate {

    public typealias StreamTextCellSizeCalculated = () -> Void

    let webView: UIWebView
    var originalWidth: CGFloat
    public var cellItems: [StreamCellItem] = []
    public var completion: StreamTextCellSizeCalculated = {}

    var srcRegex: NSRegularExpression?

    public init(webView: UIWebView) {
        self.webView = webView
        originalWidth = self.webView.frame.size.width
        super.init()
        self.webView.delegate = self

        do {
            try srcRegex = NSRegularExpression(
                pattern: "src=[\"']([^\"']*)[\"']",
                options: .CaseInsensitive)
        }
        catch {
            srcRegex = nil
        }
    }

    public func processCells(cellItems: [StreamCellItem], withWidth width: CGFloat, columnCount: Int, completion: StreamTextCellSizeCalculated) {
        self.completion = completion
        self.cellItems = cellItems
        self.originalWidth = width
        self.webView.frame = self.webView.frame.withWidth(width)
        loadNext()
    }

    private func loadNext() {
        if let activity = self.cellItems.safeValue(0) {
            if let notification = activity.jsonable as? Notification,
                let textRegion = notification.textRegion
            {
                let content = textRegion.content
                let strippedContent = self.stripImageSrc(content)
                let html = StreamTextCellHTML.postHTML(strippedContent)
                var f = self.webView.frame
                f.size.width = NotificationCell.Size.messageHtmlWidth(forCellWidth: originalWidth, hasImage: notification.hasImage)
                self.webView.frame = f
                self.webView.loadHTMLString(html, baseURL: NSURL(string: "/"))
            }
            else {
                assignCellHeight(0)
            }
        }
        else {
            nextTick(completion)
        }
    }

    public func webViewDidFinishLoad(webView: UIWebView) {
        if let webContentHeight = self.webView.windowContentSize()?.height {
            assignCellHeight(webContentHeight)
        }
        else {
            assignCellHeight(0)
        }
    }

    private func assignCellHeight(webContentHeight: CGFloat) {
        if let cellItem = self.cellItems.safeValue(0) {
            self.cellItems.removeAtIndex(0)
            StreamNotificationCellSizeCalculator.assignTotalHeight(webContentHeight, cellItem: cellItem, cellWidth: originalWidth)
        }
        loadNext()
    }

    class func assignTotalHeight(webContentHeight: CGFloat?, cellItem: StreamCellItem, cellWidth: CGFloat) {
        let notification = cellItem.jsonable as! Notification

        textViewForSizing.attributedText = notification.attributedTitle
        let titleWidth = NotificationCell.Size.messageHtmlWidth(forCellWidth: cellWidth, hasImage: notification.hasImage)
        let titleSize = textViewForSizing.sizeThatFits(CGSize(width: titleWidth, height: .max))
        var totalTextHeight = ceil(titleSize.height)
        totalTextHeight += NotificationCell.Size.createdAtFixedHeight()

        if let webContentHeight = webContentHeight where webContentHeight > 0 {
            totalTextHeight += webContentHeight - NotificationCell.Size.WebHeightCorrection + NotificationCell.Size.InnerMargin
        }

        if notification.canReplyToComment {
            totalTextHeight += NotificationCell.Size.ButtonHeight + NotificationCell.Size.ButtonMargin
        }
        else if notification.canBackFollow {
            totalTextHeight += NotificationCell.Size.ButtonHeight + NotificationCell.Size.ButtonMargin
        }

        let totalImageHeight = NotificationCell.Size.imageHeight(imageRegion: notification.imageRegion)
        var height = max(totalTextHeight, totalImageHeight)

        height += 2 * NotificationCell.Size.SideMargins
        if let webContentHeight = webContentHeight {
            cellItem.calculatedWebHeight = webContentHeight
        }
        cellItem.calculatedOneColumnCellHeight = height
        cellItem.calculatedMultiColumnCellHeight = height
    }

    private func stripImageSrc(html: String) -> String {
        // finds image tags, replaces them with data:image/png (inlines image data)
        let range = NSRange(location: 0, length: html.characters.count)

//MARK: warning - is '.ReportCompletion' what we want?
        if let srcRegex = srcRegex {
            return srcRegex.stringByReplacingMatchesInString(html,
                options: .ReportCompletion,
                range: range,
                withTemplate: "src=\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNiAAAABgADNjd8qAAAAABJRU5ErkJggg==")
        }

        return ""
    }

}
