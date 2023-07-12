//
//  CanvasView.swift
//  HiraganaPractice
//
//  Created by 金子広樹 on 2023/07/07.
//

import SwiftUI

struct CanvasView: View {
    var setting = Setting()
    @Binding var selectedLevel: Int
    @Binding var isDoubleText: Bool
    @Binding var endedDrawPoints: [DrawPoints]
    // onChangedイベント中の座標を保持
    @State private var tmpDrawPoints: DrawPoints = DrawPoints(points: [])
    @State private var canvasLocalRect: CGRect = .zero              // canvasのサイズ情報
    let text: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .border(Color.black, width: setting.canvasBorderWidth)
                    .onAppear {
                        canvasLocalRect = geometry.frame(in: .local)
                    }
                ForEach(endedDrawPoints) { data in
                    Path { path in
                        path.addLines(data.points)
                    }
                    .stroke(.black, style: StrokeStyle(lineWidth: setting.lineWidth, lineCap: .round, lineJoin: .round))
                }
                
                // ドラッグ中の描画。指を離したらここの描画は消えるがDrawPathViewが上書きするので見た目は問題ない
                Path { path in
                    path.addLines(tmpDrawPoints.points)
                }
                .stroke(.black, style: StrokeStyle(lineWidth: setting.lineWidth, lineCap: .round, lineJoin: .round))
                
                // 点線
                WidthLine()
                    .stroke(style: .init(dash: [4, 3]))
                    .foregroundColor(.black)
                    .frame(height: 0.5)
                HeightLine()
                    .stroke(style: .init(dash: [4, 3]))
                    .foregroundColor(.black)
                    .frame(width: 0.5)
                
                // 表示文字。小さいひらがなの場合、文字を小さくする。そのほかの平仮名はそのまま表示。
                if text.contains("ゃ") || text.contains("ゅ") || text.contains("ょ") || text.contains("ぁ") || text.contains("ぃ") || text.contains("ぇ") || text.contains("ぉ") {
                    VStack {
                        HStack {
                            Spacer()
                            Text(text)
                                .font(.mincho(ofSize: 150))
                                .opacity(0.1)
                                .padding(.horizontal)
                        }
                        Spacer()
                    }
                } else {
                    Text(text)
                        .font(.mincho(ofSize: 250))
                        .opacity(0.1)
                }
                
                // 矢印
                switch selectedLevel {
                case 1:
                    HiraganaArrowView(hiragana: text)
                case 2:
                    HiraganaSonantArrowView(hiragana: text)
                case 3:
                    HiraganaDiphthongArrowView(hiragana: text)
                case 4:
                    HiraganaDiphthongSonantArrowView(hiragana: text)
                default:
                    HiraganaArrowView(hiragana: text)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        // 描いている途中（DrawPoints.pointsが空だったら）現在座標を加える
                        guard !tmpDrawPoints.points.isEmpty else {
                            tmpDrawPoints.points.append(value.location)
                            return
                        }

                        // 座標の距離が近いかどうかを判定
                        if let lastPoint = tmpDrawPoints.points.last,
                           filterDistance(startPoint: lastPoint, endPoint: value.location) {
                            tmpDrawPoints.points.append(value.location)
                        }
                    })
                    .onEnded({ value in
                        endedDrawPoints.append(tmpDrawPoints)
                        tmpDrawPoints = DrawPoints(points: [])
                    })
            )
        }
    }
    
    /// 座標の距離が近いかどうかを判定する。複数本の指をタップした場合もDragGestureはonChangedを呼ぶが、連続した線ではないのでフィルターをかける。
    /// - Parameters:
    ///   - startPoint: 開始座標
    ///   - endPoint: 終わりの座標
    /// - Returns: 距離が130以下且つ終わりの座標がcanvas内に含まれるならtrue、それ以外ならfalse
    private func filterDistance(startPoint: CGPoint, endPoint: CGPoint) -> Bool {
        let distance = sqrt(pow(Double(startPoint.x) - Double(endPoint.x), 2) + pow(Double(startPoint.y) - Double(endPoint.y), 2))
        return distance <= 130 && drawingRange(point: endPoint)
    }
    
    /// 指をタップしている座標がcanvas内であるかどうかを判定する。
    /// - Parameters:
    ///   - point: 終わりの座標
    /// - Returns: 終わりの座標がcanvas内に含まれるならtrue、それ以外ならfalse
    private func drawingRange(point: CGPoint) -> Bool {
        let minX = canvasLocalRect.minX + (setting.lineWidth / 2) + setting.canvasBorderWidth
        let maxX = canvasLocalRect.maxX - (setting.lineWidth / 2) + setting.canvasBorderWidth
        let minY = canvasLocalRect.minY + (setting.lineWidth / 2) + setting.canvasBorderWidth
        let maxY = canvasLocalRect.maxY - (setting.lineWidth / 2) + setting.canvasBorderWidth
        return (point.x >= minX && point.x <= maxX) && (point.y >= minY && point.y <= maxY)
    }
}

struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasView(selectedLevel: .constant(1), isDoubleText: .constant(false), endedDrawPoints: .constant([]), text: "あ")
    }
}