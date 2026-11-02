// Renders an HTML page to an image of an exact pixel size with WebKit (1 CSS px = 1 image px).
// usage: swift pageshot.swift page.html out.png width height [wait-seconds]
import AppKit
import WebKit

let args = CommandLine.arguments
let url = URL(fileURLWithPath: args[1])
let out = args[2]
let width = Int(args[3])!
let height = Int(args[4])!
let wait = args.count > 5 ? Double(args[5])! : 1.5

final class Delegate: NSObject, WKNavigationDelegate {
    func webView(_ view: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            let config = WKSnapshotConfiguration()
            config.rect = .init(x: 0, y: 0, width: width, height: height)
            // snapshotWidth is in points; divide by the screen scale so the image comes out at exactly `width` pixels
            config.snapshotWidth = NSNumber(value: Double(width) / (NSScreen.main?.backingScaleFactor ?? 1))
            view.takeSnapshot(with: config) { image, error in
                guard let image, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else {
                    fatalError("snapshot failed: \(String(describing: error))")
                }
                try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
                print("rendered \(out)")
                exit(0)
            }
        }
    }
}

let window = NSWindow(contentRect: .init(x: 0, y: 0, width: width, height: height), styleMask: [.borderless], backing: .buffered, defer: false)
let web = WKWebView(frame: .init(x: 0, y: 0, width: width, height: height))
window.contentView = web
let delegate = Delegate()
web.navigationDelegate = delegate
// the page pulls fonts, captures and app artwork from elsewhere in the repo
web.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: "/"))
RunLoop.main.run()
