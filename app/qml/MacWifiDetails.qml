// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// MacSettings: macOS's Wi‑Fi Details sheet for the network you're on: its
// name and state, then its details in rounded groups (from Plasma's network
// module: the network, IPv4, IPv6), with Forget This Network… and Done.
// Advanced… opens KDE's full network page.
QQC2.Popup {
    id: sheet

    // The network (as MacWifiPage lists it) and its details model.
    property var network: null
    // Called to forget it (the page knows how).
    signal forgetRequested(var network)

    property var sections: []
    // macOS's names for a few of the details.
    readonly property var macNames: ({
        "Default Gateway": i18n("Router"),
        "Primary Nameserver": i18n("DNS Server"),
        "Secondary Nameserver": i18n("Second DNS Server"),
        "Access Point (SSID)": i18n("Network Name"),
        "MAC Address": i18n("Wi‑Fi Address")
    })

    // The model's rows (section titles, then label/value pairs) as groups.
    // Roles: Qt.UserRole + 1…4 = is section, section title, label, value.
    function read() {
        const model = network ? network.details : null;
        const result = [];
        if (model) {
            for (let i = 0; i < model.rowCount(); ++i) {
                const index = model.index(i, 0);
                if (model.data(index, Qt.UserRole + 1)) {
                    result.push({ title: model.data(index, Qt.UserRole + 2), rows: [] });
                } else if (result.length > 0) {
                    let label = model.data(index, Qt.UserRole + 3) || "";
                    // "IPv4 Address" under IPv4 reads as "Address".
                    const title = result[result.length - 1].title;
                    if (label.startsWith(title + " ")) {
                        label = label.substring(title.length + 1);
                        label = label.charAt(0).toUpperCase() + label.substring(1);
                    }
                    label = macNames[label] || label;
                    result[result.length - 1].rows.push({ label: label, value: model.data(index, Qt.UserRole + 4) || "" });
                }
            }
        }
        sections = result.filter(s => s.rows.length > 0);
    }

    function show(n) {
        network = n;
        read();
        open();
    }

    parent: QQC2.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - Kirigami.Units.gridUnit * 2 : 0, Kirigami.Units.gridUnit * 28)
    height: Math.min(parent ? parent.height - Kirigami.Units.gridUnit * 3 : 0, column.implicitHeight + topPadding + bottomPadding)
    modal: true
    dim: true
    padding: Kirigami.Units.gridUnit
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    Connections {
        target: sheet.network ? sheet.network.details : null
        function onModelReset() { sheet.read(); }
        function onDataChanged() { sheet.read(); }
        function onRowsInserted() { sheet.read(); }
        function onRowsRemoved() { sheet.read(); }
    }

    QQC2.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 120 }
    }

    background: Rectangle {
        radius: 12
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
    }

    contentItem: ColumnLayout {
        id: column
        spacing: Kirigami.Units.gridUnit

        // The network: its tile, name and state.
        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            MacTile {
                glyph: "network-wireless-symbolic"
                tint: "#0a84ff"
                size: 36
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                QQC2.Label {
                    Layout.fillWidth: true
                    text: sheet.network ? sheet.network.name : ""
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                RowLayout {
                    spacing: 5
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: "#30d158"
                    }
                    QQC2.Label {
                        text: i18n("Connected")
                        font: Kirigami.Theme.smallFont
                        opacity: 0.6
                    }
                }
            }
            QQC2.Button {
                text: i18n("Forget This Network…")
                visible: sheet.network !== null && sheet.network.uuid !== ""
                onClicked: forgetConfirm.open()
            }
        }

        // The details, scrolling when they don't fit.
        QQC2.ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: details.implicitHeight
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            ColumnLayout {
                id: details
                // Clear of the scroll bar when it shows.
                width: scroll.availableWidth - (scroll.QQC2.ScrollBar.vertical.visible ? scroll.QQC2.ScrollBar.vertical.width + Kirigami.Units.smallSpacing : 0)
                spacing: Kirigami.Units.gridUnit

                Repeater {
                    model: sheet.sections
                    delegate: ColumnLayout {
                        id: section
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                            text: section.modelData.title
                            font.weight: Font.Bold
                        }
                        MacGroup {
                            Repeater {
                                model: section.modelData.rows
                                delegate: MacGroupRow {
                                    id: detailRow
                                    required property var modelData
                                    required property int index
                                    first: index === 0
                                    implicitHeight: Kirigami.Units.gridUnit * 1.9
                                    QQC2.Label {
                                        text: detailRow.modelData.label
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    QQC2.Label {
                                        Layout.maximumWidth: details.width * 0.6
                                        text: detailRow.modelData.value
                                        opacity: 0.6
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                text: i18n("Advanced…")
                onClicked: {
                    sheet.close();
                    systemsettings.openFromLanding("kcm_networkmanagement");
                }
            }
            Item {
                Layout.fillWidth: true
            }
            QQC2.Button {
                text: i18n("Done")
                highlighted: true
                Accessible.defaultButton: true
                onClicked: sheet.close()
            }
        }
    }

    Kirigami.PromptDialog {
        id: forgetConfirm
        parent: QQC2.Overlay.overlay
        title: i18n("Forget “%1”?", sheet.network ? sheet.network.name : "")
        subtitle: i18n("This computer will no longer join this Wi‑Fi network automatically.")
        standardButtons: QQC2.Dialog.Cancel
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Forget")
                onTriggered: {
                    forgetConfirm.close();
                    sheet.forgetRequested(sheet.network);
                    sheet.close();
                }
            }
        ]
    }
}
