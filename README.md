# Base64CoderSwiftUI
This is a simple base64 coder with dynamic updates.

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
