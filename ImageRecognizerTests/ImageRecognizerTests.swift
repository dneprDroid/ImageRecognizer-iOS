//
//  ImageRecognizerTests.swift
//  ImageRecognizerTests
//
//  Created by user on 12/24/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import XCTest
@testable import ImageRecognizer

class ImageRecognizerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNNManager() {
        let image = UIImage(named: "test_image")
        do {
            try NNManager.shared().recognizeImage(image) { tag in
                XCTAssertTrue(tag == nil || tag.isEmpty, "Image description is empty!")
            }
        } catch _ {
            XCTFail("Recognition falied")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
