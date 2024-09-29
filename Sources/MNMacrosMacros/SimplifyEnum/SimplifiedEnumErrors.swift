//
//  SimplifiedEnumErrors.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

public enum SimplifiedEnumErrors : CustomStringConvertible, Error {
    
    case canOnlyImplementOnEnum
    case canOnlyImplementOnAssocValuedEnum
    case alreadyHasSimplifiedImplementedInEnum
    case hasMultipleAssocValueTypesInCase(String)
    case caseHasNoClearCaseName(String)
    case failedCreatingSimplifiedEnum(String)
    
    public var description: String {
        switch self {
        case .canOnlyImplementOnEnum:
            return "SimplifiedEnum macro can only be applied to an Enum. (NOTE: the enum decleration must have has at least one case with an associated value.)"
        case .canOnlyImplementOnAssocValuedEnum:
            return "SimplifiedEnum macro can only be applied to an Enum decleration that has at least one case with an associated value."
        case .alreadyHasSimplifiedImplementedInEnum:
            return "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" was already declared."
        case .hasMultipleAssocValueTypesInCase(let name):
            return "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" has multiple associated type parameters in decleration of case \(name)."
        case .caseHasNoClearCaseName(let text):
            return "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" has no clear case name for associated types: \(text)."
        case .failedCreatingSimplifiedEnum(let name):
            return "SimplifiedEnum macro failed creating a simplified sub-enum for: \(name)"
        }
    }
}

