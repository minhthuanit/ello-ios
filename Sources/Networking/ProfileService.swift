////
///  ProfileService.swift
//

import Moya
import SwiftyJSON

public typealias AccountDeletionSuccessCompletion = () -> Void
public typealias ProfileSuccessCompletion = (user: User) -> Void
public typealias ProfileUploadSuccessCompletion = (url: NSURL, user: User) -> Void

public struct ProfileService {

    public init(){}

    public func loadCurrentUser(success success: ProfileSuccessCompletion, failure: ElloFailureCompletion) {
        let endpoint: ElloAPI = .CurrentUserProfile
        ElloProvider.shared.elloRequest(endpoint,
            success: { (data, _) in
                if let user = data as? User {
                    success(user: user)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure )
    }

    public func updateUserProfile(content: [String: AnyObject], success: ProfileSuccessCompletion, failure: ElloFailureCompletion) {
        ElloProvider.shared.elloRequest(ElloAPI.ProfileUpdate(body: content),
            success: { data, responseConfig in
                if let user = data as? User {
                    success(user: user)
                } else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }

    public func updateUserCoverImage(image: UIImage, success: ProfileUploadSuccessCompletion, failure: ElloFailureCompletion) {
        updateUserImage(image, key: "remote_cover_image_url", success: { (url, user) in
            TemporaryCache.save(.CoverImage, image: image)
            success(url: url, user: user)
        }, failure: failure)
    }

    public func updateUserAvatarImage(image: UIImage, success: ProfileUploadSuccessCompletion, failure: ElloFailureCompletion) {
        updateUserImage(image, key: "remote_avatar_url", success: { (url, user) in
            TemporaryCache.save(.Avatar, image: image)
            success(url: url, user: user)
        }, failure: failure)
    }

    public func updateUserDeviceToken(token: NSData) {
        ElloProvider.shared.elloRequest(ElloAPI.PushSubscriptions(token: token),
            success: { _, _ in })
    }

    public func removeUserDeviceToken(token: NSData) {
        ElloProvider.shared.elloRequest(ElloAPI.DeleteSubscriptions(token: token),
            success: { _, _ in })
    }

    private func updateUserImage(image: UIImage, key: String, success: ProfileUploadSuccessCompletion, failure: ElloFailureCompletion) {
        S3UploadingService().upload(image, filename: "\(NSUUID().UUIDString).png", success: { url in
            if let url = url {
                self.updateUserProfile([key: url.absoluteString], success: { user in
                    success(url: url, user: user)
                }, failure: failure)
            }
        }, failure: failure)
    }

    public func deleteAccount(success success: AccountDeletionSuccessCompletion, failure: ElloFailureCompletion) {
        ElloProvider.shared.elloRequest(ElloAPI.ProfileDelete,
            success: { _, _ in success() },
            failure: failure)
    }
}
