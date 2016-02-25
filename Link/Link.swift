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

    private var lock = NSObject()
    private var subscriptions = [NSUUID: subBlock]()
    private var filter: filterBlock?
    private var lastValue: T?

    public var rebroadcastLastValue: Bool
    
    public required init(rebroadcastLastValue rebroadcast: Bool) {
        self.rebroadcastLastValue = rebroadcast
    }

    public convenience init() {
        self.init(rebroadcastLastValue: false)
    }

    public func send(value: T) {
        objc_sync_enter(lock)
        lastValue = value
        objc_sync_exit(lock)
        for (_, sub) in subscriptions {
            if let f = filter {
                if f(value) {
                    sub(value)
                    return
                }
            } else {
                sub(value)
            }
        }
    }
    
    public func receive(block: (T) -> Void) -> NSUUID {
        let uuid = NSUUID()
        objc_sync_enter(lock)
        subscriptions[uuid] = block
        objc_sync_exit(lock)
        if rebroadcastLastValue {
            guard let v = lastValue else { return uuid }
            block(v)
        }
        return uuid
    }
    
    public func unsubscribe(uuids: NSUUID...) {
        objc_sync_enter(lock)
        for arg: NSUUID in uuids {
            subscriptions[arg] = nil
        }
        if subscriptions.count == 0 {
            filter = nil
        }
        objc_sync_exit(lock)
    }
    
    public func filter(block: (T) -> Bool) -> Self {
        objc_sync_enter(lock)
        filter = block
        objc_sync_exit(lock)
        return self
    }
}
