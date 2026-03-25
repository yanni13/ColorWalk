//
//  ColorWalkWidgetBundle.swift
//  ColorWalkWidget
//
//  Created by 아우신얀 on 3/25/26.
//

import WidgetKit
import SwiftUI

@main
struct ColorWalkWidgetBundle: WidgetBundle {
    var body: some Widget {
        ColorWalkWidget()
        ColorWalkWidgetControl()
        ColorWalkWidgetLiveActivity()
    }
}
