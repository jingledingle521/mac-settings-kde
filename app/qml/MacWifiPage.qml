// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM

// MacSettings: macOS's Wi‑Fi page: Wi‑Fi on or off, the network you're on
// (Details… opens KDE's full network page), your known networks, and the
// other networks around, each with Connect. Uses Plasma's network module,
// like the Network widget; passwords for new networks are asked for by
// Plasma's network agent.
ColumnLayout {
    id: page

    spacing: Kirigami.Units.gridUnit

    // The Wi‑Fi networks, in three lists rebuilt whenever the model changes:
    // the connected (or connecting) one, the saved ones, the rest.
    property var current: []
    property var known: []
    property var others: []

    function signalIcon(signal) {
        if (signal >= 80) return "network-wireless-signal-excellent-symbolic";
        if (signal >= 55) return "network-wireless-signal-good-symbolic";
        if (signal >= 30) return "network-wireless-signal-ok-symbolic";
        if (signal > 5) return "network-wireless-signal-weak-symbolic";
        return "network-wireless-signal-none-symbolic";
    }

    function rebuild() {
        const cur = [], kn = [], ot = [];
        for (let i = 0; i < rows.count; ++i) {
            const r = rows.objectAt(i);
            if (!r || r.model.Type !== PlasmaNM.Enums.Wireless) {
                continue;
            }
            const n = {
                name: r.model.ItemUniqueName,
                signal: r.model.Signal || 0,
                secured: r.model.SecurityType !== undefined && r.model.SecurityType > 0,
                state: r.model.ConnectionState,
                uuid: r.model.Uuid || "",
                connectionPath: r.model.ConnectionPath,
                devicePath: r.model.DevicePath,
                specificPath: r.model.SpecificPath
            };
            if (n.state === PlasmaNM.Enums.Activated || n.state === PlasmaNM.Enums.Activating) {
                cur.push(n);
            } else if (n.uuid !== "") {
                kn.push(n);
            } else {
                ot.push(n);
            }
        }
        const bySignal = (a, b) => b.signal - a.signal;
        kn.sort(bySignal);
        ot.sort(bySignal);
        current = cur;
        known = kn;
        others = ot;
    }

    function connect(n) {
        if (n.uuid !== "") {
            handler.activateConnection(n.connectionPath, n.devicePath, n.specificPath);
        } else {
            handler.addAndActivateConnection(n.devicePath, n.specificPath);
        }
    }

    PlasmaNM.Handler {
        id: handler
    }
    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }
    PlasmaNM.NetworkModel {
        id: networkModel
    }
    PlasmaNM.AppletProxyModel {
        id: networks
        sourceModel: networkModel
        onRowsInserted: rebuildTimer.restart()
        onRowsRemoved: rebuildTimer.restart()
        onDataChanged: rebuildTimer.restart()
        onModelReset: rebuildTimer.restart()
        onLayoutChanged: rebuildTimer.restart()
    }
    Instantiator {
        id: rows
        model: networks
        delegate: QtObject {
            required property var model
        }
        onObjectAdded: rebuildTimer.restart()
        onObjectRemoved: rebuildTimer.restart()
    }
    Timer {
        id: rebuildTimer
        interval: 50
        onTriggered: page.rebuild()
    }
    // Look for networks while the page is open, as macOS does.
    Timer {
        running: enabledConnections.wirelessEnabled && page.visible
        repeat: true
        triggeredOnStart: true
        interval: 10000
        onTriggered: handler.requestScan()
    }

    // ---- Wi‑Fi on or off, and the network you're on --------------------------
    MacGroup {
        MacGroupRow {
            first: true
            implicitHeight: Kirigami.Units.gridUnit * 3.6

            MacTile {
                glyph: "network-wireless-symbolic"
                tint: "#0a84ff"
                size: 36
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                QQC2.Label {
                    text: i18nc("@title", "Wi‑Fi")
                    font.weight: Font.Bold
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Set up Wi‑Fi to connect wirelessly to the internet. Turn on Wi‑Fi, then choose a network to join.")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                    wrapMode: Text.Wrap
                }
            }
            MacSwitch {
                checked: enabledConnections.wirelessEnabled
                enabled: enabledConnections.wirelessHwEnabled
                onToggled: handler.enableWireless(checked)
            }
        }

        Repeater {
            model: enabledConnections.wirelessEnabled ? page.current : []
            delegate: MacGroupRow {
                id: currentRow
                required property var modelData
                readonly property bool connecting: modelData.state === PlasmaNM.Enums.Activating

                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 1
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: currentRow.modelData.name
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        spacing: 5
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            color: currentRow.connecting ? "#ff9f0a" : "#30d158"
                        }
                        QQC2.Label {
                            text: currentRow.connecting ? i18n("Connecting…") : i18n("Connected")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.6
                        }
                    }
                }
                NetworkIcons {
                    signal: currentRow.modelData.signal
                    secured: currentRow.modelData.secured
                }
                QQC2.Button {
                    text: i18n("Details…")
                    onClicked: systemsettings.openFromLanding("kcm_networkmanagement")
                }
            }
        }
    }

    // ---- Known Networks -----------------------------------------------------
    SectionTitle {
        visible: enabledConnections.wirelessEnabled && page.known.length > 0
        text: i18n("Known Networks")
    }
    MacGroup {
        visible: enabledConnections.wirelessEnabled && page.known.length > 0
        Repeater {
            model: page.known
            delegate: NetworkRow {
                known: true
            }
        }
    }

    // ---- Other Networks -----------------------------------------------------
    RowLayout {
        visible: enabledConnections.wirelessEnabled
        spacing: Kirigami.Units.smallSpacing
        SectionTitle {
            text: i18n("Other Networks")
        }
        QQC2.BusyIndicator {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            running: handler.scanning
            visible: running
        }
        Item {
            Layout.fillWidth: true
        }
    }
    MacGroup {
        visible: enabledConnections.wirelessEnabled
        Repeater {
            model: page.others
            delegate: NetworkRow {}
        }
        MacGroupRow {
            first: true
            visible: page.others.length === 0
            QQC2.Label {
                Layout.fillWidth: true
                text: handler.scanning ? i18n("Looking for networks…") : i18n("No other networks found")
                opacity: 0.55
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Item {
            Layout.fillWidth: true
        }
        QQC2.Button {
            text: i18n("Advanced…")
            onClicked: systemsettings.openFromLanding("kcm_networkmanagement")
        }
    }

    // ---- pieces -------------------------------------------------------------

    component SectionTitle: QQC2.Label {
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing
        font.weight: Font.Bold
    }

    // The lock (if secured) and the signal strength, on the right of a row.
    component NetworkIcons: RowLayout {
        property int signal: 0
        property bool secured: false
        spacing: Kirigami.Units.smallSpacing
        Kirigami.Icon {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            visible: parent.secured
            source: "object-locked-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
            opacity: 0.6
        }
        Kirigami.Icon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: page.signalIcon(parent.signal)
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    // A network you could join: Connect appears on hover (always for known
    // networks' "…" menu), as on macOS.
    component NetworkRow: MacGroupRow {
        id: networkRow
        required property var modelData
        required property int index
        property bool known: false
        readonly property bool showConnect: containsMouse || connectButton.hovered

        first: index === 0

        QQC2.Label {
            Layout.fillWidth: true
            text: networkRow.modelData.name
            elide: Text.ElideRight
        }
        QQC2.Button {
            id: connectButton
            text: i18n("Connect")
            opacity: networkRow.showConnect ? 1 : 0
            enabled: networkRow.showConnect
            onClicked: page.connect(networkRow.modelData)
        }
        NetworkIcons {
            signal: networkRow.modelData.signal
            secured: networkRow.modelData.secured
        }
        QQC2.ToolButton {
            visible: networkRow.known
            icon.name: "overflow-menu"
            display: QQC2.AbstractButton.IconOnly
            text: i18n("More")
            onClicked: knownMenu.popup()

            QQC2.Menu {
                id: knownMenu
                QQC2.MenuItem {
                    text: i18n("Connect")
                    onTriggered: page.connect(networkRow.modelData)
                }
                QQC2.MenuItem {
                    text: i18n("Forget This Network")
                    onTriggered: handler.removeConnection(networkRow.modelData.connectionPath)
                }
            }
        }
    }
}
