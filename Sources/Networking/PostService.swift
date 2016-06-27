////
///  PostService.swift
//

import Foundation

public typealias PostSuccessCompletion = (post: Post, responseConfig: ResponseConfig) -> Void
public typealias PostCommentsSuccessCompletion = (comments: [ElloComment], responseConfig: ResponseConfig) -> Void
public typealias PostLoversSuccessCompletion = (users: [User], responseConfig: ResponseConfig) -> Void
public typealias PostRepostersSuccessCompletion = (users: [User], responseConfig: ResponseConfig) -> Void
public typealias UsernamesSuccessCompletion = (usernames: [String]) -> Void
public typealias CommentSuccessCompletion = (comment: ElloComment, responseConfig: ResponseConfig) -> Void
public typealias DeletePostSuccessCompletion = () -> Void

public struct PostService {

    public init(){}

    public func loadPost(
        postParam: String,
        needsComments: Bool,
        success: PostSuccessCompletion,
        failure: ElloFailureCompletion? = nil)
    {
        let commentCount = needsComments ? 10 : 0
        ElloProvider.shared.elloRequest(
            ElloAPI.PostDetail(postParam: postParam, commentCount: commentCount),
            success: { (data, responseConfig) in
                if let post = data as? Post {
                    Preloader().preloadImages([post])
                    success(post: post, responseConfig: responseConfig)
                }
                else if let failure = failure {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure?(error: error, statusCode: statusCode)
            })
    }

    public func loadPostComments(
        postId: String,
        success: PostCommentsSuccessCompletion,
        failure: ElloFailureCompletion? = nil)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.PostComments(postId: postId),
            success: { (data, responseConfig) in
                if let comments = data as? [ElloComment] {
                    Preloader().preloadImages(comments)
                    success(comments: comments, responseConfig: responseConfig)
                }
                else if let failure = failure {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure?(error: error, statusCode: statusCode)
        })
    }

    public func loadPostLovers(
        postId: String,
        success: PostLoversSuccessCompletion,
        failure: ElloFailureCompletion? = nil)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.PostLovers(postId: postId),
            success: { (data, responseConfig) in
                if let users = data as? [User] {
                    Preloader().preloadImages(users)
                    success(users: users, responseConfig: responseConfig)
                }
                else if let failure = failure {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure?(error: error, statusCode: statusCode)
        })
    }

    public func loadPostReposters(
        postId: String,
        success: PostRepostersSuccessCompletion,
        failure: ElloFailureCompletion? = nil)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.PostReposters(postId: postId),
            success: { (data, responseConfig) in
                if let users = data as? [User] {
                    Preloader().preloadImages(users)
                    success(users: users, responseConfig: responseConfig)
                }
                else if let failure = failure {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure?(error: error, statusCode: statusCode)
        })
    }

    public func loadComment(
        postId: String,
        commentId: String,
        success: CommentSuccessCompletion,
        failure: ElloFailureCompletion? = nil)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.CommentDetail(postId: postId, commentId: commentId),
            success: { (data, responseConfig) in
                if let comment = data as? ElloComment {
                    comment.loadedFromPostId = postId
                    success(comment: comment, responseConfig: responseConfig)
                }
                else if let failure = failure {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure?(error: error, statusCode: statusCode)
            })
    }

    public func loadReplyAll(
        postId: String,
        success: UsernamesSuccessCompletion,
        failure: ElloEmptyCompletion)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.PostReplyAll(postId: postId),
            success: { (usernames, _) in
                if let usernames = usernames as? [Username] {
                    let strings = usernames
                        .map { $0.username }
                    let uniq = strings.unique()
                    success(usernames: uniq)
                }
                else {
                    failure()
                }
            }, failure: { _ in failure() })
    }

    public func deletePost(
        postId: String,
        success: ElloEmptyCompletion?,
        failure: ElloFailureCompletion)
    {
        ElloProvider.shared.elloRequest(ElloAPI.DeletePost(postId: postId),
            success: { (_, _) in
                NSURLCache.sharedURLCache().removeAllCachedResponses()
                success?()
            }, failure: failure
        )
    }

    public func deleteComment(postId: String, commentId: String, success: ElloEmptyCompletion?, failure: ElloFailureCompletion) {
        ElloProvider.shared.elloRequest(ElloAPI.DeleteComment(postId: postId, commentId: commentId),
            success: { (_, _) in
                success?()
            }, failure: failure
        )
    }
}
