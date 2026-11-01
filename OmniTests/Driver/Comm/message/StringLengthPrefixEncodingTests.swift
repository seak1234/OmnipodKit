//
//  StringLengthPrefixEncodingTests.swift
//  OmniTests
//
//  From OmniBLE/OmniBLETests/Drive/Comm/message/StringLengthPrefixEncodingTests.swift
//  Created by Bill Gestrich on 12/11/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import OmnipodKit

class StringLengthPrefixEncodingTests: XCTestCase {

    func testRejectsTruncatedPayloadEvenWhenLengthIncludesAvailablePrefixBytes() {
        for key in ["P0=", "0.0=", "3.12="] {
            for length in [1, 2, 3, 16, 255, 65535] {
                for missingBytes in 1...min(2, length) {
                    var payload = Data(key.utf8)
                    payload.appendBigEndian(UInt16(length))
                    payload.append(Data(repeating: 0x42, count: length - missingBytes))
                    XCTAssertThrowsError(try StringLengthPrefixEncoding.parseKeys([key], payload),
                                         "key \(key), length \(length), missing \(missingBytes)")
                }
            }
        }
    }

    func testParsesCompleteResponseAndEmptyTrailingKey() throws {
        for key in ["P0=", "0.0=", "3.12="] {
            let content = Data([0x01, 0x02, 0x03])
            let payload = StringLengthPrefixEncoding.formatKeys(keys: [key, ",G0.0"], payloads: [content, Data()])
            let parsed = try StringLengthPrefixEncoding.parseKeys([key, ",G0.0"], payload)
            XCTAssertEqual(parsed, [content, Data()])
        }
    }

    func testRejectsTruncatedLengthPrefix() {
        for prefix in [Data(), Data([0x00])] {
            XCTAssertThrowsError(try StringLengthPrefixEncoding.parseKeys(["0.0=", ",G0.0"], Data("0.0=".utf8) + prefix))
        }
    }

    let p0Payload = Data(hexadecimalString: "50,30,3d,00,01,a5".replacingOccurrences(of: ",", with: ""))!
    let p0Content = Data(hexadecimalString:"a5")!

    func testFormatKeysP0() {
        let payload = StringLengthPrefixEncoding.formatKeys(keys: ["P0="], payloads: [p0Content])
        assert(p0Payload.hexadecimalString == payload.hexadecimalString)
    }

    func testParseKeysP0() {
        let parsed = try! StringLengthPrefixEncoding.parseKeys(["P0="], p0Payload)
        assert(parsed.count ==  1)
        assert(parsed[0].toHexString() == p0Content.toHexString())
    }
}
