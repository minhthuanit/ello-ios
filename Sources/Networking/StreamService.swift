////
///  StreamService.swift
//

import Moya

public typealias StreamSuccessCompletion = (jsonables: [JSONAble], responseConfig: ResponseConfig) -> Void
public typealias UserSuccessCompletion = (user: User, responseConfig: ResponseConfig) -> Void
public typealias UserPostsSuccessCompletion = (posts: [Post], responseConfig: ResponseConfig) -> Void

public struct StreamLoadedNotifications {
    static let streamLoaded = TypedNotification<StreamKind>(name: "StreamLoadedNotification")
}

public class StreamService: NSObject {

    public func loadStream(
        endpoint: ElloAPI,
        streamKind: StreamKind?,
        success: StreamSuccessCompletion,
        failure: ElloFailureCompletion? = nil,
        noContent: ElloEmptyCompletion? = nil)
    {
        ElloProvider.shared.elloRequest(
            endpoint,
            success: { (data, responseConfig) in
                if let jsonables = data as? [JSONAble] {
                    if let streamKind = streamKind {
                        Preloader().preloadImages(jsonables)
                        NewContentService().updateCreatedAt(jsonables, streamKind: streamKind)
                    }
                    success(jsonables: jsonables, responseConfig: responseConfig)
                }
                else if let noContent = noContent {
                    noContent()
                }

                // this must be the last thing, after success() or noContent() is called.
                if let streamKind = streamKind {
                    postNotification(StreamLoadedNotifications.streamLoaded, value: streamKind)
                }
            },
            failure: { (error, statusCode) in
                failure?(error: error, statusCode: statusCode)
            })
    }

    public func loadUser(
        endpoint: ElloAPI,
        streamKind: StreamKind?,
        success: UserSuccessCompletion,
        failure: ElloFailureCompletion)
    {
        ElloProvider.shared.elloRequest(
            endpoint,
            success: { (data, responseConfig) in
                if let user = data as? User {
                    Preloader().preloadImages([user])
                    success(user: user, responseConfig: responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }

    public func loadUserPosts(
        userId: String,
        success: UserPostsSuccessCompletion,
        failure: ElloFailureCompletion)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.UserStreamPosts(userId: userId),
            success: { (data, responseConfig) in
                if let posts = data as? [Post] {
                    Preloader().preloadImages(posts)
                    success(posts: posts, responseConfig: responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }

    public func loadMoreCommentsForPost(
        postId: String,
        streamKind: StreamKind?,
        success: StreamSuccessCompletion,
        failure: ElloFailureCompletion,
        noContent: ElloEmptyCompletion? = nil)
    {
        ElloProvider.shared.elloRequest(
            .PostComments(postId: postId),
            success: { (data, responseConfig) in
                if let comments: [ElloComment] = data as? [ElloComment] {

                    for comment in comments {
                        comment.loadedFromPostId = postId
                    }

                    Preloader().preloadImages(comments)
                    success(jsonables: comments, responseConfig: responseConfig)
                }
                else if let noContent = noContent {
                    noContent()
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }
}
