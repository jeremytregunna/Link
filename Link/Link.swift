//
//  Link.swift
//  Link
//
//  Created by Jeremy Tregunna on 2016-02-24.
//  Copyright © 2016 Jeremy Tregunna. All rights reserved.
//

import Foundation

public class Link<T> {
    typealias subBlock = (T) -> Void
    typealias filterBlock = (T) -> Bool

    private var subscriptions = [NSUUID: subBlock]()
    private var filter: filterBlock?
    private var lastValue: T?
    private var queue: dispatch_queue_t

    public var rebroadcastLastValue: Bool
    
    public required init(rebroadcastLastValue rebroadcast: Bool) {
        self.rebroadcastLastValue = rebroadcast
        self.queue = dispatch_queue_create("ca.tregunna.link.queue", DISPATCH_QUEUE_CONCURRENT)
    }

    public convenience init() {
        self.init(rebroadcastLastValue: false)
    }

    public func send(value: T) {
        dispatch_barrier_async(self.queue) {
            self.lastValue = value
        }

        for (_, sub) in subscriptions {
            dispatch_sync(self.queue) {
                if let f = self.filter {
                    if f(value) {
                        sub(value)
                        return
                    }
                } else {
                    sub(value)
                }
            }
        }
    }
    
    public func subscribe(block: (T) -> Void) -> NSUUID {
        let uuid = NSUUID()
        dispatch_sync(self.queue) {
            self.subscriptions[uuid] = block

            if self.rebroadcastLastValue {
                if let v = self.lastValue {
                    block(v)
                }
            }
        }
        return uuid
    }

    public func unsubscribe(uuids: NSUUID...) {
        dispatch_barrier_sync(self.queue) {
            for arg: NSUUID in uuids {
                self.subscriptions[arg] = nil
            }
            if self.subscriptions.count == 0 {
                self.filter = nil
            }
        }
    }
    
    public func filter(block: (T) -> Bool) -> Self {
        dispatch_barrier_sync(self.queue) {
            self.filter = block
        }
        return self
    }
}
