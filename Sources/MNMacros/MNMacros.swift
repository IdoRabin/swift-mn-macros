// MNMacros.swift

/// SimplifiedEnum Macro:
/// A macro that adds to an enum with at least on associated value a sub-enum named "Simplified" that is equatable,
/// with helper methods to compare and convert between the Simplified and the fully-qualified enum.
///
///    @simplified
///    enum MyEnum {
///        case one(String)
///        case two(int)
///        case three
///    }
///
/// expands to a decleration of an enum named "Simplified" *inside* the target enum we are attaching to:
///
///    enum MyEnum {
///        case one(String)
///        case two(int)
///        case three
///
///        // MARK: Simplified macro
///        enum Simplified : CaseIterable, Equatable {
///            case one // NOTE: no associated type
///            case two // NOTE: no associated type
///            case three
///        }
///
///        // MARK: Simplified macro
///        /// Genrated by the SimplifiedEnumMacro
///        var simplified : Simplified {
///            switch self {
///            case one:  return Simplified.one
///            case two:  return Simplified.two
///            case three: return Simplified.three
///        }
///
///        /// Checks for equality between the "simplified" values of self and another value, both of the MyEnum type.
///        func isEqualsSimplified(_ other: Self) -> Bool {
///            return self.simplified != other.simplified
///        }
///
///        /// Checks for equality between the "simplified" values of any two values of the MyEnum type.
///        static func ~=(_ first: MyEnum,_ second: MyEnum)->Bool {
///            return first.isEqualsSimplified(second)
///        }
///    }
/// }
///
///
@attached(member)
public macro SimplifiedEnum() = #externalMacro(module: "MNMacrosMacros", type: "SimplifiedEnumMacro") // ?? Macro suffix or not?
