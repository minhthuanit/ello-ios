////
///  ProfileHeaderCellSizeCalculator.swift
//

import Foundation


public class ProfileHeaderCellSizeCalculator: NSObject {
    static let ratio: CGFloat = 16 / 9
    let webView: UIWebView

    private let label = ElloLabel()
    private var maxWidth: CGFloat = 0.0
    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, columnCount: Int, completion: ElloEmptyCompletion)
    private var cellJobs: [CellJob] = []
    private var cellItems: [StreamCellItem] = []
    private var completion: ElloEmptyCompletion = {}

    required public init(webView: UIWebView) {
        self.webView = webView
        super.init()
        webView.delegate = self
        label.lineBreakMode = .ByWordWrapping
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
        self.webView.frame = self.webView.frame.withWidth(job.width - (StreamTextCellPresenter.postMargin * 2))
        loadNext()
    }

    private func loadNext() {
        if let item = cellItems.safeValue(0),
            user = item.jsonable as? User
        {
            let html = StreamTextCellHTML.postHTML(user.headerHTMLContent)
            label.setLabelText(user.name)

            // needs to use the same width as the post text region
            webView.loadHTMLString(html, baseURL: NSURL(string: "/"))
        }
        else {
            completion()
        }
    }

    private func assignCellHeight(webViewHeight: CGFloat) {
        if let cellItem = cellItems.safeValue(0) {
            let leftLabelMargin: CGFloat = 15
            let rightLabelMargin: CGFloat = 82
            let nameSize = label.attributedText!.boundingRectWithSize(CGSize(width: maxWidth - leftLabelMargin - rightLabelMargin, height: CGFloat.max),
                options: .UsesLineFragmentOrigin, context: nil).size

            let height = ProfileHeaderCellSizeCalculator.calculateHeightBasedOn(
                webViewHeight: webViewHeight,
                nameSize: nameSize,
                width: maxWidth
                )
            self.cellItems.removeAtIndex(0)
            cellItem.calculatedWebHeight = webViewHeight
            cellItem.calculatedOneColumnCellHeight = height
            cellItem.calculatedMultiColumnCellHeight = height
        }
        loadNext()
    }

    class func calculateHeightBasedOn(webViewHeight webViewHeight: CGFloat, nameSize: CGSize, width: CGFloat) -> CGFloat {
        var height: CGFloat = width / ratio // cover image size

        height += 146 // size without webview and name label
        height += max(webViewHeight, 0)
        height += nameSize.height
        return ceil(height)
    }

}

extension ProfileHeaderCellSizeCalculator: UIWebViewDelegate {

    public func webViewDidFinishLoad(webView: UIWebView) {
        let webViewHeight = webView.windowContentSize()?.height ?? 0
        assignCellHeight(webViewHeight)
    }

}
