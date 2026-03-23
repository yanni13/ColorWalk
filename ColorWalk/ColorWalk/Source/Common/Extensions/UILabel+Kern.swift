//
//  UILabel+Kern.swift
//  ColorWalk
//

import UIKit

extension UILabel {
    /// 텍스트에 자간(letter-spacing)을 적용
    func setKern(_ value: CGFloat) {
        guard let text else { return }
        let attr = NSMutableAttributedString(string: text)
        attr.addAttribute(.kern, value: value, range: NSRange(location: 0, length: text.count))
        attributedText = attr
    }
}
