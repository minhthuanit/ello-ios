////
///  UserAvatarCellModel.swift
//

import Foundation

let UserAvatarCellModelVersion = 2

@objc(UserAvatarCellModel)
public final class UserAvatarCellModel: JSONAble {

    public let icon: InterfaceImage
    public let seeMoreTitle: String
    public var endpoint: ElloAPI?
    public var users: [User]?

    public var hasUsers: Bool {
        if let arr = users {
            return arr.count > 0
        }
        return false
    }

    public init(icon: InterfaceImage, seeMoreTitle: String) {
        self.icon = icon
        self.seeMoreTitle = seeMoreTitle
        super.init(version: UserAvatarCellModelVersion)
    }

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        self.icon = decoder.decodeKey("icon")
        self.seeMoreTitle = decoder.decodeKey("seeMoreTitle")
        super.init(coder: decoder.coder)
    }

    public override func encodeWithCoder(encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(icon, forKey: "icon")
        coder.encodeObject(seeMoreTitle, forKey: "seeMoreTitle")
        super.encodeWithCoder(coder.coder)
    }

    override public class func fromJSON(data: [String: AnyObject], fromLinked: Bool = false) -> JSONAble {
        return UserAvatarCellModel(
            icon: InterfaceImage(rawValue: (data["icon"] as? String) ?? "hearts")!,
            seeMoreTitle: (data["seeMoreTitle"] as? String) ?? ""
        )
    }

}
