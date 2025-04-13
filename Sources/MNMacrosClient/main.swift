#if canImport(MNMacrosMacros)
//    import MNMacrosMacros
//
//
//    @SimplifiedEnum
//    enum MyTestEnum {
//        case first(Int)
//        case second(String)
//        case third
//    }

    // Expected: "[first, second, third] "
    // print("The values \(MyTestEnum.Simplified.allCases) are the simplified cases of: \(MyTestEnum)")
#endif
