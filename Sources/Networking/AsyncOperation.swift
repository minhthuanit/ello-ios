////
///  AsyncOperation.swift
//

import Foundation

public class AsyncOperation: NSOperation {
    public typealias AsyncBlock = (() -> Void) -> Void
    var _block: AsyncBlock?
    var block: AsyncBlock? {
        get { return _block }
        set {
            guard _block == nil else { return }
            _block = newValue
            if cancelled && _executing {
                executing = false
            }
            else if let block = newValue where _executing {
                block(done)
            }
        }
    }

    private var _executing: Bool = false
    override public var executing: Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }

    private var _finished: Bool = false
    override public var finished: Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }

    override public var asynchronous: Bool { return true }

    public init(block: AsyncBlock? = nil) {
        _block = block
        super.init()
    }

    override public func start() {
        guard !finished else {
            return
        }
        guard !cancelled else {
            done()
            return
        }

        executing = true
        block?(done)
    }

    public func run(block: () -> Void = {}) {
        self.block = { done in
            block()
            done()
        }
    }
}

private extension AsyncOperation {

    func done() {
        executing = false
        finished = true
    }
}
