// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// MacSettings: lays a page's Kirigami.FormLayout out as macOS's System
// Settings lays out a form: each run of rows between section breaks sits on
// a rounded panel, section titles and labels are left-aligned, and the
// separator lines give way to the gaps between panels.
//
// ModuleView creates one for every FormLayout on a page, inside the form's
// own hidden helper item (its second child, at the form's top-left and
// outside its grid), so it draws in the form's coordinates without becoming
// a row. It reads the form's private parts (its grid, `knownItems` and
// `buddies`) and restyles them; if a Kirigami update renames those, it
// draws nothing and the form looks as stock.
Item {
    id: decorator

    required property Item form
    readonly property Item grid: form && form.children.length > 0 ? form.children[0] : null
    readonly property real pad: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
    property var rects: []
    // A top margin was given to a form flush with its page's top.
    property bool roomMade: false
    // Rows already watched for moves.
    property var watched: []

    function isSection(item: Item): bool {
        return item && item.Kirigami.FormData.isSection;
    }

    // Labels and titles to the left, separators hidden, sections spaced.
    function restyle() {
        if (!grid || !grid.knownItems) {
            return;
        }
        for (const child of grid.children) {
            const item = child.item;
            if (!item) {
                continue; // the grid's placeholders
            }
            if (child instanceof Text) {
                // A label (Kirigami.Heading).
                const vertical = child.Layout.alignment & (Qt.AlignTop | Qt.AlignBottom | Qt.AlignVCenter | Qt.AlignBaseline);
                child.Layout.alignment = Qt.AlignLeft | (vertical || Qt.AlignVCenter);
                if (isSection(item)) {
                    child.Layout.bottomMargin = pad;
                }
            } else if (isSection(item)) {
                // The section's own row (a separator, or an empty item).
                child.Layout.topMargin = pad;
                child.Layout.bottomMargin = pad;
                if (item.Kirigami.FormData.label.length === 0) {
                    item.opacity = 0;
                }
            }
        }
        for (const item of grid.knownItems) {
            if (item && watched.indexOf(item) < 0) {
                watched.push(item);
                item.yChanged.connect(timer.restart);
                item.heightChanged.connect(timer.restart);
                item.visibleChanged.connect(timer.restart);
            }
        }
        timer.restart();
    }

    // One panel per run of visible rows between section breaks.
    function update() {
        if (!grid || !grid.knownItems || !grid.buddies) {
            rects = [];
            return;
        }
        const groups = [];
        let current = null;
        for (let i = 0; i < grid.knownItems.length; ++i) {
            const item = grid.knownItems[i];
            if (!item) {
                continue;
            }
            if (isSection(item)) {
                current = null;
                continue;
            }
            if (!item.visible || item.height <= 0) {
                continue;
            }
            const buddy = grid.buddies[i];
            let top = item.y;
            let bottom = item.y + item.height;
            if (buddy && buddy.visible && buddy.text.length > 0) {
                top = Math.min(top, buddy.y + grid.y);
                bottom = Math.max(bottom, buddy.y + grid.y + buddy.height);
            }
            if (!current) {
                current = { top: top, bottom: bottom };
                groups.push(current);
            } else {
                current.top = Math.min(current.top, top);
                current.bottom = Math.max(current.bottom, bottom);
            }
        }
        // A form flush with the top of its page would push the first
        // panel out of view: give the form room above it instead (as its
        // layout's margin, or else by lowering the panels' reach).
        let topReach = pad;
        if (groups.length > 0 && groups[0].top - pad < 0) {
            if (!roomMade && form.Layout) {
                roomMade = true;
                form.Layout.topMargin = form.Layout.topMargin + pad;
                form.Layout.bottomMargin = form.Layout.bottomMargin + pad;
            }
            topReach = Math.max(2, groups[0].top);
        }
        rects = groups.map((g, i) => ({
            x: grid.x - pad,
            y: g.top - (i === 0 ? topReach : pad),
            width: grid.width + 2 * pad,
            height: g.bottom - g.top + pad + (i === 0 ? topReach : pad)
        }));
    }

    Timer {
        id: timer
        interval: 0
        onTriggered: decorator.update()
    }

    Connections {
        target: decorator.grid
        function onImplicitHeightChanged() { timer.restart(); }
        function onWidthChanged() { timer.restart(); }
        function onXChanged() { timer.restart(); }
        function onKnownItemsChanged() { decorator.restyle(); }
    }

    Component.onCompleted: restyle()

    Repeater {
        model: decorator.rects
        delegate: Rectangle {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
            radius: 10
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        }
    }
}
