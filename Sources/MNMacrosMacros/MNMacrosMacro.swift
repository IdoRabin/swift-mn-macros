import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MNMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SimplifiedEnum.self,
    ]
}
