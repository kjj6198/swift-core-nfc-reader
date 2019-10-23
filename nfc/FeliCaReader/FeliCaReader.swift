//
//  FeliCaReader.swift
//  nfc
//
//  Created by kalan on 2019/10/22.
//  Copyright © 2019 kalan. All rights reserved.
//

import CoreNFC
import Foundation


public enum FeliCaTagError: Error {
    case countExceed
    case typeMismatch
    case statusError
    case serviceCodeUnavailable
    case userCancel
    case becomeInvalidate
    case cannotConnect
    case serviceCodeNotSet
}

struct ServiceCodeAccess {
    var serviceCodeList: [FeliCaServiceCode]
    var blocks: Int
    
    func convert() -> ([Data], [Data]) {
        let blocksList = (0..<UInt8(blocks)).map { Data([0x80, $0]) }
        return (
            serviceCodeList.map({ $0.convertToServiceList() }),
            blocksList
        )
    }
}

@available(iOS 13.0, *)
public class FeliCaReader: NSObject, NFCTagReaderSessionDelegate {
    internal var session: NFCTagReaderSession?
    internal var serviceCodeAccess: ServiceCodeAccess?
    internal let delegate: FeliCaReaderDelegate?
    
    private override init() {
        self.delegate = nil
    }
    
    public init(delegate: FeliCaReaderDelegate) {
        self.delegate = delegate
    }
    
    public func read(_ serviceCodeList: [FeliCaServiceCode], blocks: Int) {
        // or use Future?
        self.serviceCodeAccess = ServiceCodeAccess(
            serviceCodeList: serviceCodeList,
            blocks: blocks
        )
        
        self.session = NFCTagReaderSession(pollingOption: .iso18092, delegate: self)
        self.session?.begin()
    }

    public func isReadingAvailable() -> Bool {
        return NFCTagReaderSession.readingAvailable
    }
    
    public func finish(errorMessage: String?) {
        if errorMessage != nil {
            self.session?.invalidate()
        } else {
            self.session?.invalidate(errorMessage: errorMessage!)
        }
    }

    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("tagReaderSessionDidBecomeActive(_:)")
        self.delegate?.readerDidBecomeActive(self)
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                self.delegate?.feliCaReader(self, withError: FeliCaTagError.becomeInvalidate)
            }
        }
        self.session = nil
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 {
            // TODO: make it configurable
            self.delegate?.feliCaReader(self, withError: FeliCaTagError.countExceed)
            return
        }
        
        let tag = tags.first!
        
        session.connect(to: tag) { (error) in
            guard error == nil else {
                session.invalidate(errorMessage: "Failed to connect")
                self.delegate?.feliCaReader(self, withError: FeliCaTagError.cannotConnect)
                return
            }
            
            guard case .feliCa(let feliCaTag) = tag else {
                self.delegate?.feliCaReader(self, withError: FeliCaTagError.typeMismatch)
                return
            }
            
            guard let (serviceCodeList, blockList) = self.serviceCodeAccess?.convert() else {
                self.delegate?.feliCaReader(self, withError: FeliCaTagError.serviceCodeNotSet)
                return
            }
            
            feliCaTag.requestService(nodeCodeList: serviceCodeList) { (data, error) in
                if error != nil {
                    print(error.debugDescription)
                    self.delegate?.feliCaReader(self, withError: FeliCaTagError.serviceCodeUnavailable)
                    return
                }

                for serviceCode in serviceCodeList {
                    feliCaTag.readWithoutEncryption(serviceCodeList: [serviceCode], blockList: blockList) { (status1, status2, dataList, error) in
                        if (status1 != 0 || status2 != 0) {
                            self.delegate?.feliCaReader(self, withError: FeliCaTagError.statusError)
                            return
                        }
                        
                        if error != nil {
                            self.delegate?.feliCaReader(self, withError: FeliCaTagError.statusError)
                            return
                        }

                        self.delegate?.feliCaReader(self, didRead: FeliCaCard(dataList, feliCaTag.currentIDm, feliCaTag.currentSystemCode))
                    }
                    
                    
                }
            }
            
            
        }
    }
}
