//
//  FeliCaServiceCode.swift
//  nfc
//
//  Created by kalan on 2019/10/22.
//  Copyright © 2019 kalan. All rights reserved.
//

import Foundation

public enum FeliCaServiceCode: UInt16, CaseIterable {
    case balance = 0x008b
    case entryExitHistory = 0x090f
    
    func convertToServiceList() -> Data {
        return Data(
            [UInt8(self.rawValue >> 8 & 0x00FF), UInt8(self.rawValue & 0x00FF)].reversed()
        )
    }
}
