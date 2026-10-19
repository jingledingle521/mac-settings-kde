// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

// MacSettings: a macOS System Settings icon: a white glyph on a rounded tile
// of colour, a little lighter at the top.
Rectangle {
    id: tile

    property string glyph
    property color tint: "#8e8e93"
    property int size: 22

    width: size
    height: size
    radius: Math.round(size * 0.25)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(tile.tint, 1.12) }
        GradientStop { position: 1; color: tile.tint }
    }
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(tile.size * 0.68)
        height: width
        source: tile.glyph
        isMask: true
        color: "white"
    }
}
