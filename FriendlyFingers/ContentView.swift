//
//  ContentView.swift
//  FriendlyFingers
//
//  Created by Daniel Aditya Istyana on 22/12/23.
//

import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var point: [RectPosition] = []
    @State private var localFrame: CGRect = .zero
    
    var body: some View {
        VStack {
            if let _image = self.image {
                Image(uiImage: _image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300)
                    .frame(height: 400)
                    .overlay {
                        GeometryReader(content: { geometry in
                            ZStack {
                                
                                Rectangle()
                                    .foregroundColor(.yellow.opacity(0.2))
                                
                                let frame = geometry.frame(in: .local)
                                ForEach(point) { point in
                                    Rectangle()
                                        .foregroundColor(.yellow)
                                        .frame(width: 20, height: 20)
                                        .border(.pink, width: 1)
                                        .overlay {
                                            Text(point.name)
                                                .font(.caption)
                                        }
                                        .position(x: point.point.x, y: point.point.y)
                                    
                                }
                                
                            }
                            
                            
                        })
                    }
                
                
            } else {
                PhotosPicker(selection: $selectedPhoto) {
                    Label {
                        Text("Select a photo")
                    } icon: {
                        Image(systemName: "photo")
                    }
                    
                }
            }
        }
        .padding()
        .onChange(of: self.selectedPhoto) { oldValue, newValue in
            if let item = newValue {
                item.loadTransferable(type: Data.self) { res in
                    switch res {
                    case let .success(data):
                        guard let d = data else { return }
                        self.image = UIImage(data: d)
                    case let .failure(err):
                        print(err.localizedDescription)
                    }
                }
            }
        }
        .onChange(of: self.image) { oldValue, newValue in
            if let img = newValue, let cgImage = img.cgImage {
                let handler = VNImageRequestHandler(cgImage: cgImage)
                do {
                    try handler.perform([self.handPoseRequest])
                    
                    guard let results = handPoseRequest.results else { return }
                    self.processObservation(observation: results.first!, width: cgImage.width, height: cgImage.height)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func processObservation(observation: VNHumanHandPoseObservation, width: Int, height: Int) {
        if let indexFinger = try? observation.recognizedPoints(.indexFinger),
           let tip = indexFinger[.indexTip], let dip = indexFinger[.indexDIP], let pip = indexFinger[.indexPIP], let mcp = indexFinger[.indexMCP] {
            
            print("tip: ", tip.location)
            print("dip: ", dip.location)
            print("pip: ", pip.location)
            print("mcp: ", mcp.location)
            let normalized = VNNormalizedPointForImagePoint(.zero, width, height)
            print(normalized)
            
            self.point.append(contentsOf: [
                RectPosition(name: "mcp", point: CGPoint(x: 1 - mcp.location.x, y: mcp.location.y)),
                RectPosition(name: "dip", point: CGPoint(x: 1 - dip.location.x, y: dip.location.y)),
                RectPosition(name: "tip", point: CGPoint(x: 1 - tip.location.x, y: tip  .location.y)),
                RectPosition(name: "pip", point: CGPoint(x: 1 - pip.location.x, y: pip.location.y)),
            ])
        }
    }
}

#Preview {
    ContentView()
}

struct RectPosition: Identifiable {
    var name: String
    var point: CGPoint
    
    var id: String {
        self.name
    }
}
