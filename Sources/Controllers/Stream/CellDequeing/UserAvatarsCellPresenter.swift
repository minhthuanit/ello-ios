////
///  UserAvatarsCellPresenter.swift
//

public struct UserAvatarsCellPresenter {

    public static func configure(
        cell: UICollectionViewCell,
        streamCellItem: StreamCellItem,
        streamKind: StreamKind,
        indexPath: NSIndexPath,
        currentUser: User?)
    {
        guard let cell = cell as? UserAvatarsCell,
            model = streamCellItem.jsonable as? UserAvatarCellModel else {
                return
        }
        cell.imageView.image = model.icon.normalImage
        cell.userAvatarCellModel = model
        cell.loadingLabel.hidden = model.hasUsers
    }
}
