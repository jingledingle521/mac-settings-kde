// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// MacSettings: one of macOS's rounded groups of rows. Rows go in as
// children; MacGroupRow draws the hairline above each row but the first.
Rectangle {
    id: group

    default property alias rows: column.data

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight
    radius: 10
    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.05)
    border.width: 1
    border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.09)

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
    }
}
