//
//  StreamTextCellSizeCalculator.swift
//  Ello
//
//  Created by Sean Dougherty on 12/15/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import Foundation

public class StreamTextCellSizeCalculator: NSObject, UIWebViewDelegate {
    public typealias StreamTextCellSizeCalculated = () -> Void

    let webView: UIWebView
    var maxWidth: CGFloat
    public var cellItems: [StreamCellItem] = []
    public var completion: StreamTextCellSizeCalculated = {}

    public static let srcRegex: NSRegularExpression  = try! NSRegularExpression(
        pattern: "src=[\"']([^\"']*)[\"']",
        options: NSRegularExpressionOptions.CaseInsensitive)

    public init(webView: UIWebView) {
        self.webView = webView
        self.maxWidth = 0
        super.init()
        self.webView.delegate = self
    }

    public func processCells(cellItems: [StreamCellItem], withWidth width: CGFloat, columnCount: Int, completion: StreamTextCellSizeCalculated) {
        self.completion = completion
        self.cellItems = cellItems
        self.maxWidth = width
        loadNext()
    }

    private func loadNext() {
        if let item = self.cellItems.safeValue(0) {
            if let _ = item.jsonable as? ElloComment {
                // need to add back in the postMargin (15) since the maxWidth should already
                // account for 15 on the left that is part of the commentMargin (60)
                self.webView.frame = self.webView.frame.withWidth(maxWidth - StreamTextCellPresenter.commentMargin + StreamTextCellPresenter.postMargin)
            }
            else {
                self.webView.frame = self.webView.frame.withWidth(maxWidth)
            }
            let textElement = item.type.data as? TextRegion

            if let textElement = textElement {
                let content = textElement.content
                let strippedContent = StreamTextCellSizeCalculator.stripImageSrc(content)
                let html = StreamTextCellHTML.postHTML(strippedContent)
                // needs to use the same width as the post text region
                self.webView.loadHTMLString(html, baseURL: NSURL(string: "/"))
            }
            else {
                self.cellItems.removeAtIndex(0)
                loadNext()
            }
        }
        else {
            completion()
        }
    }

    public func webViewDidFinishLoad(webView: UIWebView) {
        let textHeight = self.webView.windowContentSize()?.height
        assignCellHeight(textHeight ?? 0)
    }

    private func assignCellHeight(height: CGFloat) {
        if let cellItem = self.cellItems.safeValue(0) {
            self.cellItems.removeAtIndex(0)
            cellItem.calculatedWebHeight = height
            cellItem.calculatedOneColumnCellHeight = height
            cellItem.calculatedMultiColumnCellHeight = height
        }
        loadNext()
    }


    public static func stripImageSrc(html: String) -> String {
        // finds image tags, replaces them with data:image/png (inlines image data)
        let range = NSRange(location: 0, length: html.characters.count)

        let strippedHtml: String = srcRegex.stringByReplacingMatchesInString(html,
            options: NSMatchingOptions(),
            range:range,
            withTemplate: "src=\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNiAAAABgADNjd8qAAAAABJRU5ErkJggg==")

        return strippedHtml
    }
}
