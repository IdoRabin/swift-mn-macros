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
import SwiftDiagnostics

public protocol SimplifiableEnum {
    var simplified : any Hashable { get }
}

// Will be used as: @attached(member)
// , ExtensionMacro
public struct SimplifiedEnum: MemberMacro {
    
    // MARK: static constants
    static let NO_ASSOCIATED_TYPES_STR = " -- has no associated type"

    // MARK: private funcs
    /// Creates a 'simplified' var for the declared enum, giving the ability to use myEnumValue.simplified to get the 'simplified' value for each / any of the cases
    /// - Parameters:
    ///   - allEnumCasesDecl: all enum case declerations (can be extracted by using EnumDeclSyntax.allEnumCaseDeclerations(viewMode:) helper function)
    ///   - maxCaseTextLength: the maximum text length of all the case names
    /// - Returns: array of DeclSyntaxtes to add to an attached expansion providing members to an Enum.
    fileprivate static func createSimplifiedVar(allEnumCasesDecl: [EnumCaseElementSyntax], maxCaseTextLength: Int) throws -> [DeclSyntax] {
        // Create a string representing the var declaration with a getter
        
        // tab hard codes the indentation.
        // NOTE: this is important when compating to an XCTest with multiline strings
        // See: assertMacroExpansion
        let tab = "    "
        var cases : [String] = []
        for acase in allEnumCasesDecl {
            let name = acase.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let commentSpacesCount = max(maxCaseTextLength - name.count, 0)
            let commentSpaces = String(repeating: " ", count: commentSpacesCount)

            // NOTE: SwiftSyntax automatically adds a newline ("block") after the colon.
            let assocTypeDesc : String = try acase.associatedType.namesDescription
            cases.append("\(tab)case .\(name):\nreturn Simplified.\(name)   \(commentSpaces) // \(assocTypeDesc)")
        }

        var lines = [
            "var simplified: Simplified {",
            "\(tab)switch self {"
        ]
        lines.append(contentsOf: cases)
        lines.append(contentsOf: [
            "\(tab)}",
            "}"
        ])
        
        let code = lines.joined(separator: "\n")

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
                    inheritanceClause: // Add protocol conformance/s
                    InheritanceClauseSyntax {
                        InheritedTypeListSyntax {
                            InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "Int"))
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

    fileprivate static func addConformance( to enumDecl: inout EnumDeclSyntax, newProtocols: [String]) {
        // Step 1: Get the existing inheritance clause (if any)
        var existingProtocols: Set<String> = []
        
        if let inheritanceClause = enumDecl.inheritanceClause {
            for element in inheritanceClause.inheritedTypes {
                if let protocolName = element.type.as(IdentifierTypeSyntax.self)?.name.text {
                    existingProtocols.insert(protocolName)
                }
            }
        }
        
        // Step 2: Add new protocols to the set, avoiding duplicates
        let newUniqueProtocols = newProtocols.filter { !existingProtocols.contains($0) }
        
        // If no new protocols to add, return the original enum declaration
        if newUniqueProtocols.isEmpty {
            return // No changes required
        }
        
        // Step 3: Build the new inheritance clause
        var inheritedTypeListSyntax = enumDecl.inheritanceClause?.inheritedTypes ?? InheritedTypeListSyntax([])

        for newUniqueProtocol in newUniqueProtocols {
            let newInheritedType = InheritedTypeSyntax(type: TypeSyntax(stringLiteral: newUniqueProtocol))
            inheritedTypeListSyntax.append(newInheritedType)
        }

        let newInheritanceClause = InheritanceClauseSyntax(inheritedTypes: inheritedTypeListSyntax)
        
        // Step 4: Return the modified EnumDeclSyntax with the new inheritance clause
        enumDecl.inheritanceClause = newInheritanceClause
    }
    
    // MARK: MemberMacro
    public static func expansion(of _: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo conformances: [TypeSyntax],
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        
        func diagnose(err:SimplifiedEnumErrors) throws {
            context.diagnose(err.asDiagnostic(node: Syntax(declaration)))
            // throw err
        }
        
        // Check decleration is an Enum
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // The macro can only be applied to enums
            try diagnose(err:SimplifiedEnumErrors.canOnlyImplementOnEnum)
            return []
        }
        
        // UNUSED: let enumName = enumDecl.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check cases have at least one associated value enum case:
        guard let allEnumCasesDecl = declaration.as(EnumDeclSyntax.self)?.allEnumCaseDeclerations(viewMode: .all) else {
            try diagnose(err:SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum)
            return []
        }
        
        if let internalEnum = enumDecl.memberBlock.members.first(where: { memberBlockItemSyntax in
            return memberBlockItemSyntax.decl.kind == .enumDecl
        })?.decl, let internalEnumDecl = internalEnum.as(EnumDeclSyntax.self) {
            if internalEnumDecl.name.text.trimmingCharacters(in: .whitespacesAndNewlines) == "Simplified" {
                // Already has an implemented sub-enum named 'Simplified'
                try diagnose(err: SimplifiedEnumErrors.alreadyHasSimplifiedImplementedInEnum)
                return []
            }
        }
        
        guard try allEnumCasesDecl.first(where: { enumCaseElementSyntax in
            try enumCaseElementSyntax.hasAssociatedType
        }) != nil else {
            // Guard failed - no associated type in any of the cases:
            try diagnose(err: SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum)
            return []
        }
        
        // UNUSED: let enumDeclOwner = allEnumCasesDecl.first?.ownerEnum
        // print("Expansion for Enum: \(enumName) Found case/s with associated type.")
        
        // For nice spacing of comments, we measure the length of the longest case name:
        let maxCaseTextLength = allEnumCasesDecl.reduce(0) { partialResult, enumCaseElementSyntax in
            max(partialResult, enumCaseElementSyntax.name.text.count)
        }
        
        // Add all needed members:
        var result: [DeclSyntax] = []
        try result.append(contentsOf: createSimplifiedEnum(allEnumCasesDecl: allEnumCasesDecl, maxCaseTextLength: maxCaseTextLength))
        try result.append(contentsOf: createSimplifiedVar(allEnumCasesDecl: allEnumCasesDecl, maxCaseTextLength: maxCaseTextLength))
        return result
        
        // NOTE:
        // If something fails during creation use
        // throw SimplifiedEnumErrors.failedCreatingSimplifiedEnum(enumDecl.name.trimmedDescription)
    }
    
    // MARK: ExtensionMacro
    /*
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

        // Check decleration is an Enum
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // The macro can only be applied to enums
            throw SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum
        }

        let enumName = enumDecl.name.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check cases have at least one associated value enum case:
        let allEnumCasesDecl = enumDecl.allEnumCaseDeclerations(viewMode: .all)
        guard try allEnumCasesDecl.first(where: { enumCaseElementSyntax in
            try enumCaseElementSyntax.hasAssociatedType
        }) != nil else {
            // Guard failed - no associated type in any of the cases:
            print("No cases with associated type were found in Enum: \(enumName)\n")
            throw SimplifiedEnumErrors.canOnlyImplementOnAssocValuedEnum
        }

        // For nice spacing of comments, we measure the length of the longest case name:
        let maxCaseTextLength = allEnumCasesDecl.reduce(0) { partialResult, enumCaseElementSyntax in
            max(partialResult, enumCaseElementSyntax.name.text.count)
        }

        let result = try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: "extension \(enumName) : SimplifiableEnum")) {
            try createSimplifiedVar(allEnumCasesDecl: allEnumCasesDecl, maxCaseTextLength: maxCaseTextLength)
        }
        return [result]
    }*/
}
