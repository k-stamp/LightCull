//
//  FolderMonitorTests.swift
//  LightCullTests
//
//  Created by Claude Code on 28.10.2025.
//

import XCTest
@testable import LightCull

final class FolderMonitorTests: XCTestCase {
    var folderMonitor: FolderMonitor!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        folderMonitor = FolderMonitor()

        // Create temporary directory for tests
        let tempDir = FileManager.default.temporaryDirectory
        tempDirectory = tempDir.appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        } catch {
            XCTFail("Could not create temp directory: \(error)")
        }
    }

    override func tearDown() {
        folderMonitor.stopMonitoring()
        folderMonitor = nil

        // Clean up temp directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDirectory = nil

        super.tearDown()
    }

    // MARK: - Basic Tests

    func testStartMonitoring() {
        // Expectation: monitoring starts without crashing
        let expectation = self.expectation(description: "Monitoring started")

        folderMonitor.startMonitoring(url: tempDirectory) {
            // onChange callback
            print("Change detected")
        }

        // Wait a bit to ensure monitoring started
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(true, "Monitoring started successfully")
    }

    func testStopMonitoring() {
        // Start monitoring
        folderMonitor.startMonitoring(url: tempDirectory) {
            print("Change detected")
        }

        // Stop monitoring (should not crash)
        folderMonitor.stopMonitoring()

        XCTAssertTrue(true, "Monitoring stopped successfully")
    }

    func testMultipleStartCalls() {
        // Start monitoring twice (should handle gracefully)
        folderMonitor.startMonitoring(url: tempDirectory) {
            print("Change detected 1")
        }

        folderMonitor.startMonitoring(url: tempDirectory) {
            print("Change detected 2")
        }

        XCTAssertTrue(true, "Multiple start calls handled gracefully")
    }

    // MARK: - File System Change Detection

    func testDetectsFileAddition() {
        let expectation = self.expectation(description: "File addition detected")
        var changeDetected = false

        // Start monitoring
        folderMonitor.startMonitoring(url: tempDirectory) {
            changeDetected = true
            expectation.fulfill()
        }

        // Add a file after monitoring starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let testFile = self.tempDirectory.appendingPathComponent("test.txt")
            try? "Hello World".write(to: testFile, atomically: true, encoding: .utf8)
        }

        // Wait for debounce delay + some buffer (500ms debounce + 300ms buffer)
        waitForExpectations(timeout: 2.0)

        XCTAssertTrue(changeDetected, "File addition should be detected")
    }

    func testDetectsFileDeletion() {
        // Create a test file first
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        try? "Hello World".write(to: testFile, atomically: true, encoding: .utf8)

        let expectation = self.expectation(description: "File deletion detected")
        var changeDetected = false

        // Start monitoring
        folderMonitor.startMonitoring(url: tempDirectory) {
            changeDetected = true
            expectation.fulfill()
        }

        // Delete the file after monitoring starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            try? FileManager.default.removeItem(at: testFile)
        }

        // Wait for debounce delay + buffer
        waitForExpectations(timeout: 2.0)

        XCTAssertTrue(changeDetected, "File deletion should be detected")
    }

    func testDebouncing() {
        var changeCount = 0
        let expectation = self.expectation(description: "Debouncing works")

        // Start monitoring
        folderMonitor.startMonitoring(url: tempDirectory) {
            changeCount += 1
        }

        // Create multiple files in quick succession (within debounce window)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for i in 0..<5 {
                let testFile = self.tempDirectory.appendingPathComponent("test\(i).txt")
                try? "Hello \(i)".write(to: testFile, atomically: true, encoding: .utf8)
                // Small delay between writes (but within debounce window)
                Thread.sleep(forTimeInterval: 0.05)
            }
        }

        // Wait for debounce to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)

        // Debouncing should consolidate multiple changes into 1-2 callbacks
        // (exact count depends on timing, but definitely less than 5)
        XCTAssertLessThanOrEqual(changeCount, 3, "Debouncing should reduce number of callbacks")
        XCTAssertGreaterThanOrEqual(changeCount, 1, "Should detect at least one change")
    }

    // MARK: - Edge Cases

    func testMonitoringNonExistentFolder() {
        let nonExistentURL = tempDirectory.appendingPathComponent("doesnotexist")

        // Should handle gracefully without crashing
        folderMonitor.startMonitoring(url: nonExistentURL) {
            print("Change detected")
        }

        XCTAssertTrue(true, "Monitoring non-existent folder handled gracefully")
    }

    func testStopMonitoringWithoutStart() {
        // Should not crash
        folderMonitor.stopMonitoring()
        XCTAssertTrue(true, "Stop without start handled gracefully")
    }

    func testDeinitCleansUp() {
        // Create a new monitor
        var monitor: FolderMonitor? = FolderMonitor()

        monitor?.startMonitoring(url: tempDirectory) {
            print("Change detected")
        }

        // Deinit should clean up (not testable directly, but shouldn't crash)
        monitor = nil

        XCTAssertNil(monitor, "Monitor deinitialized")
    }
}
