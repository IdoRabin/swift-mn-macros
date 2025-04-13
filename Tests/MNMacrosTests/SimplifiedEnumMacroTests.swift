import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MNMacrosMacros)
    import MNMacrosMacros

    let testSimplifyEnumMacros: [String: Macro.Type] = [
        "SimplifiedEnum": SimplifiedEnum.self,
    ]
#endif

struct TestStructExample {
    let name: String
    let other: String
}

final class SimplifiedEnumMacroTests: XCTestCase {
    
    func testAAMacroOnNonEnum() {
        #if canImport(MNMacrosMacros)
        // UNUSED: let err = SimplifiedEnumErrors.canOnlyImplementOnEnum
        let expectedDiagnostic = DiagnosticSpec(message: "SimplifiedEnum macro can only be applied to an Enum. (NOTE: the enum decleration must have has at least one case with an associated value.)",
                                                line: 1,
                                                column: 1,
                                                severity: .error,
                                                highlights: nil,
                                                // notes: [],
                                                // fixIts: []
                                                originatorFile: "",
                                                originatorLine: 1)
        assertMacroExpansion(
                             """
                                 @SimplifiedEnum
                                 struct MNTestStruct {
                                    var x: Int
                                    let y: String
                                 }
                             """,
             expandedSource: """
                                 struct MNTestStruct {
                                    var x: Int
                                    let y: String
                                 }
                             """,
             diagnostics: [expectedDiagnostic],
             macros: testSimplifyEnumMacros)
        #endif
    }
    
    func testAMacroWithExistingSimplified() {
        #if canImport(MNMacrosMacros)
        let expectedDiagnostic = DiagnosticSpec(message: "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" was already declared",
                                                line: 1,
                                                column: 1,
                                                severity: .error,
                                                highlights: nil,
                                                notes: [],
                                                fixIts: [],
                                                originatorFile: "",
                                                originatorLine: 1)
        assertMacroExpansion(
                             """
                                 @SimplifiedEnum
                                 enum MNTestFncEnum {
                                    case one(Int)
                                    case two(String)
                                    
                                    enum Simplified {
                                      case one
                                      case other
                                    }
                                 }
                             """,
             expandedSource: """
                                 enum MNTestFncEnum {
                                    case one(Int)
                                    case two(String)
                                    
                                    enum Simplified {
                                      case one
                                      case other
                                    }
                                 }
                             """,
             diagnostics: [expectedDiagnostic],
             macros: testSimplifyEnumMacros)
        #endif
    }
    
    
    func testAMacroWithAssocFunc() {
        #if canImport(MNMacrosMacros)
            assertMacroExpansion(
                                 """
                                 typealias MyFunc = (Int, String)->Bool
                                 @SimplifiedEnum
                                 enum MNTestFncEnum {
                                     case noSorting(MyFunc)
                                     case custom((any CustomStringConvertible, any Comparable)->Bool)
                                     case byChildrenCount(Int)
                                     case byIDHashess
                                     case byComperableIDs
                                     case byComperableValues
                                 }
                                 """,
            expandedSource:      """
                                 typealias MyFunc = (Int, String)->Bool
                                 enum MNTestFncEnum {
                                     case noSorting(MyFunc)
                                     case custom((any CustomStringConvertible, any Comparable)->Bool)
                                     case byChildrenCount(Int)
                                     case byIDHashess
                                     case byComperableIDs
                                     case byComperableValues

                                     enum Simplified: Int, CaseIterable, Hashable {
                                         case noSorting          // MyFunc
                                         case custom             // Anonymous_Func_0
                                         case byChildrenCount    // Int
                                         case byIDHashess        //  -- has no associated type
                                         case byComperableIDs    //  -- has no associated type
                                         case byComperableValues //  -- has no associated type
                                     }

                                     var simplified: Simplified {
                                         switch self {
                                         case .noSorting:
                                             return Simplified.noSorting             // MyFunc
                                         case .custom:
                                             return Simplified.custom                // Anonymous_Func_0
                                         case .byChildrenCount:
                                             return Simplified.byChildrenCount       // Int
                                         case .byIDHashess:
                                             return Simplified.byIDHashess           //  -- has no associated type
                                         case .byComperableIDs:
                                             return Simplified.byComperableIDs       //  -- has no associated type
                                         case .byComperableValues:
                                             return Simplified.byComperableValues    //  -- has no associated type
                                         }
                                     }
                                 }
                                 """,
                                macros: testSimplifyEnumMacros)
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

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
                                 expandedSource:
                                 """
                                 enum MyEnum {
                                     case one(String)
                                     case two(Int)
                                     case three(TestStructExample)
                                     case four

                                     enum Simplified: Int, CaseIterable, Hashable {
                                         case one   // String
                                         case two   // Int
                                         case three // TestStructExample
                                         case four  //  -- has no associated type
                                     }

                                     var simplified: Simplified {
                                         switch self {
                                         case .one:
                                             return Simplified.one      // String
                                         case .two:
                                             return Simplified.two      // Int
                                         case .three:
                                             return Simplified.three    // TestStructExample
                                         case .four:
                                             return Simplified.four     //  -- has no associated type
                                         }
                                     }
                                 }
                                 """,
                                 macros: testSimplifyEnumMacros)
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithoutAssocTypes() {
        #if canImport(MNMacrosMacros)
            let expectedDiagnostic = DiagnosticSpec(message: "SimplifiedEnum macro can only be applied to an Enum decleration that has at least one case with an associated value.",
                                                    line: 1,
                                                    column: 1,
                                                    severity: .error,
                                                    highlights: nil,
                                                    notes: [],
                                                    fixIts: [],
                                                    originatorFile: "",
                                                    originatorLine: 1)

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
                                 diagnostics: [expectedDiagnostic],
                                 macros: testSimplifyEnumMacros)
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
}
