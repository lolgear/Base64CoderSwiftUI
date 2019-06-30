//
//  Model.swift
//  Base64CoderSwiftUI
//
//  Created by Dmitry Lobanov on 30/06/2019.
//  Copyright © 2019 Dmitry Lobanov. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class Model: BindableObject {
    var raw: Raw {
        didSet {
            let pretty = self.pretty
            let result = self.decoded()
            switch result {
            case .success(let value):
                self.error = nil
                if pretty.string != value {
                    self.pretty.string = value
                }
                else {
                    // prevent infinite loop
                }
            case .failure(let error):
                self.error = error
            }
            didChange.send()
        }
    }
    
    var pretty: Pretty {
        didSet {
            let raw = self.raw
            let result = self.encoded()
 
            switch result {
            case .success(let value):
                self.error = nil
                if raw.string != value {
                    self.raw.string = value
                }
                else {
                    // prevent infinite loop
                }
            case .failure(let error):
                self.error = error
            }
            didChange.send()
        }
    }

    var error: Error?
    
    var didChange = PassthroughSubject<Void, Never>()
    
    required init(raw: Raw, pretty: Pretty) {
        self.raw = raw
        self.pretty = pretty
    }
}

protocol StringMutationsProtocol {
    static func encode(value: String) -> Result<String, Error>
    static func decode(value: String) -> Result<String, Error>
}

class JSON64Coder : StringMutationsProtocol {
    enum SomeError: String, Error {
        case encoding, decoding, serialization
    }
    
    static func validate(value: String) -> Result<String, Error> {
        guard let data = value.data(using: .utf8) else {
            return .failure(SomeError.decoding)
        }
        do {
            try JSONSerialization.jsonObject(with: data, options: [])
        }
        catch let error {
            return .failure(error)
        }
        return .success(value)
    }
    
    static func encode(value: String) -> Result<String, Error> {
        return self.validate(value: value)
    }
    
    static func decode(value: String) -> Result<String, Error> {
        return self.validate(value: value)
    }
}

class Base64Coder : StringMutationsProtocol {
    enum SomeError: String, Error {
        case encoding, decoding
    }
    static func encode(value: String) -> Result<String, Error> {
        guard let data = value.data(using: .utf8) else {
            return .failure(SomeError.encoding)
        }
        let string = data.base64EncodedString()
        return .success(string)
    }
    
    static func decode(value: String) -> Result<String, Error> {
        guard let data = Data(base64Encoded: value) else {
            return .failure(SomeError.decoding)
        }
        guard let string = String(bytes: data, encoding: .utf8) else {
            return .failure(SomeError.decoding)
        }
        return .success(string)
    }
}

// MARK: Calculations
extension Model {
    func decoded() -> Result<String, Error> {
        Base64Coder.decode(value: self.raw.string).flatMap { JSON64Coder.decode(value: $0) }
    }
    func encoded() -> Result<String, Error> {
        JSON64Coder.encode(value: self.pretty.string).flatMap { Base64Coder.encode(value: $0) }
    }
}

// MARK: Structures
extension Model {
    struct Raw {
        var string: String
    }
    struct Pretty {
        var string: String
    }
}

// MARK: Example
extension Model {
    static func example() -> Self {
        let raw = Raw(string: "eyJleGFtcGxlIjoidmFsdWUifQ==")
        let pretty = Pretty(string: "{\"example\":\"value\"}")
        return self.init(raw: raw, pretty: pretty)
    }
}
