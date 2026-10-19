// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// MacSettings: the page of a sidebar entry that covers several KDE pages
// (General, Appearance…): their names in rounded groups, as macOS lists a
// pane's sub-pages. Clicking one opens it, with ‹ back to this list.
Rectangle {
    id: page

    readonly property var entry: systemsettings.landing
    readonly property int contentWidth: Math.min(width - Kirigami.Units.gridUnit * 3, Kirigami.Units.gridUnit * 34)

    function pageName(id) {
        const names = entry.pageNames || {};
        return names[id] || systemsettings.moduleInfo(id).name || id;
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    // The window paints the background (with its rounded corners).
    color: "transparent"


    QQC2.ScrollView {
        anchors.fill: parent
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        Flickable {
            contentWidth: width
            contentHeight: column.implicitHeight + Kirigami.Units.gridUnit * 2

            ColumnLayout {
                id: column
                x: Math.round((parent.width - page.contentWidth) / 2)
                y: Kirigami.Units.gridUnit * 2.5
                width: page.contentWidth
                spacing: Kirigami.Units.gridUnit

                RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    MacTile {
                        glyph: page.entry.glyph || ""
                        tint: page.entry.color || "#8e8e93"
                        size: 34
                    }
                    Kirigami.Heading {
                        text: page.entry.name || ""
                        level: 1
                        font.weight: Font.Bold
                    }
                }

                Repeater {
                    model: page.entry.sections || []

                    // One rounded group of rows with hairlines between them.
                    delegate: Rectangle {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: rows.implicitHeight
                        radius: 10
                        color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.05)
                        border.width: 1
                        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.09)

                        ColumnLayout {
                            id: rows
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 0

                            Repeater {
                                model: group.modelData
                                delegate: MouseArea {
                                    id: row
                                    required property string modelData
                                    required property int index
                                    readonly property var info: systemsettings.moduleInfo(modelData)
                                    Layout.fillWidth: true
                                    implicitHeight: Kirigami.Units.gridUnit * 2.2
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    Accessible.role: Accessible.Button
                                    Accessible.name: page.pageName(modelData)
                                    onClicked: systemsettings.openFromLanding(modelData)

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: 9
                                        color: Kirigami.Theme.textColor
                                        opacity: row.pressed ? 0.1 : row.containsMouse ? 0.05 : 0
                                    }
                                    // Hairline above every row but the first,
                                    // indented past the icon as on macOS.
                                    Rectangle {
                                        visible: row.index > 0
                                        x: Kirigami.Units.largeSpacing * 2 + 24
                                        width: parent.width - x
                                        height: 1
                                        color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.1)
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Kirigami.Units.largeSpacing
                                        anchors.rightMargin: Kirigami.Units.largeSpacing
                                        spacing: Kirigami.Units.largeSpacing

                                        Kirigami.Icon {
                                            Layout.preferredWidth: 24
                                            Layout.preferredHeight: 24
                                            source: row.info.icon || ""
                                        }
                                        QQC2.Label {
                                            Layout.fillWidth: true
                                            text: page.pageName(row.modelData)
                                            elide: Text.ElideRight
                                        }
                                        Kirigami.Icon {
                                            Layout.preferredWidth: 14
                                            Layout.preferredHeight: 14
                                            source: "go-next-symbolic"
                                            opacity: 0.45
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // No title bar: the strip above the content moves the window.
    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        height: Kirigami.Units.gridUnit * 2.5
        onPressed: systemsettings.startMove()
        onDoubleClicked: systemsettings.toggleMaximized()
    }
}
