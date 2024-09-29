//
//  SimplifiedEnum.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// Will be used as: @attached(member)
public struct SimplifiedEnum: MemberMacro {
    static let NO_ASSOCIATED_TYPES_STR = " -- has no associated type"

    /// Creates a 'simplified' var for the declared enum, giving the ability to use myEnumValue.simplified to get the 'simplified' value for each / any of the cases
    /// - Parameters:
    ///   - allEnumCasesDecl: all enum case declerations (can be extracted by using EnumDeclSyntax.allEnumCaseDeclerations(viewMode:) helper function)
    ///   - maxCaseTextLength: the maximum text length of all the case names
    /// - Returns: array of DeclSyntaxtes to add to an attached expansion providing members to an Enum.
    fileprivate static func createSimplifiedVar(allEnumCasesDecl: [EnumCaseElementSyntax], maxCaseTextLength: Int) throws -> [DeclSyntax] {
        // Create a string representing the var declaration with a getter
        var cases = ""
        for acase in allEnumCasesDecl {
            let name = acase.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let commentSpacesCount = max(maxCaseTextLength - name.count, 0)
            let commentSpaces = String(repeating: " ", count: commentSpacesCount)

            // NOTE: SwiftSyntax automatically adds a newline ("block") after the colon.
            let newLine = (acase != allEnumCasesDecl.last) ? "\n" : ""
            try cases += "case \(name): return Simplified.\(name)   \(commentSpaces) // \(acase.associatedType.namesDescription)ֿ\(newLine)"
        }

        let code = """
        var simplified: Simplified {
            switch self {
            \(cases)
            }
        }
        """

        // Parse the string into SwiftSyntax nodes
        return [DeclSyntax(stringLiteral: code)]
    }

    /// Add a 'Simplified" enum as a sub-enum to an Enum that has at least one case with an associated value
    /// - Parameters:
    ///   - allEnumCasesDecl: all enum case declerations (can be extracted by using EnumDeclSyntax.allEnumCaseDeclerations(viewMode:) helper function)
    ///   - maxCaseTextLength: the maximum text length of all the case names
    /// - Returns: array of DeclSyntaxtes to add to an attached expansion providing members to an Enum.
    fileprivate static func createSimplifiedEnum(allEnumCasesDecl: [EnumCaseElementSyntax], maxCaseTextLength: Int) throws -> [DeclSyntax] {
        return try [
            DeclSyntax(
                // Create the Simplified enum declaration as a sub-Enum
                EnumDeclSyntax(
                    name: "Simplified",
                    inheritanceClause: // Add protocol conformane/s
                    InheritanceClauseSyntax {
                        InheritedTypeListSyntax {
                            InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "CaseIterable"))
                            InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "Hashable"))
                        }
                    }
                ) {
                    // Adds the cases to the sub enum, each case in a line of its own
                    try MemberBlockItemListSyntax {
                        // Create cases
                        for acase in allEnumCasesDecl {
                            // Each MemberBlockItemSyntax contains an EnumCaseDeclSyntax (in a line of its own)
                            let commentSpacesCount = maxCaseTextLength - acase.name.text.count
                            let commentSpaces = String(repeating: " ", count: commentSpacesCount)
                            try MemberBlockItemSyntax(
                                decl: EnumCaseDeclSyntax(elements: EnumCaseElementListSyntax([EnumCaseElementSyntax(name: acase.name)]),
                                                         trailingTrivia: Trivia.lineComment(" \(commentSpaces)// \(acase.associatedType.namesDescription)"))
                            )
                        }
                    }
                }
            ), // DeclSyntax Ends here
        ]
    }

    public static func expansion(of _: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo _: [TypeSyntax],
                                 in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        // Check decleration is an Enum
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // The macro can only be applied to enums
            throw SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum
        }

        let enumName = enumDecl.name.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check cases have at least one associated value enum case:
        guard let allEnumCasesDecl = declaration.as(EnumDeclSyntax.self)?.allEnumCaseDeclerations(viewMode: .all) else {
            throw SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum
        }

        guard try allEnumCasesDecl.first(where: { enumCaseElementSyntax in
            try enumCaseElementSyntax.hasAssociatedType
        }) != nil else {
            // Guard failed - no associated type in any of the cases:
            print("No cases with associated type were found in Enum: \(enumName)\n")
            throw SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum
        }

        // let enumDeclOwner = allEnumCasesDecl.first?.ownerEnum
        print("Expansion for Enum: \(enumName) Found case/s with associated type.")

        // For nice spacing of comments, we measure the length of the longest case name:
        let maxCaseTextLength = allEnumCasesDecl.reduce(0) { partialResult, enumCaseElementSyntax in
            max(partialResult, enumCaseElementSyntax.name.text.count)
        }

        // Add all needed members:
        var result: [DeclSyntax] = try createSimplifiedEnum(allEnumCasesDecl: allEnumCasesDecl, maxCaseTextLength: maxCaseTextLength)
        try result.append(contentsOf: createSimplifiedVar(allEnumCasesDecl: allEnumCasesDecl, maxCaseTextLength: maxCaseTextLength))

        return result
        // NOTE:
        // If something fails during creation use
        // throw SimplifiedEnumErrors.failedCreatingSimplifiedEnum(enumDecl.name.trimmedDescription)

        /*
         // === declaration is expected to contain: ==
         ─[0]: AttributeSyntax
         │   ├─atSign: atSign
         │   ╰─attributeName: IdentifierTypeSyntax
         │     ╰─name: identifier("simplifyEnum")

          // === memberBlock is expected to contain: ==
         ├─members: MemberBlockItemListSyntax
         │ ├─[0]: MemberBlockItemSyntax
         │ │ ╰─decl: EnumCaseDeclSyntax
         │ │   ├─attributes: AttributeListSyntax
         │ │   ├─modifiers: DeclModifierListSyntax
         │ │   ├─caseKeyword: keyword(SwiftSyntax.Keyword.case)
         │ │   ╰─elements: EnumCaseElementListSyntax
         │ │     ╰─[0]: EnumCaseElementSyntax
         │ │       ├─name: identifier("one")
         │ │       ╰─parameterClause: EnumCaseParameterClauseSyntax
         │ │         ├─leftParen: leftParen
         │ │         ├─parameters: EnumCaseParameterListSyntax // <--- here is the indication this is an associated type enum case
         │ │         │ ╰─[0]: EnumCaseParameterSyntax
         │ │         │   ├─modifiers: DeclModifierListSyntax
         │ │         │   ╰─type: IdentifierTypeSyntax
         │ │         │     ╰─name: identifier("String")
         │ │         ╰─rightParen: rightParen
         │ ├─...
          */
    }
}
