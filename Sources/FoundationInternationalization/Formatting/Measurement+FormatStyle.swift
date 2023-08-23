//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Measurement where UnitType: Dimension {
    public struct FormatStyle : FormatStyle, Sendable  {
        public struct UnitWidth : Codable, Hashable, Sendable {
            /// Examples for formatting a measurement with value of 37.20:
            ///
            /// Shows the unit in its full spelling.
            /// For example, "37.20 Calories", "37,20 litres"
            public static var wide: Self { .init(option: .wide) }

            /// Shows the unit using abbreviation.
            /// For example, "37.20 Cal", "37,2 L"
            public static var abbreviated: Self { .init(option: .abbreviated) }

            /// Shows the unit in the shortest form possible, and may condense the spacing between the value and the unit.
            /// For example, "37.20Cal", "37,2L"
            public static var narrow: Self { .init(option: .narrow) }

            enum Option: Int, Codable, Hashable {
                case wide
                case abbreviated
                case narrow
            }
            var option: Option

            var skeleton: String {
                switch option {
                case .wide:
                    return "unit-width-full-name"
                case .abbreviated:
                    return "unit-width-short"
                case .narrow:
                    return "unit-width-narrow"
                }
            }
        }

        public var width: UnitWidth
        public var locale: Locale

        /// Specifies how the value part is formatted.
        public var numberFormatStyle: FloatingPointFormatStyle<Double>?

        public var usage: MeasurementFormatUnitUsage<UnitType>?

        public var attributed: Measurement.AttributedStyle {
            Measurement.AttributedStyle(innerStyle: self)
        }

        public init(width: UnitWidth, locale: Locale = .autoupdatingCurrent, usage: MeasurementFormatUnitUsage<UnitType> = .general, numberFormatStyle: FloatingPointFormatStyle<Double>? = nil) {
            self.width = width
            self.locale = locale
            self.usage = usage
            self.numberFormatStyle = numberFormatStyle
        }
        
        public func locale(_ locale: Locale) -> Self {
            var new = self
            new.locale = locale
            return new
        }

        static func skeleton(_ unitSkeleton: String?, width: UnitWidth, usage: MeasurementFormatUnitUsage<UnitType>?, numberFormatStyle: FloatingPointFormatStyle<Double>?) -> String {
            var stem = ""
            if let unitSkeleton = unitSkeleton {
                stem += unitSkeleton + " " + width.skeleton

                if let usage = usage, usage != .asProvided, UnitType.supportsRegionalPreference {
                    // ICU handles the conversion when using the `usage` skeleton.
                    stem += " usage/" + usage.usage.rawValue
                }
            }

            if let numberFormatSkeleton = numberFormatStyle?.collection.skeleton {
                if stem.count > 0 {
                    stem += " "
                }

                stem += numberFormatSkeleton
            }

            return stem
        }

        // For UnitTemperature only
        var _hidesScaleName: Bool = false

        // MARK: formatting functions

        public func format(_ measurement: Measurement) -> String {
            var result: String?

            if let measurement = measurement as? Measurement<UnitTemperature> {
                if let (skel, value) = skeletonForUsage(measurement) {
                    result = _format(value, withSkeleton: skel)
                }
            } else {
                if let skel = skeleton(forMeasurement: measurement) {
                    result = _format(measurement.value, withSkeleton: skel)
                }

                // It's possible that the input measure unit is not supported by ICU, like N/m^2.
                // Try converting it to the "best unit" ourselves. Perhaps ICU supports that one.
                if result == nil, shouldConvertToBestUnit, let (skel, value) = skeletonForUsage(measurement) {
                    result = _format(value, withSkeleton: skel)
                }
            }

            // Fall-back: format using the base unit
            if result == nil, shouldConvertToBestUnit, let (skel, value) = skeletonForBaseUnit(measurement) {
                result = _format(value, withSkeleton: skel)
            }

            return result ?? formatAsDescription(measurement)
        }

        internal func _format(_ value: Double, withSkeleton skeleton: String) -> String? {
            guard let nf = ICUMeasurementNumberFormatter.create(for: skeleton, locale: locale) else {
                return nil
            }

            return nf.format(value)
        }

        // MARK: -- Skeleton builders

        func skeleton(forMeasurement measurement: Measurement) -> String? {
            guard let unitSkeleton = measurement.unit.skeleton else { return nil }

            return Self.skeleton(unitSkeleton, width: width, usage: usage, numberFormatStyle: numberFormatStyle)
        }

        var shouldConvertToBestUnit: Bool {
            usage != .asProvided
        }

        func skeletonForUsage(_ measurement: Measurement) -> (String, Double)? {
            let bestUnit = bestUnitForUsage(locale, dimension: measurement.unit, usage: usage ?? .general)
            let converted = measurement.converted(to: bestUnit)

            guard let skel = converted.unit.skeleton else { return nil }

            let skeleton = Self.skeleton(skel, width: width, usage: usage, numberFormatStyle: numberFormatStyle)
            return (skeleton, converted.value)
        }

        func skeletonForBaseUnit(_ measurement: Measurement) -> (String, Double)? {
            let measurementInBaseUnit = measurement.inBaseUnit
            guard let baseSkeleton = measurementInBaseUnit.unit.skeleton else { return nil }

            let skeleton = Self.skeleton(baseSkeleton, width: width, usage: usage, numberFormatStyle: numberFormatStyle)
            return (skeleton, measurementInBaseUnit.value)
        }

        // unit-less skeleton that only formats the value part but not the unit
        var numberSkeleton : String {
            Self.skeleton(nil, width: width, usage: usage, numberFormatStyle: numberFormatStyle)
        }

        func formatAsDescription(_ measurement: Measurement) -> String {
            let numstr = _format(measurement.value, withSkeleton: numberSkeleton) ?? String(measurement.value)
            return numstr + " " + measurement.unit.symbol
        }

        // Temperature

        func skeletonForUsage(_ measurement: Measurement<UnitTemperature>) -> (String, Double)? {
            // We always convert the unit to the best unit and omit the "usage" skeleton when formatting temperature for the following reasons:
            // - The skeleton for `_hidesScaleName` is "temperature-generic". It cannot co-exist cannot co-exist with the "usage" skeleton: 104983714
            // - `locale` might specify a temperature override that always takes precendence
            let meas: Measurement<UnitTemperature>
            if let usage, usage.usage != .asProvided {
                let bestUnit = bestUnitForUsage(locale, dimension: measurement.unit as! UnitType, usage: usage) as! UnitTemperature
                meas = measurement.converted(to: bestUnit)
            } else {
                meas = measurement
            }

            guard let unitSkeleton = meas.unit.skeleton else {
                return nil
            }

            let skeleton = Self.skeleton(_hidesScaleName ? "measure-unit/temperature-generic" : unitSkeleton, width: width, usage: nil, numberFormatStyle: numberFormatStyle)
            return (skeleton, meas.value)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Measurement.FormatStyle where UnitType == UnitTemperature {

    /// Hides the scale name. For example, "90°" rather than "90°F" or "90°C" with the `narrow` unit width, or "90 degrees" rather than "90 degrees celcius" or "90 degrees fahrenheit" with the `wide` width.
    public var hidesScaleName: Bool {
        get {
            _hidesScaleName
        }
        set {
            _hidesScaleName = newValue
        }
    }

    public init(width: UnitWidth = .abbreviated, locale: Locale = .autoupdatingCurrent, usage: MeasurementFormatUnitUsage<UnitType> = .general, hidesScaleName: Bool = false, numberFormatStyle: FloatingPointFormatStyle<Double>? = nil) {
        self.width = width
        self.locale = locale
        self.usage = usage
        self.numberFormatStyle = numberFormatStyle
        self.hidesScaleName = hidesScaleName
    }
}

extension Measurement where UnitType == UnitTemperature {
    var asPreferredTemperature: Measurement? {
        guard let preferredTemp = NSLocale._preferredTemperatureUnit() else { return nil }

        var preferredTemperature: Measurement?
        if preferredTemp == NSLocaleTemperatureUnitCelsius {
            preferredTemperature = converted(to: UnitTemperature.celsius)
        } else if preferredTemp == NSLocaleTemperatureUnitFahrenheit {
            preferredTemperature = converted(to: UnitTemperature.fahrenheit)
        }

        return preferredTemperature
    }
}

extension Measurement where UnitType: Dimension {
    var inBaseUnit: Measurement {
        let baseUnit = type(of: unit).baseUnit()
        return converted(to: baseUnit)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension Measurement.FormatStyle where UnitType == UnitInformationStorage {

    public struct ByteCount : Foundation.FormatStyle, Sendable {

        public typealias Style = ByteCountFormatStyle.Style
        public typealias Units = ByteCountFormatStyle.Units

        public var style: Style
        public var allowedUnits: Units
        public var spellsOutZero: Bool
        public var includesActualByteCount: Bool
        public var locale: Locale
        public var attributed: Measurement.AttributedStyle.ByteCount {
            Measurement.AttributedStyle.ByteCount(style: style, allowedUnits: allowedUnits, spellsOutZero: spellsOutZero, includesActualByteCount: includesActualByteCount, locale: locale)
        }

        public init(style: Style, allowedUnits: Units, spellsOutZero: Bool, includesActualByteCount: Bool, locale: Locale) {
            self.style = style
            self.allowedUnits = allowedUnits
            self.spellsOutZero = spellsOutZero
            self.includesActualByteCount = includesActualByteCount
            self.locale = locale
        }

        // MARK: FormatStyle conformance
        public func format(_ value: Measurement<UnitInformationStorage>) -> String {
            String(attributed.format(value).characters)
        }

        public func locale(_ locale: Locale) -> Self {
            var new = self
            new.locale = locale
            return new
        }
    }
}


// MARK: - UnitUsage

// The raw values are for use with ICU's API. They should match CLDR's declaration at https://github.com/unicode-org/cldr/blob/master/common/supplemental/units.xml
internal enum Usage: String, Codable, Hashable {
    // common
    case general = "default"
    case person

    // energy
    case food

    // length
    case personHeight = "person-height"
    case road
    case focalLength = "focal-length"
    case rainfall
    case snowfall
    case visibility = "visiblty"

    // pressure
    case barometric = "baromtrc"

    // speed
    case wind

    // temperature
    case weather

    // volume
    case fluid

    // Foundation's flag: Do not convert to preferred unit
    case asProvided
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct MeasurementFormatUnitUsage<UnitType: Dimension> : Codable, Hashable, Sendable  {
    internal var usage: Usage = .general

    /// Default. No specific usage.
    public static var general: Self { .init(usage: .general) }

    /// Ignore the preferred unit by the locale and use the given unit.
    public static var asProvided: Self { .init(usage: .asProvided) }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension MeasurementFormatUnitUsage where UnitType == UnitTemperature {
    public static var weather: Self { .init(usage: .weather) }
    public static var person: Self { .init(usage: .person) }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension MeasurementFormatUnitUsage where UnitType == UnitLength {
    public static var person: Self { .init(usage: .person) }
    public static var road: Self { .init(usage: .road) }
    public static var personHeight: Self { .init(usage: .personHeight) }

    /// Describes the distance of visibility
    @available(macOS 14, iOS 16, tvOS 17, watchOS 9, *)
    public static var visibility: Self { .init(usage: .visibility) }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension MeasurementFormatUnitUsage where UnitType == UnitLength {

    /// Used to format the focal length of an optical system, such as that of camera lenses
    public static var focalLength: Self { .init(usage: .focalLength) }

    /// Used to format the rainfall amount
    public static var rainfall: Self { .init(usage: .rainfall) }

    /// Used to format the snowfall amount
    public static var snowfall: Self { .init(usage: .snowfall) }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension MeasurementFormatUnitUsage where UnitType == UnitEnergy {
    public static var food: Self { .init(usage: .food) }
    public static var workout: Self {
        // CLDR does not actually distinguish between food and workout usage.
        .init(usage: .food)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension MeasurementFormatUnitUsage where UnitType == UnitMass {
    public static var personWeight: Self { .init(usage: .person) }
}

extension MeasurementFormatUnitUsage where UnitType == UnitSpeed {
    /// Describes the unit for wind speed
    @available(macOS 14, iOS 16, tvOS 17, watchOS 9, *)
    public static var wind: Self { .init(usage: .wind) }
}

extension MeasurementFormatUnitUsage where UnitType == UnitPressure {
    /// Describes the unit for barometric pressure
    @available(macOS 14, iOS 16, tvOS 17, watchOS 9, *)
    public static var barometric: Self { .init(usage: .barometric) }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension MeasurementFormatUnitUsage where UnitType == UnitVolume {
    /// Used to format the amount of liquid
    public static var liquid: Self { .init(usage: .fluid) }
}

// MARK: - Measurement Extension
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension Measurement where UnitType: Dimension {
    func formatted<S: Foundation.FormatStyle>(_ style: S) -> S.FormatOutput where S.FormatInput == Self {
        style.format(self)
    }
    
    func formatted() -> String {
        self.formatted(Measurement.FormatStyle(width: .abbreviated, locale: .autoupdatingCurrent, usage: .general, numberFormatStyle: FloatingPointFormatStyle<Double>?.none))
    }
}

// MARK: - Dimension Extension

extension Dimension {
    var skeleton: String? {
        guard let type = type(of: self).icuType, let subType = icuSubtype else { return nil }
        return "measure-unit/\(type)-\(subType)"
    }
    
    // Different regions (countries) may have different preferences for the default unit. This variable returns if CLDR has data for the preferred default unit.
    @objc class var supportsRegionalPreference: Bool { false }
}

extension UnitArea {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitConcentrationMass {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitEnergy {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitFuelEfficiency {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitLength {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitMass {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitPower {
    override class var supportsRegionalPreference: Bool { true }
}


extension UnitPressure {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitSpeed {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitTemperature {
    override class var supportsRegionalPreference: Bool { true }
}

extension UnitVolume {
    override class var supportsRegionalPreference: Bool { true }
}

// MARK: -

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle {
    public static func measurement<UnitType>(width: Self.UnitWidth, usage: MeasurementFormatUnitUsage<UnitType> = .general, numberFormatStyle: FloatingPointFormatStyle<Double>? = nil) -> Self where Self == Measurement<UnitType>.FormatStyle {
        return Measurement<UnitType>.FormatStyle(width: width, usage: usage, numberFormatStyle: numberFormatStyle)
    }

    public static func measurement(width: Self.UnitWidth = .abbreviated, usage: MeasurementFormatUnitUsage<UnitTemperature> = .general, hidesScaleName: Bool = false, numberFormatStyle: FloatingPointFormatStyle<Double>? = nil) -> Self where Self == Measurement<UnitTemperature>.FormatStyle {
        return Measurement<UnitTemperature>.FormatStyle(width: width, usage: usage, hidesScaleName: hidesScaleName, numberFormatStyle: numberFormatStyle)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public extension FormatStyle where Self == Measurement<UnitInformationStorage>.FormatStyle.ByteCount {
    static func byteCount(style: Self.Style, allowedUnits: Self.Units = .all, spellsOutZero: Bool = true, includesActualByteCount: Bool = false) -> Self {
        Measurement<UnitInformationStorage>.FormatStyle.ByteCount(style: style, allowedUnits: allowedUnits, spellsOutZero: spellsOutZero, includesActualByteCount: includesActualByteCount, locale: .autoupdatingCurrent)
    }
}
