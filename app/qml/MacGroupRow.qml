// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// MacSettings: a row in a MacGroup: padding, a hairline above it (unless
// it's the first), a hover tint when it's clickable.
MouseArea {
    id: row

    default property alias content: inner.data
    property bool first: false
    property bool clickable: false
    property real indent: Kirigami.Units.largeSpacing

    Layout.fillWidth: true
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 2.2, inner.implicitHeight + Kirigami.Units.largeSpacing * 1.5)
    hoverEnabled: true
    cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 9
        color: Kirigami.Theme.textColor
        opacity: row.clickable ? (row.pressed ? 0.1 : row.containsMouse ? 0.05 : 0) : 0
    }
    Rectangle {
        visible: !row.first
        x: row.indent
        width: parent.width - x
        height: 1
        color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.1)
    }
    RowLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing
    }
}
