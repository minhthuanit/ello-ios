////
///  AsyncOperationSpec.swift
//

import Ello
import Quick
import Nimble
import Moya

class AsyncOperationSpec: QuickSpec {
    override func spec() {
        describe("AsyncOperation") {

            var queue: NSOperationQueue!
            var subject: AsyncOperation!

            beforeEach {
                queue = NSOperationQueue()
            }

            context("created WITH a block") {
                var executed = false
                beforeEach {
                    executed = false
                    subject = AsyncOperation() { done in
                        delay(0.1) {
                            executed = true
                            done()
                        }
                    }
                }

                it("can be executed") {
                    queue.addOperation(subject)
                    queue.waitUntilAllOperationsAreFinished()
                    expect(executed) == true
                }

                it("ignores block assignment (only runs initial block)") {
                    var hit = false
                    subject.run { hit = true }

                    queue.addOperation(subject)
                    queue.waitUntilAllOperationsAreFinished()
                    expect(executed) == true
                    expect(hit) == false
                }
            }

            context("block added later") {
                beforeEach {
                    subject = AsyncOperation()
                }

                it("can be executed") {
                    var executed = false
                    subject.run {
                        executed = true
                    }
                    expect(executed) == false
                    queue.addOperation(subject)
                    queue.waitUntilAllOperationsAreFinished()
                    expect(executed) == true
                }

                it("can be assigned after operation is added") {
                    var executed = false
                    queue.addOperation(subject)
                    subject.run {
                        executed = true
                    }
                    queue.waitUntilAllOperationsAreFinished()
                    expect(executed) == true
                }

                it("does not run when cancelled") {
                    let queue = NSOperationQueue()
                    var executed = false
                    let subject = AsyncOperation()
                    queue.addOperation(subject)
                    queue.cancelAllOperations()
                    subject.run {
                        executed = true
                    }
                    queue.waitUntilAllOperationsAreFinished()

                    expect(executed) == false
                }
            }
        }
    }
}
