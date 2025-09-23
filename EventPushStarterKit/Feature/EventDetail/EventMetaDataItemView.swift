//
//  EventMetaDataItemView.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//

import SwiftUI

struct EventMetaDataItemView: View {
    let imageName: String
    let title: String
    let suntitle: String
    
    var body: some View {
        VStack {
            HStack(spacing: 4) {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.system(size: 12))
            }
            Text(suntitle)
        }

    }
}
