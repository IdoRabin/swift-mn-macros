import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MNMacrosMacros)
import MNMacrosMacros

let testSimplifyEnumMacros: [String: Macro.Type] = [
    "SimplifiedEnum": SimplifiedEnum.self,
]
#endif

struct TestStructExample {
    let name : String
    let other : String
}

final class SimplifiedEnumMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(MNMacrosMacros)
        assertMacroExpansion("""
            @SimplifiedEnum
            enum MyEnum {
                case one(String)
                case two(Int)
                case three(TestStructExample)
                case four
            }
            """,
            expandedSource: """
            enum MyEnum {
                case one(String)
                case two(Int)
                case three(TestStructExample)
                case four
            
                enum Simplified: CaseIterable, Hashable {
                    case one   // String
                    case two   // Int
                    case three // TestStructExample
                    case four  //  -- has no associated type
                }
            
                var simplified: Simplified {
                    switch self {
                    case one:
                        return Simplified.one      // Stringֿ
                    case two:
                        return Simplified.two      // Intֿ
                    case three:
                        return Simplified.three    // TestStructExampleֿ
                    case four:
                        return Simplified.four     //  -- has no associated typeֿ
                    }
                }
            }
            """,
            macros: testSimplifyEnumMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacroWithoutAssocTypes() {
        #if canImport(MNMacrosMacros)
        assertMacroExpansion("""
        @SimplifiedEnum
        enum MyEnum {
            case one
            case two
            case three
            case four
        }
        """,
       expandedSource: """
        enum MyEnum {
            case one
            case two
            case three
            case four
        }
        """,
        diagnostics: [
            DiagnosticSpec(message: "SimplifiedEnum macro can only be applied to an Enum decleration that has at least one case with an associated value.",
                           line: 1,
                           column: 1,
                           severity: .error,
                           highlight: nil,
                           notes: [],
                           fixIts: [],
                           originatorFile: "",
                           originatorLine: 1)
                     ],
        macros: testSimplifyEnumMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
