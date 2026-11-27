import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Click-through overlay across all monitors to hint which physical display is
// being configured or to identify every active monitor with big numbered badges.
//
// Summon payload:
//   {"mode":"focus"|"identify"|"clear","focus":"DP-6","duration":2600,
//    "displays":[{"name":"DP-6","number":1,"title":"HP Z24n G3","sub":"1920×1200 · 100%","main":true,"ws":"4"}]}
Item {
  id: root

  property bool opened: false
  property string mode: "identify"
  property string focusName: ""
  property var displays: []
  property int duration: 2800

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      if (p.mode === "clear") {
        opened = false
        hideTimer.stop()
        return
      }
      mode = p.mode === "focus" ? "focus" : "identify"
      focusName = String(p.focus || "")
      displays = Array.isArray(p.displays) ? p.displays : []
      duration = p.duration === undefined ? (mode === "identify" ? 3600 : 2400) : Math.max(400, Math.min(12000, Number(p.duration) || 2600))
      opened = displays.length > 0
      if (opened) hideTimer.restart()
      else hideTimer.stop()
    } catch (e) {}
  }

  function close() {
    opened = false
    hideTimer.stop()
  }

  function infoFor(screenName) {
    for (var i = 0; i < displays.length; i++) {
      if (displays[i] && displays[i].name === screenName) return displays[i]
    }
    return null
  }

  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.opened = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData

      readonly property var info: root.infoFor(modelData ? modelData.name : "")
      readonly property bool isTarget: root.focusName !== "" && modelData && modelData.name === root.focusName
      readonly property bool fullCard: root.mode === "identify" || isTarget

      screen: modelData
      visible: root.opened && !!info
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "artem-display-osd"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      // Screen-edge frame: vivid accent on the targeted display, subtle frame on others in identify mode.
      Rectangle {
        anchors.fill: parent
        visible: win.fullCard
        color: win.isTarget ? Util.alpha(Commons.Color.accent, 0.05) : "transparent"
        border.width: win.isTarget ? Math.max(6, Style.space(6)) : Math.max(2, Style.space(2))
        border.color: win.isTarget ? Commons.Color.accent : Util.alpha(Commons.Color.popups.border, 0.55)
      }

      // Corner brackets for extra visibility on the targeted display.
      Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(8, Style.space(8))
        visible: win.isTarget
        color: "transparent"
        border.width: 2
        border.color: Util.alpha(Commons.Color.accent, 0.35)
        radius: Style.cornerRadius
      }

      // Full center badge card (shown on all screens in identify mode, and on the targeted screen in focus mode).
      BorderSurface {
        id: card
        visible: win.fullCard && !!win.info
        anchors.centerIn: parent
        width: card.borderLeft + cardPad + cardRow.implicitWidth + cardPad + card.borderRight
        height: card.borderTop + cardPad + cardRow.implicitHeight + cardPad + card.borderBottom
        color: Util.alpha(Commons.Color.background, 0.94)
        borderSpec: Border.surfaceSpec(
          "popups", "border",
          win.isTarget ? Commons.Color.accent : Commons.Color.popups.border,
          Math.max(2, Style.space(win.isTarget ? 3 : 2))
        )
        radius: Style.cornerRadius

        readonly property int cardPad: Style.space(20)

        Row {
          id: cardRow
          x: card.borderLeft + card.cardPad
          y: card.borderTop + card.cardPad
          spacing: Style.space(18)

          Rectangle {
            width: Math.max(76, Style.space(76))
            height: width
            radius: Style.cornerRadius
            anchors.verticalCenter: parent.verticalCenter
            color: win.isTarget ? Commons.Color.accent : Util.alpha(Commons.Color.popups.text, 0.14)

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: win.info ? String(win.info.number || "?") : ""
              font.family: Style.font.family
              font.bold: true
              font.pixelSize: Math.round(Style.font.displayLarge * 1.9)
              color: win.isTarget ? Commons.Color.background : Commons.Color.popups.text
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(5)

            Row {
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: win.info ? String(win.info.title || win.info.name || "") : ""
                font.family: Style.font.family
                font.bold: true
                font.pixelSize: Math.round(Style.font.displayLarge * 1.05)
                color: Commons.Color.popups.text
                anchors.verticalCenter: parent.verticalCenter
              }

              Rectangle {
                visible: !!(win.info && win.info.main)
                radius: 999
                color: Util.alpha(Commons.Color.accent, 0.22)
                border.width: 1
                border.color: Commons.Color.accent
                width: mainLbl.implicitWidth + Style.space(14)
                height: mainLbl.implicitHeight + Style.space(6)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  id: mainLbl
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: "★ Main"
                  font.family: Style.font.family
                  font.bold: true
                  font.pixelSize: Style.font.body
                  color: Commons.Color.accent
                }
              }
            }

            Text {
              textFormat: Text.PlainText
              text: win.info ? (String(win.info.name || "") + (win.info.sub ? " · " + String(win.info.sub) : "")) : ""
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              color: Util.alpha(Commons.Color.popups.text, 0.82)
            }

            Text {
              visible: win.isTarget || !!(win.info && win.info.ws)
              textFormat: Text.PlainText
              text: {
                var bits = []
                if (win.isTarget) bits.push("Configuring in Pulpit")
                if (win.info && win.info.ws) bits.push("Workspace " + String(win.info.ws))
                return bits.join(" · ")
              }
              font.family: Style.font.family
              font.bold: win.isTarget
              font.pixelSize: Style.font.body
              color: win.isTarget ? Commons.Color.accent : Util.alpha(Commons.Color.popups.text, 0.6)
            }
          }
        }
      }

      // Quiet corner pill on non-targeted screens during single-display focus hinting.
      BorderSurface {
        id: mini
        visible: !win.fullCard && !!win.info
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Style.space(44)
        anchors.leftMargin: Style.space(22)
        width: mini.borderLeft + Style.space(12) + miniRow.implicitWidth + Style.space(12) + mini.borderRight
        height: mini.borderTop + Style.space(8) + miniRow.implicitHeight + Style.space(8) + mini.borderBottom
        color: Util.alpha(Commons.Color.background, 0.88)
        borderSpec: Border.surfaceSpec("popups", "border", Util.alpha(Commons.Color.popups.border, 0.55), 1)
        radius: Style.cornerRadius

        Row {
          id: miniRow
          x: mini.borderLeft + Style.space(12)
          y: mini.borderTop + Style.space(8)
          spacing: Style.space(8)

          Rectangle {
            width: Math.max(24, Style.space(24))
            height: width
            radius: 6
            color: Util.alpha(Commons.Color.popups.text, 0.16)
            anchors.verticalCenter: parent.verticalCenter

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: win.info ? String(win.info.number || "?") : ""
              font.family: Style.font.family
              font.bold: true
              font.pixelSize: Style.font.body
              color: Commons.Color.popups.text
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: win.info ? (String(win.info.name || "") + (win.info.main ? " · ★ Main" : "")) : ""
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Util.alpha(Commons.Color.popups.text, 0.78)
          }
        }
      }
    }
  }
}
