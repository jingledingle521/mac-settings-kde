// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2

// MacSettings: the ‹ back to a list of pages, inside a QML page's own header
// (a widget laid over the page would be hidden under it). ModuleView makes
// room for it with the header's titleLeftPadding.
QQC2.ToolButton {
    objectName: "macBack"
    required property QtObject view
    // Height of the page's header (Kirigami's global toolbar).
    property real headerHeight: 46

    x: 8
    y: Math.round((headerHeight - height) / 2)
    z: 1000
    icon.name: "go-previous"
    display: QQC2.AbstractButton.IconOnly
    text: typeof i18nc === "function" ? i18nc("@info:tooltip", "Back") : "Back"
    QQC2.ToolTip.text: text
    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.delay: 600
    onClicked: view.requestBack()
}
