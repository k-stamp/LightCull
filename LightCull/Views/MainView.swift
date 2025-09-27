//
//  ContentView.swift
//  LightCull
//
//  Created by Kevin Stamp on 23.09.25.
//

import SwiftUI

struct MainView: View {
    @State private var pairs: [ImagePair] = []  // Ergebnisliste
    @State private var folderURL: URL?  // Merkt sich den gewählten Ordner
    
    private let fileService = FileService() // unser Service
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR (links)
            sidebarContent
        } content: {
            // CONTENT AREA (mitte)
            contentArea
        } detail: {
            // DETAIL Area
            detailArea
        }
    }
    
    // MARK: Sidebar Content
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LightCull")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Ordner")
                    .font(.headline)
                    .padding(.horizontal)
                
                Button("Ordner auswählen") {
                    selectFolder()
                }
                .padding(.horizontal)
                
                if let folderURL {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gewählter Ordner:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(folderURL.lastPathComponent)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                }
            }
            
            Divider()
            
            // Info-Bereich
            VStack(alignment: .leading, spacing: 8) {
                Text("Info")
                    .font(.headline)
                    .padding(.horizontal)
                
                if pairs.isEmpty {
                    Text("Keine Bildpaare gefunden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    Text("Paare: \(pairs.count)")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
            
            
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }
    
    
    // MARK: Content Area
    private var contentArea: some View {
        VStack {
            Text("Bildvorschau")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    
    // MARK: Detail Area
    private var detailArea: some View {
        VStack {
            Text("Detail")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    
    // MARK: Helper Methods
    
    // Öffnet den macOS Dialog zur Ordnerwahl
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            folderURL = url
            pairs = fileService.findImagePairs(in: url)
        }
    }
}

#Preview {
    MainView()
}
