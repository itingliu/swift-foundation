//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if !FOUNDATION_FRAMEWORK

@available(macOS 10.12, *)
open class Unit {

    open var symbol: String
    public init(symbol: String) {
        self.symbol = symbol
    }
}

public struct Measurement<UnitType : Unit> {
    // Stub
}

public class UnitDuration: Unit {}

#endif
