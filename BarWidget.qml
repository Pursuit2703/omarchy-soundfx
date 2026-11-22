import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Sound FX: one orb toggles Razer-style virtual 7.1 surround. The truth lives in
// ~/.local/state/soundfx (written by the soundfx daemon); this widget only asks
// for "on"/"off" and mirrors status.json, so the UI can never drift from the audio.
BarWidget {
  id: root
  moduleName: "omar.soundfx"

  readonly property string bin: Quickshell.env("HOME") + "/.local/bin/soundfx"
  readonly property string statusPath: Quickshell.env("HOME") + "/.local/state/soundfx/status.json"

  // What the audio really is (from status.json) and what the UI shows.
  property bool realOn: false
  property int bass: 1
  property bool available: true
  property bool synced: true
  property bool uiOn: false
  property double lastClickMs: 0
  property bool popupOpen: false
  function close() { popupOpen = false }

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // ---- status mirror ------------------------------------------------------
  FileView {
    id: statusView
    path: root.statusPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var s = JSON.parse(text())
        root.realOn = s.on === true
        root.bass = Number(s.bass)
        root.available = s.available !== false
        root.synced = s.synced !== false
        // A fresh click wins for a moment; the status file catches up behind it.
        if (Date.now() - root.lastClickMs > 1500 || root.realOn === root.uiOn) root.uiOn = root.realOn
      } catch (e) { }
    }
    onFileChanged: reload()
  }

  // Truth wins: if the audio disagrees with the orb a moment after a click, follow the audio.
  Timer {
    interval: 1600
    running: root.uiOn !== root.realOn
    repeat: false
    onTriggered: { statusView.reload() }
  }

  // ---- sending (latest request wins, never overlapping) -------------------
  property string want: ""
  property string sent: ""
  Process {
    id: sender
    onExited: root.flush()
  }
  function flush() {
    if (sender.running || want === "" || want === sent) return
    sent = want
    sender.command = [root.bin, want]
    sender.running = true
  }
  function setOn(v) {
    lastClickMs = Date.now()
    uiOn = v
    want = v ? "on" : "off"
    sent = ""
    flush()
  }

  property int bassWant: -1
  Process {
    id: bassProc
    onExited: if (root.bassWant >= 0 && root.bassWant !== root.bass) root.setBass(root.bassWant)
  }
  function setBass(n) {
    bassWant = n
    bass = n
    if (bassProc.running) return
    bassProc.command = [root.bin, "bass", String(n)]
    bassProc.running = true
  }

  // ---- bar icon -----------------------------------------------------------
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰋋"
    tooltipText: root.uiOn ? "Surround 7.1 on (right-click to turn off)" : "Surround off (right-click to turn on)"
    // Gray while off, white while on. Steady, no pulsing. `dimmed` is the button's
    // own 0.45 fade, so nothing here fights its opacity binding.
    dimmed: !root.uiOn
    onPressed: function(b) {
      if (b === Qt.RightButton) root.setOn(!root.uiOn)
      else root.popupOpen = !root.popupOpen
    }
  }

  // ---- panel --------------------------------------------------------------
  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(col.implicitHeight, Style.space(520))

    Column {
      id: col
      width: parent.width
      spacing: Style.space(8)

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Sound FX"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Item {
        id: scene
        width: parent.width
        height: Style.space(190)

        // 0 = off, 1 = on; eases both ways so nothing ever snaps.
        property real glow: root.uiOn ? 1 : 0
        Behavior on glow { NumberAnimation { duration: 750; easing.type: Easing.OutCubic } }
        property real t: 0
        property real ringPhase: 0

        Timer {
          interval: 16
          repeat: true
          running: popup.open && scene.glow > 0.004
          onTriggered: { scene.t += 0.018; ribbons.requestPaint() }
        }
        NumberAnimation on ringPhase {
          running: popup.open && scene.glow > 0.004
          from: 0; to: 1; duration: 3000; loops: Animation.Infinite
        }
        onGlowChanged: ribbons.requestPaint()

        // Sound ribbons pouring out of the orb.
        Canvas {
          id: ribbons
          anchors.fill: parent
          renderTarget: Canvas.FramebufferObject
          property color c1: root.accent
          onC1Changed: requestPaint()
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var W = width, H = height, w = scene.glow
            var n = 7
            for (var i = 0; i < n; i++) {
              var f = i / (n - 1) - 0.5
              var mid = (i === 3)
              var a = mid ? 0.25 + 0.45 * w : 0.6 * w * (1 - Math.abs(f) * 1.3)
              ctx.beginPath()
              for (var x = 0; x <= W; x += 3) {
                var d = Math.abs(x / W - 0.5) * 2
                var env = Math.pow(d, 0.85) * (0.25 + 0.75 * d)
                var amp = H * 0.34 * env * w
                var y = H / 2 + f * H * 0.6 * env * w
                        + Math.sin(d * 9 - scene.t * 3 + i * 0.9) * amp * (mid ? 0.5 : 1)
                        + Math.sin(d * 21 - scene.t * 4) * amp * 0.1
                if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
              }
              ctx.strokeStyle = Qt.rgba(c1.r, c1.g, c1.b, Math.max(0.1, a))
              ctx.lineWidth = mid ? 3 : 2
              ctx.stroke()
            }
          }
        }

        // Pulse rings (phase-driven so they fade out with glow instead of snapping).
        Repeater {
          model: 3
          Rectangle {
            required property int index
            readonly property real p: (scene.ringPhase + index / 3) % 1
            anchors.centerIn: parent
            width: orb.width
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: root.accent
            scale: 0.9 + 1.7 * p
            opacity: (1 - p) * 0.55 * scene.glow
          }
        }

        // One-shot burst when turning on.
        Rectangle {
          id: burst
          anchors.centerIn: parent
          width: orb.width
          height: width
          radius: width / 2
          color: root.accent
          opacity: 0
          ParallelAnimation {
            id: burstAnim
            NumberAnimation { target: burst; property: "opacity"; from: 0.5; to: 0; duration: 800; easing.type: Easing.OutCubic }
            NumberAnimation { target: burst; property: "scale"; from: 0.8; to: 3; duration: 800; easing.type: Easing.OutCubic }
          }
        }

        // Glow behind the orb.
        Rectangle {
          anchors.centerIn: parent
          width: orb.width * 1.55
          height: width
          radius: width / 2
          color: root.accent
          opacity: 0.16 * scene.glow
        }

        Rectangle {
          id: orb
          anchors.centerIn: parent
          width: Style.space(104)
          height: width
          radius: width / 2
          scale: (0.94 + 0.14 * scene.glow) * (orbMouse.pressed ? 0.93 : 1)
          Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
          opacity: root.available ? 1 : 0.55
          gradient: Gradient {
            GradientStop { position: 0; color: Qt.tint(Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18), Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.95 * scene.glow)) }
            GradientStop { position: 1; color: Qt.tint(Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08), Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.62 * scene.glow)) }
          }
          // soft highlight
          Rectangle {
            x: parent.width * 0.2; y: parent.height * 0.12
            width: parent.width * 0.42; height: parent.height * 0.26
            radius: height / 2
            color: "white"
            opacity: 0.1 + 0.2 * scene.glow
          }
          Text {
            anchors.centerIn: parent
            text: "󰋋"
            font.family: root.fontFamily
            font.pixelSize: Style.space(44)
            color: Qt.tint(Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.7), Qt.rgba(Color.background.r, Color.background.g, Color.background.b, scene.glow))
          }
          MouseArea {
            id: orbMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setOn(!root.uiOn)
          }
        }
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.uiOn ? "Surround on" : "Surround off"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: !root.available ? "Works on the headphone jack only"
            : root.uiOn ? "7.1 · Razer HRIR" : "Plain stereo"
        color: Qt.darker(root.fg, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(10)
        topPadding: Style.space(6)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Bass"
          color: Qt.darker(root.fg, 1.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Rectangle {
          width: Style.space(200)
          height: Style.space(28)
          radius: height / 2
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.07)
          Rectangle {
            id: pick
            y: Style.space(3)
            height: parent.height - Style.space(6)
            width: (parent.width - Style.space(6)) / 3
            radius: height / 2
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.14)
            x: Style.space(3) + root.bass * width
            Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
          }
          Row {
            anchors.fill: parent
            anchors.margins: Style.space(3)
            Repeater {
              model: ["Soft", "Normal", "Deep"]
              Item {
                required property int index
                required property string modelData
                width: (parent.width) / 3
                height: parent.height
                Text {
                  anchors.centerIn: parent
                  text: modelData
                  color: root.bass === index ? root.fg : Qt.darker(root.fg, 1.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setBass(index)
                }
              }
            }
          }
        }
      }
    }
  }

  onUiOnChanged: if (uiOn) { burstAnim.restart() }

  // omarchy-shell omar.soundfx on|off|toggle|open|close  (handy for keybinds)
  IpcHandler {
    target: "omar.soundfx"
    function on(): void { root.setOn(true) }
    function off(): void { root.setOn(false) }
    function toggle(): void { root.setOn(!root.uiOn) }
    function open(): void { root.popupOpen = true }
    function close(): void { root.popupOpen = false }
  }
}
