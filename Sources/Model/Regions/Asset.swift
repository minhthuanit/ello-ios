//
//  Asset.swift
//  Ello
//
//  Created by Sean on 2/11/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Crashlytics
import Foundation
import SwiftyJSON

let AssetVersion = 1

@objc(Asset)
public final class Asset: JSONAble {

    // active record
    public let id: String
    // optional
    public var optimized: Attachment?
    public var smallScreen: Attachment?
    public var ldpi: Attachment?
    public var mdpi: Attachment?
    public var hdpi: Attachment?
    public var xhdpi: Attachment?
    public var xxhdpi: Attachment?
    public var original: Attachment?
    // optional avatar
    public var largeOrBest: Attachment? {
        // we originally had this expressed via
        // return large ?? optimized ?? xxhdpi ?? xhdpi ?? hdpi ?? regular
        //
        // unfortunately that took 12.4 seconds to compile
        // this (much more verbose) code compiles very quickly
        if let large = large { return large }
        if let optimized = optimized { return optimized }
        if let xxhdpi = xxhdpi { return xxhdpi }
        if let xhdpi = large { return xhdpi }
        if let hdpi = hdpi { return hdpi }
        if let regular = regular { return regular }
        return nil

    }
    public var large: Attachment?
    public var regular: Attachment?
    public var small: Attachment?
    // computed
    public var isGif: Bool {
        return self.optimized?.type == "image/gif"
    }
    public var isLargeGif: Bool {
        if isGif {
            if let size = self.optimized?.size {
                return size >= 3_145_728
            }
        }
        return false
    }

	public var oneColumnAttachment: Attachment? {
        return self.hdpi
    }

    public var gridLayoutAttachment: Attachment? {
        let isWide = Window.isWide(Window.width)
        if isWide {
            return self.hdpi
        }
        else {
            return self.mdpi
        }
    }

// MARK: Initialization

    public convenience init(url: NSURL) {
        self.init(id: NSUUID().UUIDString)

        let attachment = Attachment(url: url)
        self.optimized = attachment
    }

    public convenience init(image: UIImage, url: NSURL) {
        self.init(id: NSUUID().UUIDString)

        let attachment = Attachment(url: url)
        attachment.width = Int(image.size.width)
        attachment.height = Int(image.size.height)
        attachment.image = image

        self.optimized = attachment
    }

    public init(id: String)
    {
        self.id = id
        super.init(version: AssetVersion)
    }

// MARK: NSCoding

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        // required
        self.id = decoder.decodeKey("id")
        // optional
        self.optimized = decoder.decodeOptionalKey("optimized")
        self.smallScreen = decoder.decodeOptionalKey("smallScreen")
        self.ldpi = decoder.decodeOptionalKey("ldpi")
        self.mdpi = decoder.decodeOptionalKey("mdpi")
        self.hdpi = decoder.decodeOptionalKey("hdpi")
        self.xhdpi = decoder.decodeOptionalKey("xhdpi")
        self.xxhdpi = decoder.decodeOptionalKey("xxhdpi")
        self.original = decoder.decodeOptionalKey("original")
        // optional avatar
        self.large = decoder.decodeOptionalKey("large")
        self.regular = decoder.decodeOptionalKey("regular")
        self.small = decoder.decodeOptionalKey("small")
        super.init(coder: decoder.coder)
    }

    public override func encodeWithCoder(encoder: NSCoder) {
        let coder = Coder(encoder)
        // required
        coder.encodeObject(id, forKey: "id")
        // optional
        coder.encodeObject(optimized, forKey: "optimized")
        coder.encodeObject(smallScreen, forKey: "smallScreen")
        coder.encodeObject(ldpi, forKey: "ldpi")
        coder.encodeObject(mdpi, forKey: "mdpi")
        coder.encodeObject(hdpi, forKey: "hdpi")
        coder.encodeObject(xhdpi, forKey: "xhdpi")
        coder.encodeObject(xxhdpi, forKey: "xxhdpi")
        coder.encodeObject(original, forKey: "original")
        // optional avatar
        coder.encodeObject(large, forKey: "large")
        coder.encodeObject(regular, forKey: "regular")
        coder.encodeObject(small, forKey: "small")
        super.encodeWithCoder(coder.coder)
    }

// MARK: JSONAble

    override class public func fromJSON(data: [String: AnyObject], fromLinked: Bool = false) -> JSONAble {
        let json = JSON(data)
        Crashlytics.sharedInstance().setObjectValue(json.rawString(), forKey: CrashlyticsKey.AssetFromJSON.rawValue)
        return parseAsset(json["id"].stringValue, node: data["attachment"] as? [String: AnyObject])
    }

    class public func parseAsset(id: String, node: [String: AnyObject]?) -> Asset {
        let asset = Asset(id: id)
        // optional
        if let optimized = node?["optimized"] as? [String: AnyObject] {
            asset.optimized = Attachment.fromJSON(optimized) as? Attachment
        }
        if let smallScreen = node?["small_screen"] as? [String: AnyObject] {
            asset.smallScreen = Attachment.fromJSON(smallScreen) as? Attachment
        }
        if let ldpi = node?["ldpi"] as? [String: AnyObject] {
            asset.ldpi = Attachment.fromJSON(ldpi) as? Attachment
        }
        if let mdpi = node?["mdpi"] as? [String: AnyObject] {
            asset.mdpi = Attachment.fromJSON(mdpi) as? Attachment
        }
        if let hdpi = node?["hdpi"] as? [String: AnyObject] {
            asset.hdpi = Attachment.fromJSON(hdpi) as? Attachment
        }
        if let xhdpi = node?["xhdpi"] as? [String: AnyObject] {
            asset.xhdpi = Attachment.fromJSON(xhdpi) as? Attachment
        }
        if let xxhdpi = node?["xxhdpi"] as? [String: AnyObject] {
            asset.xxhdpi = Attachment.fromJSON(xxhdpi) as? Attachment
        }
        if let original = node?["original"] as? [String: AnyObject] {
            asset.original = Attachment.fromJSON(original) as? Attachment
        }
        // optional avatar
        if let large = node?["large"] as? [String: AnyObject] {
            asset.large = Attachment.fromJSON(large) as? Attachment
        }
        if let regular = node?["regular"] as? [String: AnyObject] {
            asset.regular = Attachment.fromJSON(regular) as? Attachment
        }
        if let small = node?["small"] as? [String: AnyObject] {
            asset.small = Attachment.fromJSON(small) as? Attachment
        }
        return asset
    }
}
