// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.bluezqt as BluezQt

// MacSettings: macOS's Bluetooth page: Bluetooth on or off, the computer
// discoverable while the page is open, your devices (connect, disconnect,
// forget) and nearby ones found by scanning while the page is open
// (Connect pairs, trusts and connects; PINs are asked for by Plasma's
// Bluetooth agent). Advanced… opens KDE's full Bluetooth page.
ColumnLayout {
    id: page

    spacing: Kirigami.Units.gridUnit

    readonly property var manager: BluezQt.Manager
    readonly property var adapter: manager.usableAdapter
    readonly property bool on: manager.bluetoothOperational

    property var myDevices: []
    property var nearby: []
    // The device being paired by Connect, connected once paired.
    property var pairing: null
    // Why the last Connect failed, shown under Nearby Devices.
    property string pairError: ""
    // Whether we made the adapter discoverable (and so undo it on leaving).
    property bool madeDiscoverable: false

    function rebuild() {
        const mine = [], near = [];
        for (let i = 0; i < rows.count; ++i) {
            const r = rows.objectAt(i);
            if (!r) {
                continue;
            }
            const d = {
                ubi: r.model.Ubi,
                name: r.model.Name || r.model.Address,
                // Unnamed devices get their address as a name (with dashes).
                hasName: (r.model.Name || "") !== "" && !/^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(r.model.Name),
                icon: r.model.Icon || "preferences-system-bluetooth",
                connected: r.model.Connected === true,
                paired: r.model.Paired === true
            };
            if (d.paired) {
                mine.push(d);
            } else if (d.hasName) {
                near.push(d);
            }
        }
        mine.sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));
        near.sort((a, b) => a.name.localeCompare(b.name));
        myDevices = mine;
        nearby = near;
    }

    function setOn(enable) {
        manager.bluetoothBlocked = !enable;
        for (const a of manager.adapters) {
            a.powered = enable;
        }
    }

    function device(ubi) {
        return manager.deviceForUbi(ubi);
    }

    function connectNew(ubi) {
        const d = device(ubi);
        if (!d) {
            return;
        }
        pairing = d;
        pairError = "";
        const call = d.pair();
        call.finished.connect(() => {
            if (page.pairing !== d) {
                return;
            }
            if (call.error === BluezQt.PendingCall.AlreadyExists) {
                // Paired already: onPairedChanged won't come, connect now.
                d.trusted = true;
                d.connectToDevice();
                page.pairing = null;
            } else if (call.error !== BluezQt.PendingCall.NoError) {
                page.pairing = null;
                page.pairError = i18n("Couldn't connect to “%1”. Put it in pairing mode and try again.", d.name);
            }
        });
    }

    // While the page is open: discoverable and scanning, as on macOS.
    function startLooking() {
        if (!adapter || !adapter.powered) {
            return;
        }
        if (!adapter.discoverable) {
            adapter.discoverable = true;
            madeDiscoverable = true;
        }
        if (!adapter.discovering) {
            adapter.startDiscovery();
        }
    }
    function stopLooking() {
        if (!adapter) {
            return;
        }
        if (adapter.discovering) {
            adapter.stopDiscovery();
        }
        if (madeDiscoverable) {
            adapter.discoverable = false;
            madeDiscoverable = false;
        }
    }

    onOnChanged: Qt.callLater(on ? startLooking : stopLooking)
    onAdapterChanged: Qt.callLater(startLooking)
    Component.onCompleted: Qt.callLater(startLooking)
    Component.onDestruction: stopLooking()

    Connections {
        target: page.pairing
        function onPairedChanged() {
            if (page.pairing && page.pairing.paired) {
                page.pairing.trusted = true;
                page.pairing.connectToDevice();
                page.pairing = null;
            }
        }
    }

    BluezQt.DevicesModel {
        id: devicesModel
        onRowsInserted: rebuildTimer.restart()
        onRowsRemoved: rebuildTimer.restart()
        onDataChanged: rebuildTimer.restart()
        onModelReset: rebuildTimer.restart()
    }
    Instantiator {
        id: rows
        model: devicesModel
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

    // ---- Bluetooth on or off --------------------------------------------------
    MacGroup {
        MacGroupRow {
            first: true
            implicitHeight: Kirigami.Units.gridUnit * 3.6

            MacTile {
                glyph: "bluetooth-symbolic"
                tint: "#0a84ff"
                size: 36
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                QQC2.Label {
                    text: i18nc("@title", "Bluetooth")
                    font.weight: Font.Bold
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: !page.manager.operational ? i18n("Bluetooth isn't available on this computer.")
                        : page.on && page.adapter ? i18n("This computer is discoverable as “%1” while Bluetooth settings are open.", page.adapter.name)
                        : i18n("Turn on Bluetooth to connect to devices like headphones, keyboards and mice.")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                    wrapMode: Text.Wrap
                }
            }
            MacSwitch {
                checked: page.on
                enabled: page.manager.operational || page.manager.bluetoothBlocked
                onToggled: page.setOn(checked)
            }
        }
    }

    // ---- My Devices -----------------------------------------------------------
    SectionTitle {
        visible: page.myDevices.length > 0
        text: i18n("My Devices")
    }
    MacGroup {
        visible: page.myDevices.length > 0
        Repeater {
            model: page.myDevices
            delegate: DeviceRow {
                mine: true
            }
        }
    }

    // ---- Nearby Devices -------------------------------------------------------
    RowLayout {
        visible: page.on
        spacing: Kirigami.Units.smallSpacing
        SectionTitle {
            text: i18n("Nearby Devices")
        }
        QQC2.BusyIndicator {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            running: page.adapter ? page.adapter.discovering : false
            visible: running
        }
        Item {
            Layout.fillWidth: true
        }
    }
    MacGroup {
        visible: page.on
        Repeater {
            model: page.nearby
            delegate: DeviceRow {}
        }
        MacGroupRow {
            first: true
            visible: page.nearby.length === 0
            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Looking for devices…")
                opacity: 0.55
            }
        }
    }
    QQC2.Label {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        visible: page.on && page.pairError !== ""
        text: page.pairError
        color: Kirigami.Theme.negativeTextColor
        font: Kirigami.Theme.smallFont
        wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.fillWidth: true
        Item {
            Layout.fillWidth: true
        }
        QQC2.Button {
            text: i18n("Advanced…")
            onClicked: systemsettings.openFromLanding("kcm_bluetooth")
        }
    }

    // ---- pieces -------------------------------------------------------------

    component SectionTitle: QQC2.Label {
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing
        font.weight: Font.Bold
    }

    // A device: its icon in a gray circle, its name, its state, and a button
    // that appears on hover (Connect / Disconnect), as on macOS.
    component DeviceRow: MacGroupRow {
        id: deviceRow
        required property var modelData
        required property int index
        property bool mine: false
        readonly property bool hoveredRow: containsMouse || actionButton.hovered || menuButton.hovered
        readonly property bool busy: page.pairing !== null && page.pairing.ubi === modelData.ubi

        first: index === 0

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 16
                height: 16
                // The symbolic glyph: colour icons turn into blank
                // squares when drawn as a mask.
                source: deviceRow.modelData.icon + "-symbolic"
                fallback: "bluetooth-symbolic"
                isMask: true
                color: Kirigami.Theme.textColor
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: deviceRow.modelData.name
            elide: Text.ElideRight
        }
        QQC2.BusyIndicator {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            visible: deviceRow.busy
            running: visible
        }
        QQC2.Label {
            visible: deviceRow.mine && !deviceRow.hoveredRow
            text: deviceRow.modelData.connected ? i18n("Connected") : i18n("Not Connected")
            opacity: 0.55
        }
        QQC2.Button {
            id: actionButton
            visible: deviceRow.hoveredRow && !deviceRow.busy
            // A nearby device can be connected without being paired (a
            // keyboard that still has an old pairing): Connect pairs it.
            readonly property bool disconnects: deviceRow.modelData.paired && deviceRow.modelData.connected
            text: disconnects ? i18n("Disconnect") : i18n("Connect")
            onClicked: {
                const d = page.device(deviceRow.modelData.ubi);
                if (!d) {
                    return;
                }
                if (disconnects) {
                    d.disconnectFromDevice();
                } else if (deviceRow.modelData.paired) {
                    d.connectToDevice();
                } else {
                    page.connectNew(deviceRow.modelData.ubi);
                }
            }
        }
        QQC2.ToolButton {
            id: menuButton
            visible: deviceRow.mine
            icon.name: "overflow-menu"
            display: QQC2.AbstractButton.IconOnly
            text: i18n("More")
            onClicked: deviceMenu.popup()

            QQC2.Menu {
                id: deviceMenu
                QQC2.MenuItem {
                    text: i18n("Forget This Device")
                    onTriggered: {
                        const d = page.device(deviceRow.modelData.ubi);
                        if (d && d.adapter) {
                            d.adapter.removeDevice(d);
                        }
                    }
                }
            }
        }
    }
}
