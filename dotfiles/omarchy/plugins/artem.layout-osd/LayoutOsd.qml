import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Shows every keyboard layout near the top of the screen: the active one big
// and inverted, the others small and dim. Every cell has the width of the big
// pill, so the row does not shift when the active layout moves.
//
// Summon payload: {"layouts": ["US", "UA"], "index": 1, "duration": 1200}
Item {
  id: root

  property bool opened: false
  property var layouts: []
  property int index: 0
  property int duration: 1200

  readonly property int pad: Style.space(12)
  readonly property int bigFont: Math.round(Style.font.displayLarge * 1.6)
  readonly property int smallFont: Style.font.display
  readonly property int cellWidth: Math.ceil(bigMetrics.advanceWidth) + Style.space(28)
  readonly property int cellHeight: Math.ceil(bigMetrics.height) + Style.space(12)

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      layouts = Array.isArray(p.layouts) ? p.layouts : []
      index = p.index === undefined ? 0 : Number(p.index)
      duration = p.duration === undefined ? 1200 : Number(p.duration)
      opened = true
      hideTimer.restart()
    } catch (e) {}
  }

  function close() { opened = false }

  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.opened = false
  }

  TextMetrics {
    id: bigMetrics
    font.family: Style.font.family
    font.bold: true
    font.pixelSize: root.bigFont
    text: "WW"
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "artem-layout-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    BorderSurface {
      id: card
      width: card.borderLeft + root.pad + row.width + root.pad + card.borderRight
      height: card.borderTop + root.pad + root.cellHeight + root.pad + card.borderBottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: Style.space(48)
      color: Util.alpha(Commons.Color.background, 0.97)
      borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius

      Row {
        id: row
        x: card.borderLeft + root.pad
        y: card.borderTop + root.pad

        Repeater {
          model: root.layouts

          Item {
            required property var modelData
            required property int index
            readonly property bool active: index === root.index
            width: root.cellWidth
            height: root.cellHeight

            Rectangle {
              anchors.fill: parent
              visible: parent.active
              radius: Style.cornerRadius
              color: Commons.Color.popups.text
            }

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: String(parent.modelData)
              font.family: Style.font.family
              font.bold: true
              font.pixelSize: parent.active ? root.bigFont : root.smallFont
              color: parent.active ? Commons.Color.background : Util.alpha(Commons.Color.popups.text, 0.45)
            }
          }
        }
      }
    }
  }
}
