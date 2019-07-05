# Base64CoderSwiftUI
This is a simple base64 coder with dynamic updates.

## Urgent

This project is powered by Combine framework and suggested task can be accomplished by merging two publishers.

```swift
class PublishersModel: BindableObject {
    @Published var raw: Raw
    @Published var pretty: Pretty
    
    var didChange: AnyPublisher<Result<(Raw, Pretty), Error>, Never> = Publishers.Empty().eraseToAnyPublisher()
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
        self.didChange = publisher
    }
}
```

## Purpose

This project shows corner stones of mutually connected components with single source of truth in SwiftUI.

## Overview

We have a model which provides two bindings: `raw` and `pretty` for `EncodedView` and `DecodedView` respectively.

On each update we receive `didSet` hook in model where we should check if value of mutual connected component is changed.

Also we have an error indication which is hosted at `ErrorView`.

## Data Workflow

### EncodedView

1. Receive update.
2. Call `didSet`.
3. Check error absence.
3. Check `pretty` similarity.
4. Call `didChange`.

### DecodedView

1. Receive update.
2. Call `didSet`.
3. Check error absence.
4. Check `raw` similarity.
4. Call `didChange`.
