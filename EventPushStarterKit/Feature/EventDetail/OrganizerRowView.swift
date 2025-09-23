//
//  OrganizerRowView.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//

import SwiftUI

struct OrganizerRowView: View {
    var body: some View {
        HStack {
            Image("event-sample2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .clipShape(.circle)
            VStack(alignment: .leading) {
                Text("title")
                Text("suntitle")
                
            }
        }
    }
}


