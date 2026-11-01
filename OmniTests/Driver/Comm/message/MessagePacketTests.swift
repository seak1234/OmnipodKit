//
//  MessagePacketTests.swift
//  OmniTests
//
//  From OmniBLE/OmniBLETests/Drive/Comm/message/MessagePacketTests.swift
//  Created by Bill Gestrich on 12/11/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import OmnipodKit

class MessagePacketTests: XCTestCase {

    func testEncryptedPacketsRejectEveryTruncationIncludingMissingAuthenticationTag() throws {
        for type in [MessageType.ENCRYPTED, .ENCRYPTED_SIGNED] {
            let packet = MessagePacket(type: type, source: 1, destination: 2,
                                       payload: Data(repeating: 0x42, count: 32), sequenceNumber: 1)
            let encoded = packet.asData()
            for count in 0..<encoded.count {
                XCTAssertThrowsError(try MessagePacket.parse(payload: Data(encoded.prefix(count))),
                                     "type \(type), length \(count)")
            }
            let parsed = try MessagePacket.parse(payload: encoded)
            XCTAssertEqual(parsed.type, type)
            XCTAssertEqual(parsed.payload, packet.payload)
        }
    }

    func testUnencryptedPacketDoesNotRequireAuthenticationTag() throws {
        let packet = MessagePacket(type: .SESSION_ESTABLISHMENT, source: 1, destination: 2,
                                   payload: Data([0x01]), sequenceNumber: 1)
        let parsed = try MessagePacket.parse(payload: packet.asData())
        XCTAssertEqual(parsed.payload, packet.payload)
    }
    
    let payloadString = "54,57,11,01,07,00,03,40,08,20,2e,a8,08,20,2e,a9,ab,35,d8,31,60,9b,b8,fe,3a,3b,de,5b,18,37,24,9a,16,db,f8,e4,d3,05,e9,75,dc,81,7c,37,07,cc,41,5f,af,8a".replacingOccurrences(of: ",", with: "")
    
    func testParseMessagePacket() {
        let msg = try! MessagePacket.parse(payload: Data(hexadecimalString: payloadString)!)
        assert(msg.type == MessageType.ENCRYPTED)
        assert(msg.source == Id.fromInt(136326824))
        assert(msg.destination == Id.fromInt(136326825))
        assert(msg.sequenceNumber == 7)
        assert(msg.ackNumber == 0)
        assert(msg.eqos == 1)
        assert(msg.priority == false)
        assert(msg.lastMessage == false)
        assert(msg.gateway == false)
        assert(msg.sas == true)
        assert(msg.tfs == false)
        assert(msg.version == 0)
        let index1 = payloadString.index(payloadString.startIndex, offsetBy: 32)
        let toCheck = payloadString[index1...]
        assert(msg.payload.hexadecimalString == String(toCheck))
    }
    
    
    func testSerializeMessagePacket() {
        let payload = Data(hexadecimalString: payloadString)!
        let msg = MessagePacket(type: .ENCRYPTED,
                                source: Id.fromInt(136326824).toUInt32(),
                                destination: Id.fromInt(136326825).toUInt32(),
                                payload: payload,
                                sequenceNumber: 0,
                                ack: false, ackNumber: 0,
                                eqos: 1,
                                priority: false,
                                lastMessage: false,
                                gateway: false,
                                sas: true,
                                tfs: false,
                                version: 0)
        
        assert(msg.payload.hexadecimalString == payloadString)
    }

}
