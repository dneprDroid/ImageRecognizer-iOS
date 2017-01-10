//
//  ImageRecognizerUITests.swift
//  ImageRecognizerUITests
//
//  Created by user on 12/24/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import XCTest

class ImageRecognizerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        galleryTest()
        
       //drawingTest()
    }
    
    private func galleryTest() {
        let app = XCUIApplication()
        app.buttons["ic file image"].tap() // go to the gallery
        
        //gallery image picker
        app.cells.elementBoundByIndex(1).tap()
        app.cells.elementBoundByIndex(0).tap()
        
        app.buttons["What is"].tap()
        let label = app.staticTexts["toastView"] // recognition result
        
        XCTAssertFalse(!label.exists, "Image recognition failed (check NNManager)")
        XCTAssertFalse(label.label.isEmpty, "Image recognition failed")
    }
    
    private func drawingTest() {
        let app = XCUIApplication()
        app.buttons["ic eraser variant"].tap() // clean drawing area
        app.buttons["ic lead pencil"].tap() // enable drawing mode
        
        let paintView = app.images["paintView"]
        let fromCoordinate = paintView.coordinateWithNormalizedOffset(CGVector(dx: 0, dy: 10))
        let toCoordinate = paintView.coordinateWithNormalizedOffset(CGVector(dx: 0, dy: 20))
        fromCoordinate.pressForDuration(0, thenDragToCoordinate: toCoordinate)
        
        app.buttons["What is"].tap()
        let label = app.staticTexts["toastView"].label // recognition result
        XCTAssertNotNil(label, "Image recognition failed")
    }
    
}
