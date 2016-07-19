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
                changeExecuting(false)
            }
            else if let block = newValue where _executing {
                block(done)
            }
        }
    }
    private var _executing: Bool = false
    override public var executing: Bool {
        return _executing
    }
    private var _finished: Bool = false
    override public var finished: Bool {
        return _finished
    }
    override public var asynchronous: Bool { return true }

    public init(block: AsyncBlock? = nil) {
        _block = block
        super.init()
    }

    override public func start() {
        guard !_finished else {
            return
        }
        guard !cancelled else {
            done()
            return
        }

        changeExecuting(true)
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

    private func done() {
        changeExecuting(false)
        changeFinished(true)
    }

    func changeFinished(finished: Bool) {
        self.willChangeValueForKey("isFinished")
        self._finished = finished
        self.didChangeValueForKey("isFinished")
    }

    func changeExecuting(executing: Bool) {
        self.willChangeValueForKey("isExecuting")
        self._executing = executing
        self.didChangeValueForKey("isExecuting")
    }
}
