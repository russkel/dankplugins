import QtQuick
import Quickshell
import Quickshell.Io

// Authenticated request to the Shortcut API. Token and any POST body go in the
// process environment (never arguments) so they never appear in `ps`/`/proc`.
Item {
    id: root
    property string baseUrl: "https://api.app.shortcut.com/api/v3"
    property string path: ""
    property string token: ""
    property string method: "GET"     // "GET" or "POST"
    property string body: ""          // JSON string, used when method === "POST"

    signal loaded(string jsonText)
    signal failed(int code)

    function run() {
        if (root.token.length === 0 || root.path.length === 0) { root.failed(-1); return }
        proc.running = false
        const url = root.baseUrl + root.path
        if (root.method === "POST") {
            proc.command = ["sh", "-c",
                "curl -sS --fail --compressed --connect-timeout 3 --max-time 8 " +
                "-X POST -H \"Shortcut-Token: $SC_TOKEN\" -H 'Content-Type: application/json' " +
                "--data \"$SC_BODY\" '" + url + "'"]
        } else {
            proc.command = ["sh", "-c",
                "curl -sS --fail --compressed --connect-timeout 3 --max-time 8 " +
                "-H \"Shortcut-Token: $SC_TOKEN\" '" + url + "'"]
        }
        proc.running = true
    }

    Process {
        id: proc
        running: false
        property string buf: ""
        environment: ({ "SC_TOKEN": root.token, "SC_BODY": root.body })
        stdout: StdioCollector { onStreamFinished: proc.buf = text }
        onExited: code => {
            const t = proc.buf.trim()
            proc.buf = ""
            if (code === 0 && t.length > 0) root.loaded(t)
            else root.failed(code)
        }
    }
}
