// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

// MacSettings: macOS's switch: a rounded track (the accent blue when on) and
// a white knob that slides across.
T.Switch {
    id: control

    implicitWidth: 38
    implicitHeight: 22
    padding: 0
    hoverEnabled: true

    indicator: Rectangle {
        width: control.width
        height: control.height
        radius: height / 2
        color: control.checked ? Kirigami.Theme.focusColor
             : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, control.hovered ? 0.22 : 0.16)
        opacity: control.enabled ? 1 : 0.45
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            width: parent.height - 4
            height: width
            radius: width / 2
            y: 2
            x: control.checked ? parent.width - width - 2 : 2
            color: control.pressed ? "#e8e8ec" : "white"
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0.15)
            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
    }
    contentItem: null
}
