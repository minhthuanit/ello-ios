////
///  StreamImageCellSizeCalculator.swift
//

import Foundation

public class StreamImageCellSizeCalculator: NSObject {
    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, columnCount: Int, completion: ElloEmptyCompletion)
    private var cellJobs: [CellJob] = []
    private var screenWidth: CGFloat = 0.0
    private var maxWidth: CGFloat = 0.0
    private var columnCount: Int = 1
    private var cellItems: [StreamCellItem] = []
    private var completion: ElloEmptyCompletion = {}

// MARK: Static

    public static func aspectRatioForImageRegion(imageRegion: ImageRegion) -> CGFloat {
        if let asset = imageRegion.asset {
            var attachment: Attachment?
            if let tryAttachment = asset.hdpi {
                attachment = tryAttachment
            }
            else if let tryAttachment = asset.optimized {
                attachment = tryAttachment
            }

            if let attachment = attachment {
                if let width = attachment.width, height = attachment.height {
                    return CGFloat(width)/CGFloat(height)
                }
            }
        }
        return 4.0/3.0
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
        self.screenWidth = job.width
        self.columnCount = job.columnCount
        loadNext()
    }

    private func loadNext() {
        self.maxWidth = screenWidth
        if !self.cellItems.isEmpty {
            let item = cellItems.removeAtIndex(0)
            if (item.type.data as? Regionable)?.isRepost == true {
                maxWidth -= StreamTextCellPresenter.repostMargin
            }
            else if item.jsonable is ElloComment {
                maxWidth -= StreamTextCellPresenter.commentMargin
            }

            if let imageRegion = item.type.data as? ImageRegion {
                item.calculatedOneColumnCellHeight = StreamImageCell.Size.bottomMargin + oneColumnImageHeight(imageRegion)
                item.calculatedMultiColumnCellHeight = StreamImageCell.Size.bottomMargin + multiColumnImageHeight(imageRegion)
            }
            else if let embedRegion = item.type.data as? EmbedRegion {
                var ratio: CGFloat
                if embedRegion.isAudioEmbed || embedRegion.service == .UStream {
                    ratio = 1.0
                }
                else {
                    ratio = 16.0/9.0
                }
                item.calculatedOneColumnCellHeight = StreamImageCell.Size.bottomMargin + maxWidth / ratio
                item.calculatedMultiColumnCellHeight = StreamImageCell.Size.bottomMargin + calculateColumnWidth(screenWidth: maxWidth, columnCount: columnCount) / ratio
            }
            loadNext()
        }
        else {
            completion()
        }
    }

    private func oneColumnImageHeight(imageRegion: ImageRegion) -> CGFloat {
        var imageWidth = maxWidth
        if let assetWidth = imageRegion.asset?.oneColumnAttachment?.width {
            imageWidth = min(maxWidth, CGFloat(assetWidth))
        }
        return ceil(imageWidth / StreamImageCellSizeCalculator.aspectRatioForImageRegion(imageRegion))
    }

    private func multiColumnImageHeight(imageBlock: ImageRegion) -> CGFloat {
        var imageWidth = calculateColumnWidth(screenWidth: maxWidth, columnCount: columnCount)
        if let assetWidth = imageBlock.asset?.gridLayoutAttachment?.width {
            imageWidth = min(imageWidth, CGFloat(assetWidth))
        }
        return ceil((imageWidth / StreamImageCellSizeCalculator.aspectRatioForImageRegion(imageBlock)))
    }

}
