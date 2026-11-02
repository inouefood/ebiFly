// Rasterizes SVG files to PNG with WebKit (faithful <symbol>/<use>/clipPath support).
// usage: swift render.swift jobs.txt
// jobs.txt lines: <svgPath>\t<pngPath>\t<pixelWidth>\t<pixelHeight>
import AppKit
import WebKit

final class Renderer: NSObject, WKNavigationDelegate {
    let jobs: [(String, String, Int, Int)]
    var index = 0
    let window: NSWindow
    let web: WKWebView

    init(jobs: [(String, String, Int, Int)]) {
        self.jobs = jobs
        window = NSWindow(contentRect: .init(x: 0, y: 0, width: 1024, height: 1024), styleMask: [.borderless], backing: .buffered, defer: false)
        web = WKWebView(frame: .init(x: 0, y: 0, width: 1024, height: 1024))
        super.init()
        web.setValue(false, forKey: "drawsBackground")
        web.navigationDelegate = self
        window.contentView = web
    }

    func next() {
        guard index < jobs.count else { exit(0) }
        let (svg, _, w, h) = jobs[index]
        web.setFrameSize(.init(width: w, height: h))
        let svgURL = URL(fileURLWithPath: svg)
        let html = "<html><body style=\"margin:0;background:transparent\"><img src=\"\(svgURL.lastPathComponent)\" style=\"display:block;width:\(w)px;height:\(h)px\"></body></html>"
        let htmlURL = svgURL.deletingLastPathComponent().appendingPathComponent("_render.html")
        try! html.write(to: htmlURL, atomically: true, encoding: .utf8)
        web.loadFileURL(htmlURL, allowingReadAccessTo: svgURL.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let (_, out, w, h) = jobs[index]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let cfg = WKSnapshotConfiguration()
            cfg.rect = .init(x: 0, y: 0, width: w, height: h)
            cfg.snapshotWidth = NSNumber(value: w)
            webView.takeSnapshot(with: cfg) { image, error in
                guard let image else { fatalError("snapshot failed: \(String(describing: error))") }
                let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                                           hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                rep.size = .init(width: w, height: h)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
                NSColor.clear.set()
                NSRect(x: 0, y: 0, width: w, height: h).fill()
                image.draw(in: .init(x: 0, y: 0, width: w, height: h))
                NSGraphicsContext.restoreGraphicsState()
                try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
                print("rendered \(out)")
                self.index += 1
                self.next()
            }
        }
    }
}

let lines = try! String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8).split(separator: "\n")
let jobs = lines.map { l -> (String, String, Int, Int) in
    let p = l.split(separator: "\t").map(String.init)
    return (p[0], p[1], Int(p[2])!, Int(p[3])!)
}
let app = NSApplication.shared
let renderer = Renderer(jobs: jobs)
renderer.next()
app.run()
