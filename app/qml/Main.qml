/*
   SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
   SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
   SPDX-FileCopyrightText: 2026 Brhett

   SPDX-License-Identifier: LGPL-2.0-only
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigamiaddons.components as KirigamiComponents

import "Entries.js" as Entries

// MacSettings: the sidebar, as macOS's System Settings: a search field, the
// user's account, then groups of entries with coloured tiles. An entry with
// one page opens it; one with several shows their list (LandingPage.qml).
// Typing searches KDE's pages by name and keyword.
Item {
    id: root

    // properties, signals and methods used by C++ backend
    readonly property real headerHeight: Kirigami.Units.gridUnit * 2 + Kirigami.Units.largeSpacing

    readonly property var entries: Entries.available(id => systemsettings.hasModule(id))
    readonly property bool searching: searchField.text.length > 0
    // The entry last picked; follows the open page when it changes
    // otherwise (search, a link from another page).
    property string selectedKey: ""
    // Keep the selected entry in view (a page opened from search or another
    // app may be further down).
    onSelectedKeyChanged: {
        const i = entries.findIndex(e => e.key === selectedKey);
        if (i >= 0) {
            list.positionViewAtIndex(i, ListView.Contain);
        }
    }

    function entryFor(moduleId) {
        if (moduleId === "") {
            return null;
        }
        const current = entries.find(e => e.key === selectedKey);
        if (current && current.modules.indexOf(moduleId) >= 0) {
            return current;
        }
        return entries.find(e => e.modules.indexOf(moduleId) >= 0) || null;
    }

    function open(entry) {
        selectedKey = entry.key;
        if (entry.modules.length === 1 && !entry.page) {
            systemsettings.openModule(entry.modules[0]);
        } else {
            systemsettings.openLanding({
                key: entry.key,
                name: entry.name,
                glyph: entry.glyph,
                color: entry.color,
                sections: entry.sections,
                page: entry.page || "",
                pageNames: Entries.pageNames
            });
        }
    }

    implicitWidth: Kirigami.Units.gridUnit * 14
    implicitHeight: Kirigami.Units.gridUnit * 30

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    Connections {
        target: systemsettings
        function onActiveModuleIdChanged() {
            if (!systemsettings.landingShown) {
                const entry = root.entryFor(systemsettings.activeModuleId);
                if (entry) {
                    root.selectedKey = entry.key;
                } else if (systemsettings.activeModuleId === "kcm_users") {
                    root.selectedKey = "account";
                }
            }
        }
    }

    // Start on General, as macOS does, unless a page was asked for.
    Timer {
        running: true
        interval: 0
        onTriggered: {
            const test = root.entries.find(e => e.key === systemsettings.testEntry());
            if (test) {
                root.open(test);
                return;
            }
            const id = systemsettings.activeModuleId;
            if (id === "" || id === "kcm_landingpage") {
                const general = root.entries.find(e => e.key === "general");
                if (general) {
                    root.open(general);
                }
            }
        }
    }

    // macOS's sidebar selection (the accent blue, as in the Mac menus).
    readonly property color selectionColor: "#315bef"
    // Where a row's icon starts: well inside its rounded selection.
    readonly property real rowInset: Kirigami.Units.smallSpacing * 2 + 10

    // The window has no title bar (SettingsChrome paints the glass behind
    // this sidebar): empty space at the top moves it, double-click zooms.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: systemsettings.startMove()
        onDoubleClicked: systemsettings.toggleMaximized()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 1
        spacing: 0

        Stoplights {
            Layout.leftMargin: Kirigami.Units.largeSpacing + 2
            Layout.topMargin: Kirigami.Units.largeSpacing + 4
        }

        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing + 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            focus: !Kirigami.InputMethod.willShowOnActive
            onTextChanged: systemsettings.searchModel.filterRegExp = text
            KeyNavigation.down: searching ? results : list
        }

        // ---- the sidebar ----------------------------------------------------
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.searching
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical: ThinScrollBar {}

            ListView {
                id: list
                clip: true
                model: root.entries
                keyNavigationEnabled: true
                topMargin: Kirigami.Units.smallSpacing
                bottomMargin: Kirigami.Units.largeSpacing

                header: SidebarRow {
                    id: account
                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 3
                    selected: root.selectedKey === "account"
                    visible: systemsettings.hasModule("kcm_users")
                    onClicked: {
                        root.selectedKey = "account";
                        systemsettings.openModule("kcm_users");
                    }

                    KCoreAddons.KUser {
                        id: user
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.rowInset
                        anchors.rightMargin: root.rowInset
                        spacing: Kirigami.Units.largeSpacing

                        KirigamiComponents.Avatar {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                            Layout.preferredHeight: Layout.preferredWidth
                            source: user.faceIconUrl
                            name: user.fullName || user.loginName
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: user.fullName || user.loginName
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                color: account.selected ? "white" : Kirigami.Theme.textColor
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18nc("@label under the user's name in the sidebar", "Account")
                                font: Kirigami.Theme.smallFont
                                elide: Text.ElideRight
                                opacity: 0.7
                                color: account.selected ? "white" : Kirigami.Theme.textColor
                            }
                        }
                    }
                }

                delegate: Item {
                    id: slot
                    required property int index
                    required property var modelData
                    // macOS separates groups with space, no headings.
                    readonly property bool firstOfGroup: index > 0 && root.entries[index - 1].group !== modelData.group
                    width: ListView.view.width
                    height: row.implicitHeight + (firstOfGroup ? Kirigami.Units.largeSpacing * 1.5 : 0)

                    SidebarRow {
                        id: row
                        readonly property var modelData: slot.modelData
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: implicitHeight
                        selected: root.selectedKey === modelData.key
                        onClicked: root.open(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.rowInset
                            anchors.rightMargin: root.rowInset
                            spacing: Kirigami.Units.mediumSpacing

                            MacTile {
                                glyph: row.modelData.glyph
                                tint: row.modelData.color
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: row.selected ? "white" : Kirigami.Theme.textColor
                            }
                        }
                    }
                }
            }
        }

        // ---- search results -------------------------------------------------
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.searching
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical: ThinScrollBar {}

            ListView {
                id: results
                clip: true
                model: root.searching ? systemsettings.searchModel : null
                topMargin: Kirigami.Units.smallSpacing

                delegate: SidebarRow {
                    id: result
                    required property int index
                    required property var model
                    required property bool isKCM
                    required property string iconName
                    width: ListView.view.width
                    height: isKCM ? implicitHeight : 0
                    visible: isKCM
                    selected: systemsettings.activeModuleId !== "" && ListView.isCurrentItem
                    onClicked: {
                        ListView.view.currentIndex = index;
                        systemsettings.loadModule(ListView.view.model.index(index, 0));
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.rowInset
                        anchors.rightMargin: root.rowInset
                        spacing: Kirigami.Units.mediumSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            source: result.iconName
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: result.model.display
                            elide: Text.ElideRight
                            color: result.selected ? "white" : Kirigami.Theme.textColor
                        }
                    }
                }

                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 2
                    visible: root.searching && results.count === 0
                    text: i18nc("A search yielded no results", "No Results")
                }
            }
        }
    }

    // One sidebar row: macOS's rounded selection in the accent colour.
    component SidebarRow: MouseArea {
        id: sidebarRow

        property bool selected: false

        implicitHeight: Kirigami.Units.gridUnit * 1.75
        hoverEnabled: true
        Accessible.role: Accessible.ListItem

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
            anchors.rightMargin: Kirigami.Units.smallSpacing * 2
            radius: 6
            color: sidebarRow.selected ? root.selectionColor
                 : sidebarRow.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
                 : "transparent"
        }
    }
    // macOS's overlay scrollbar: a thin rounded thumb while scrolling.
    component ThinScrollBar: QQC2.ScrollBar {
        id: bar
        width: 8
        policy: QQC2.ScrollBar.AsNeeded
        background: null
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: Kirigami.Theme.textColor
            opacity: bar.active ? (bar.hovered || bar.pressed ? 0.45 : 0.3) : 0
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }
    }

    // The window's close, minimize and zoom buttons, as on macOS: glyphs on
    // hover, gray while the window is inactive.
    // A little larger than the window decorations' (MacSequoia draws ~22 px
    // circles 35 px apart at 1.5×); the user preferred them bigger.
    component Stoplights: Row {
        id: lights
        spacing: 8
        readonly property bool lit: systemsettings.windowActive || lightsHover.hovered

        HoverHandler {
            id: lightsHover
        }

        Repeater {
            model: [
                { color: "#ff5f57", glyph: "×", action: () => systemsettings.closeWindow() },
                { color: "#febc2e", glyph: "−", action: () => systemsettings.minimizeWindow() },
                { color: "#28c840", glyph: "+", action: () => systemsettings.toggleMaximized() }
            ]
            delegate: Rectangle {
                id: light
                required property var modelData
                width: 16
                height: width
                radius: width / 2
                color: !lights.lit ? "#505054" : lightMouse.pressed ? Qt.darker(modelData.color, 1.25) : modelData.color
                border.width: 0.5
                border.color: Qt.rgba(0, 0, 0, 0.2)

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -0.5
                    visible: lightsHover.hovered
                    text: light.modelData.glyph
                    color: Qt.rgba(0, 0, 0, 0.6)
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: lightMouse
                    anchors.fill: parent
                    anchors.margins: -3
                    onClicked: light.modelData.action()
                }
            }
        }
    }
}
