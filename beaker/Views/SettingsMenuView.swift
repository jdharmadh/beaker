//
//  SettingsMenuView.swift
//  beaker
//
//  Created by Jay Dharmadhikari on 7/6/25.
//
import SwiftUI

struct SettingsMenuView: View {
    @Binding var selectedMode: ModeType
    @State private var showMenu = false

    var body: some View {
        VStack {
            Button(action: {
                if selectedMode != .none {
                    showMenu.toggle()
                } else {
                    selectedMode = .chat
                }
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showMenu, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Command") {
                        selectedMode = .command
                        showMenu = false
                    }
                    Button("Chat") {
                        selectedMode = .chat
                        showMenu = false
                    }
                    Button("Done") {
                        selectedMode = .none
                        showMenu = false
                    }
                }
                .padding()
                .frame(width: 120)
            }
        }
    }
}
