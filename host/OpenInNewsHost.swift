// Chrome native messaging host: opens a web URL via News.app's "Open in News" share extension.
import AppKit

struct Request: Decodable { let url: String }
struct Response: Encodable { let ok: Bool; let error: String? }

func respond(_ response: Response) -> Never {
    let body = (try? JSONEncoder().encode(response)) ?? Data(#"{"ok":false}"#.utf8)
    var length = UInt32(body.count)
    FileHandle.standardOutput.write(Data(bytes: &length, count: 4) + body)
    exit(response.ok ? 0 : 1)
}

func fail(_ message: String) -> Never { respond(Response(ok: false, error: message)) }

func readRequest() -> Request {
    let input = FileHandle.standardInput
    let header = input.readData(ofLength: 4)
    guard header.count == 4 else { fail("missing message header") }
    let length = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
    let body = input.readData(ofLength: Int(length))
    guard body.count == Int(length), let request = try? JSONDecoder().decode(Request.self, from: body) else { fail("invalid message") }
    return request
}

final class Delegate: NSObject, NSSharingServiceDelegate {
    func sharingService(_ service: NSSharingService, didShareItems items: [Any]) {
        respond(Response(ok: true, error: nil))
    }
    func sharingService(_ service: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        fail(error.localizedDescription)
    }
}

let request = readRequest()
guard let url = URL(string: request.url), ["http", "https"].contains(url.scheme?.lowercased()) else {
    fail("not a web URL")
}
guard let service = NSSharingService(named: NSSharingService.Name("com.apple.news.openinnews")) else {
    fail("Open in News is unavailable")
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = Delegate()
service.delegate = delegate
service.perform(withItems: [url])
DispatchQueue.main.asyncAfter(deadline: .now() + 15) { fail("timed out") }
app.run()
