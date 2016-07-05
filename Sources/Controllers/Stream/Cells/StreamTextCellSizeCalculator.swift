////
///  StreamTextCellSizeCalculator.swift
//

import Foundation

public class StreamTextCellSizeCalculator: NSObject, UIWebViewDelegate {
    let webView: UIWebView
    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, columnCount: Int, completion: ElloEmptyCompletion)
    private var cellJobs: [CellJob] = []
    private var cellItems: [StreamCellItem] = []
    private var maxWidth: CGFloat
    private var completion: ElloEmptyCompletion = {}

    public static let srcRegex: NSRegularExpression  = try! NSRegularExpression(
        pattern: "src=[\"']([^\"']*)[\"']",
        options: NSRegularExpressionOptions.CaseInsensitive)

    public init(webView: UIWebView) {
        self.webView = webView
        self.maxWidth = 0
        super.init()
        self.webView.delegate = self
    }

// MARK: Public

    public func processCells(cellItems: [StreamCellItem], withWidth width: CGFloat, columnCount: Int, completion: ElloEmptyCompletion) {
        let job: CellJob = (cellItems: cellItems, width: width, columnCount: columnCount, completion: completion)
        cellJobs.append(job)
        if cellJobs.count == 1 {
            processJob(job)
        }
    }

// MARK: Private

    private func processJob(job: CellJob) {
        self.completion = {
            self.cellJobs.removeAtIndex(0)
            job.completion()
            if let nextJob = self.cellJobs.safeValue(0) {
                self.processJob(nextJob)
            }
        }
        self.cellItems = job.cellItems
        self.maxWidth = job.width
        loadNext()
    }

    private func loadNext() {
        if let item = self.cellItems.safeValue(0) {
            if item.jsonable is ElloComment {
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
