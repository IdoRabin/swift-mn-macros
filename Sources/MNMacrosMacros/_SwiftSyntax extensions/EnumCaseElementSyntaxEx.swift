//
//  EnumCaseElementSyntaxEx.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension EnumCaseElementSyntax {
    var ownerEnum: Optional<EnumCaseDeclSyntax> {
        do {
            if let enumCaseDeclItem = try firstRecursiveParent(where: { item, _ in
                item.kind == .enumCaseDecl
            }) {
                // Found firstRecursiveParent of kind enumCaseDecl
                // (expected to conform to EnumCaseDeclSyntax)
                return enumCaseDeclItem.as(EnumCaseDeclSyntax.self)
            }
        } catch {
            print("EnumCaseElementSyntax.ownerEnum error in firstRecursiveParent: \(error)")
        }

        return nil
    }

    /// Will return an array of IdentifierTypeSyntax describing all the param ids of the associated type(s)
    /// Has no associated type when retsult is an empty array
    /// Expected one id in most cases of an associated type (for a stregight-up classic decleration syntax)
    var associatedType: [IdentifierTypeSyntax] {
        get throws {
            // The case children should contain at least one child - the case type name (token)
            // Optionally, the case children may contain  enumCaseParameterClause with the associated type ids:

            let children = self.children(viewMode: .all)
            var result: [String: [IdentifierTypeSyntax]] = [:]
            var foundToken = false
            for child in children {
                switch child.kind {
                case .enumCaseParameterClause:
                    // We have a parameter in the case decleration syntax:
                    // i.e for myCase(AnExampleAssocType) the param is "(AnExampleAssocType)"
                    // associatedType validates the type syntax is valid leftParantheses + (param.type.kind == .identifierType) + valid rightParanthese
                    if let associatedTypeIds = child.as(EnumCaseParameterClauseSyntax.self)?.associatedTypeIds,
                       !associatedTypeIds.isEmpty
                    {
                        // We have left and right parantheses and at least one identifier value:
                        result[name.text.trimmingCharacters(in: .whitespacesAndNewlines) + child.description.trimmingCharacters(in: .newlines)] = associatedTypeIds
                    }
                case .token:
                    foundToken = true
                default:
                    break
                }
            }

            // After looping, we make sure result has one list of associated type identifiers and one found token (name) for the declared case:
            switch result.count {
            case 0:
                // print("  an EnumCaseElement: [\(self.name)] foundToken: \(foundToken) NO ASSOC TYPE")
                return []
            case 1:
                // 1. We have one found token (name) for the declared case
                // 2. result has one list of associated type identifiers (no less, no more)
                // 3. list of associated type identifiers is not empty
                if foundToken == true, let ids = result.values.first, !ids.isEmpty {
                    // print("  an EnumCaseElement: [\(self.name)] foundToken: \(foundToken) foundPrams: (\(result.count)) \(ids.descriptions.description)")
                    return ids
                } else {
                    throw SimplifiedEnumErrors.caseHasNoClearCaseName(result.description)
                }
            default:
                // NOT Supposed to happen: we have found a case that has more than one array of associated types (!?)
                throw SimplifiedEnumErrors.hasMultipleAssocValueTypesInCase("case .\(name.text.trimmingCharacters(in: .whitespacesAndNewlines)): " + result.description)
            }
        }
    }

    var hasAssociatedType: Bool {
        get throws {
            return try !associatedType.isEmpty
        }
    }
}

public extension EnumCaseDeclSyntax {
    func enumCaseElementSyntax() -> EnumCaseElementSyntax? {
        return elements.first //?.as(EnumCaseElementSyntax.self)
    }
//    var name : String? {
//
//    }
}

