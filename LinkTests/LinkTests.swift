//
//  LinkTests.swift
//  LinkTests
//
//  Created by Jeremy Tregunna on 2016-02-24.
//  Copyright © 2016 Jeremy Tregunna. All rights reserved.
//

import XCTest
@testable import Link

class LinkTests: XCTestCase {
    var link = Link<Int>()
    
    override func setUp() {
        super.setUp()
        link = Link<Int>()
    }

    func testReceiveValue() {
        let exp = expectationWithDescription("receive")
        link.receive { value in
            XCTAssertEqual(42, value)
            exp.fulfill()
        }
        link.send(42)
        
        waitForExpectationsWithTimeout(1) { (err) -> Void in
            XCTAssertNil(err)
        }
    }
    
    func testReceiveMultipleValues() {
        let exp = expectationWithDescription("receive")
        let values = [23, 42]
        var saw = [Int]()

        link.receive { value in
            saw.append(value)
            if values.last == value {
                exp.fulfill()
            }
        }
        
        for value in values {
            link.send(value)
        }
        
        waitForExpectationsWithTimeout(1) { (err) -> Void in
            XCTAssertNil(err)
            XCTAssertEqual(saw, values)
        }
    }
    
    func testMultipleReceiveValues() {
        let exp1 = expectationWithDescription("receive1")
        let exp2 = expectationWithDescription("receive2")

        link.receive { value in
            XCTAssertEqual(42, value)
            exp1.fulfill()
        }
        link.receive { value in
            XCTAssertEqual(42, value)
            exp2.fulfill()
        }
        link.send(42)
        
        waitForExpectationsWithTimeout(1) { (err) -> Void in
            XCTAssertNil(err)
        }
    }
    
    func testMultipleReceivesMultipleValues() {
        let exp1 = expectationWithDescription("receive1")
        let exp2 = expectationWithDescription("receive2")
        let values = [23, 42]
        var saw1 = [Int]()
        var saw2 = [Int]()
        
        link.receive { value in
            saw1.append(value)
            if values.last == value {
                exp1.fulfill()
            }
        }
        link.receive { value in
            saw2.append(value)
            if values.last == value {
                exp2.fulfill()
            }
        }
        
        for value in values {
            link.send(value)
        }
        
        waitForExpectationsWithTimeout(1) { (err) -> Void in
            XCTAssertNil(err)
            XCTAssertEqual(saw1, values)
            XCTAssertEqual(saw2, values)
        }
    }
    
    func testDoesNotReceiveIfAskingAfterValueSent() {
        link.send(42)
        link.receive { value in
            XCTFail("Something's wibbly wobbly.")
        }
    }
    
    func testRebroadcastOfLastValue() {
        let exp = expectationWithDescription("rebroadcast")

        link = Link<Int>(rebroadcastLastValue: true)
        link.send(42)
        link.receive { value in
            XCTAssertEqual(42, value)
            exp.fulfill()
        }
        
        waitForExpectationsWithTimeout(1) { (err) -> Void in
            XCTAssertNil(err)
        }
    }
    
    func testWontReceiveValueAfterUnsubscribing() {
        let uuid = link.receive { value in
            XCTFail("Received value after unsubscribing")
        }
        link.unsubscribe(uuid)
        link.send(42)
    }
    
    func testWontRemoveFilterAfterUnsubscribingIfSubscriptionsRemain() {
        link.filter { value in
            return value % 2 == 0
        }

        link.receive { value in
            XCTFail("Did not filter out odd value")
        }
        let uuid = link.receive { value in
            XCTFail("Received value after unsubscribing")
        }
        link.unsubscribe(uuid)
        link.send(23)
    }
    
    func testRemovesFilterWhenLastSubscriptionUnsubscribed() {
        link.filter { value in
            return value % 2 == 0
        }
        let uuid = link.receive { value in
            XCTFail("Received value after unsubscribing")
        }
        link.unsubscribe(uuid)
        
        link.receive { value in
            XCTAssertEqual(23, value)
        }

        link.send(23)
    }
    
    func testFilteringValues() {
        var saw = [Int]()
        
        link.filter { value in
            return value % 2 == 0
        }.receive { value in
            saw.append(value)
        }
        
        link.send(23)
        link.send(42)
        
        XCTAssertEqual([42], saw)
    }
}
