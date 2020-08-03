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

class Model: ObservableObject {
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
            objectWillChange.send()
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
            objectWillChange.send()
        }
    }

    var error: Error?
    
    var objectWillChange = PassthroughSubject<Void, Never>()
    
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
    enum SomeError: LocalizedError, CustomStringConvertible {
        case validateStringIsNotUTF8(String)
        var description: String {
            switch self {
            case let .validateStringIsNotUTF8(value): return "Value <\(value)> is not `String.UTF8`."
            }
        }
        var localizedDescription: String {
            return self.description
        }
    }
    
    static func validate(value: String) -> Result<String, Error> {
        guard let data = value.data(using: .utf8) else {
            return .failure(SomeError.validateStringIsNotUTF8(value))
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
    enum SomeError: LocalizedError, CustomStringConvertible {
        case encoding(String)
        case decodeToBase64EncodedDataIsInvalid(String)
        case decodeToUTF8StringIsInvalid(Data)
        var description: String {
            switch self {
            case let .encoding(value): return "Value <\(value)> can't be encoded."
            case let .decodeToBase64EncodedDataIsInvalid(value): return "Value <\(value)> can't be decoded to `Data.Base64`."
            case let .decodeToUTF8StringIsInvalid(value): return "Value <\(value)> can't be decoded to `String.UTF8`."
            }
        }
        var errorDescription: String? {
            return self.description
        }
    }
    static func encode(value: String) -> Result<String, Error> {
        guard let data = value.data(using: .utf8) else {
            return .failure(SomeError.encoding(value))
        }
        let string = data.base64EncodedString()
        return .success(string)
    }
    
    static func decode(value: String) -> Result<String, Error> {
        guard let data = Data(base64Encoded: value) else {
            return .failure(SomeError.decodeToBase64EncodedDataIsInvalid(value))
        }
        guard let string = String(bytes: data, encoding: .utf8) else {
            return .failure(SomeError.decodeToUTF8StringIsInvalid(data))
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

class PublishersModel: ObservableObject {
    @Published var raw: Raw
    @Published var pretty: Pretty
    
    var willChange: AnyPublisher<Result<(Raw, Pretty), Error>, Never> = Empty().eraseToAnyPublisher()
    required init(raw: Raw, pretty: Pretty) {
        self.raw = raw
        self.pretty = pretty
        
        let rawPublisher = $raw.map { (raw) -> Result<(Raw, Pretty), Error> in
            let decoded = Base64Coder.decode(value: raw.string).flatMap { JSON64Coder.decode(value: $0) }
            return decoded.flatMap { rhs in
                return .success((Raw(string: raw.string), Pretty(string: rhs)))
            }
        }
        
        let prettyPublisher = $pretty.map { (pretty) -> Result<(Raw, Pretty), Error> in
            let encoded = JSON64Coder.encode(value: pretty.string).flatMap { Base64Coder.encode(value: $0) }
            return encoded.flatMap { lhs in
                return .success((Raw(string: lhs), Pretty(string: pretty.string)))
            }
        }
                
        let publisher = rawPublisher.merge(with: prettyPublisher).eraseToAnyPublisher()
        self.willChange = publisher
    }
}

// MARK: Structures
extension PublishersModel {
    struct Raw {
        var string: String
    }
    struct Pretty {
        var string: String
    }
}

// MARK: Example
extension PublishersModel {
    static func example() -> Self {
        let raw = Raw(string: "eyJleGFtcGxlIjoidmFsdWUifQ==")
        let pretty = Pretty(string: "{\"example\":\"value\"}")
        return self.init(raw: raw, pretty: pretty)
    }
}
