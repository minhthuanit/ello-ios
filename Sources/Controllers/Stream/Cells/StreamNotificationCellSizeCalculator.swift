////
///  StreamNotificationCellSizeCalculator.swift
//


private let textViewForSizing = ElloTextView(frame: CGRectZero, textContainer: nil)
private var srcRegex: NSRegularExpression? = try? NSRegularExpression(
                pattern: "src=[\"']([^\"']*)[\"']",
                options: .CaseInsensitive)

public class StreamNotificationCellSizeCalculator: NSObject, UIWebViewDelegate {
    let webView: UIWebView
    var originalWidth: CGFloat

    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, columnCount: Int, completion: ElloEmptyCompletion)
    private var cellJobs: [CellJob] = []
    private var cellItems: [StreamCellItem] = []
    private var completion: ElloEmptyCompletion = {}

    public init(webView: UIWebView) {
        self.webView = webView
        originalWidth = self.webView.frame.size.width
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
        self.originalWidth = job.width
        self.webView.frame = self.webView.frame.withWidth(job.width)
        loadNext()
    }

    private func loadNext() {
        if let activity = self.cellItems.safeValue(0) {
            if let notification = activity.jsonable as? Notification,
                textRegion = notification.textRegion
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
