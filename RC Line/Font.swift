import SwiftUI
import UIKit

func registerCustomFont(fontName: String, fileName: String, extension: String = "ttf") {
    guard let fontURL = Bundle.main.url(forResource: fileName, withExtension: `extension`) else {
        print("フォントファイルが見つからない: \(fileName).\(`extension`)")
        return
    }
    
    var error: Unmanaged<CFError>?
    let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    
    if success {
        print("フォント登録成功: \(fontName)")
    } else {
        print("フォント登録失敗: \(error?.takeRetainedValue().localizedDescription ?? "不明")")
    }
}

extension Font {
    static func custom(_ name: String, size: CGFloat) -> Font {
        if let uiFont = UIFont(name: name, size: size) {
            return Font(uiFont)
        } else {
            print("UIFont が見つからない: \(name)")
            return Font.system(size: size)
        }
    }
}
