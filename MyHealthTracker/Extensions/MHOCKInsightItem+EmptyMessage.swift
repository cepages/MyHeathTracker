//
//  MHOCKInsightItem+EmptyMessage.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import CareKit

extension OCKInsightItem {
    /// Returns an `OCKInsightItem` to show when no insights have been calculated.
    static func emptyInsightsMessage() -> OCKInsightItem {
        return OCKMessageItem(title: "No Insights", text: "There are no insights to show.", tintColor: UIColor.green, messageType: .tip)
    }
}
