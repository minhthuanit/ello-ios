////
///  ProfileViewControllerSpec.swift
//

@testable import Ello
import Moya
import Quick
import Nimble


class ProfileViewControllerSpec: QuickSpec {
    override func spec() {
        describe("ProfileViewController") {
            let currentUser: User = stub([:])

            describe("initialization from storyboard") {
                let user: User = stub(["id": "42"])
                let subject = ProfileViewController(userParam: user.id)
                subject.currentUser = currentUser

                it("can be instantiated") {
                    expect(subject).notTo(beNil())
                }

                describe("IBOutlets") {
                    beforeEach {
                        showController(subject)
                    }

                    it("has navigationBar") {
                        expect(subject.navigationBar).toNot(beNil())
                    }
                    it("has whiteSolidView") {
                        expect(subject.whiteSolidView).toNot(beNil())
                    }
                    it("has noPostsView") {
                        expect(subject.noPostsView).toNot(beNil())
                    }
                    it("has noPostsHeader") {
                        expect(subject.noPostsHeader).toNot(beNil())
                    }
                    it("has noPostsBody") {
                        expect(subject.noPostsBody).toNot(beNil())
                    }
                    it("has navigationBarTopConstraint") {
                        expect(subject.navigationBarTopConstraint).toNot(beNil())
                    }
                    it("has coverImage") {
                        expect(subject.coverImage).toNot(beNil())
                    }
                    it("has coverImageHeight") {
                        expect(subject.coverImageHeight).toNot(beNil())
                    }
                    it("has noPostsViewHeight") {
                        expect(subject.noPostsViewHeight).toNot(beNil())
                    }
                }

            }

            describe("contentInset") {
                let user: User = stub(["id": "42"])
                let subject = ProfileViewController(userParam: user.id)
                subject.currentUser = currentUser

                beforeEach {
                    UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
                    showController(subject)
                }

                it("does not update the top inset") {
                    expect(subject.streamViewController.contentInset.top) == 0
                }
            }

            context("when displaying the currentUser") {
                var currentUser: User!
                var subject: ProfileViewController!

                beforeEach {
                    currentUser = User.stub(["id": "42"])
                    subject = ProfileViewController(user: currentUser)
                    subject.currentUser = currentUser
                    showController(subject)
                }

                it("does not have a 'more following options' Button") {
                    let rightButtons = subject.elloNavigationItem.rightBarButtonItems
                    expect(rightButtons?.count ?? 0) == 0
                }
            }

            context("when NOT displaying the currentUser") {
                var currentUser: User!
                var subject: ProfileViewController!

                beforeEach {
                    currentUser = User.stub(["id": "not42"])
                    subject = ProfileViewController(userParam: "42")
                    subject.currentUser = currentUser
                    showController(subject)
                }

                it("has 'share' and 'more following options' buttons") {
                    expect(subject.elloNavigationItem.rightBarButtonItems?.count) == 2
                }
            }

            context("when displaying a private user") {
                var currentUser: User!
                var subject: ProfileViewController!

                beforeEach {
                    ElloProvider.sharedProvider = ElloProvider.RecordedStubbingProvider([
                        RecordedResponse(endpoint: .UserStream(userParam: "50"), response: .NetworkResponse(200,
                            stubbedData("profile__no_sharing")
                        )),
                    ])

                    currentUser = User.stub(["id": "not50"])
                    subject = ProfileViewController(userParam: "50")
                    subject.currentUser = currentUser
                    showController(subject)
                }

                it("only has a 'more following options' button") {
                    expect(subject.elloNavigationItem.rightBarButtonItems?.count) == 1
                }
            }

            describe("tapping more button") {
                var user: User!
                var subject: ProfileViewController!

                beforeEach {
                    user = User.stub(["id": "42"])
                    subject = ProfileViewController(userParam: user.id)
                    subject.currentUser = currentUser
                    showController(subject)
                }

                it("launches the block modal") {
                    subject.moreButtonTapped()
                    let presentedVC = subject.presentedViewController
                    expect(presentedVC).notTo(beNil())
                    expect(presentedVC).to(beAKindOf(BlockUserModalViewController))
                }
            }


            context("with successful request") {
                var user: User!
                var subject: ProfileViewController!

                beforeEach {
                    subject = ProfileViewController(userParam: "42")
                    subject.currentUser = currentUser
                    showController(subject)
                    user = subject.user!
                }

                describe("@moreButton") {
                    it("not selected block") {
                        user.relationshipPriority = .Inactive
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Block)
                        expect(user.relationshipPriority) == RelationshipPriority.Block
                    }

                    it("not selected mute") {
                        user.relationshipPriority = .Inactive
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Mute)
                        expect(user.relationshipPriority) == RelationshipPriority.Mute
                    }

                    it("selected block") {
                        user.relationshipPriority = .Block
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Inactive)
                        expect(user.relationshipPriority) == RelationshipPriority.Inactive
                    }

                    it("selected mute") {
                        user.relationshipPriority = .Mute
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Inactive)
                        expect(user.relationshipPriority) == RelationshipPriority.Inactive
                    }

                }
            }

            context("with failed request") {
                var user: User!
                var subject: ProfileViewController!

                beforeEach {
                    subject = ProfileViewController(userParam: "42")
                    subject.currentUser = currentUser
                    showController(subject)
                    user = subject.user!
                    ElloProvider.sharedProvider = ElloProvider.ErrorStubbingProvider()
                }

                describe("@moreButton") {
                    it("not selected block") {
                        user.relationshipPriority = .Inactive
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Block)
                        expect(user.relationshipPriority).to(equal(RelationshipPriority.Inactive))
                    }

                    it("not selected mute") {
                        user.relationshipPriority = .Inactive
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Mute)
                        expect(user.relationshipPriority).to(equal(RelationshipPriority.Inactive))
                    }

                    it("selected block") {
                        user.relationshipPriority = .Block
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Inactive)
                        expect(user.relationshipPriority).to(equal(RelationshipPriority.Block))
                    }

                    it("selected mute") {
                        user.relationshipPriority = .Mute
                        subject.moreButtonTapped()
                        let presentedVC = subject.presentedViewController as! BlockUserModalViewController
                        presentedVC.updateRelationship(.Inactive)
                        expect(user.relationshipPriority).to(equal(RelationshipPriority.Mute))
                    }
                }
            }

            xcontext("snapshots") {
                let subject = ProfileViewController(userParam: "42")
                subject.currentUser = currentUser
                validateAllSnapshots(subject)
            }

            xcontext("snapshots - currentUser") {
                let user: User = stub([:])
                let subject = ProfileViewController(user: user)
                subject.currentUser = currentUser
                beforeEach {
                    showController(subject)
                    subject.currentUser = user
                    subject.updateCurrentUser(user)
                }
                validateAllSnapshots(subject)
            }
        }
    }
}
