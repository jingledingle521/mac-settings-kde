// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

// MacSettings: the sidebar, arranged as macOS's System Settings. Each entry
// is a coloured tile (a white glyph from the icon theme on a macOS colour)
// and the KDE pages (KCM plugin ids) it covers: one page opens directly;
// several open a list of them, in sections. An entry with a `page` opens
// this app's own page instead (Mac<Page>Page.qml), with KDE's pages behind
// its Details…/Advanced… buttons. Pages that aren't installed or
// don't apply here are left out, and so are entries left with none.

.pragma library

const blue = "#0a84ff";
const red = "#ff3b30";
const pink = "#ff2d55";
const gray = "#8e8e93";
const dark = "#3a3a3c";
const green = "#34c759";
const cyan = "#32ade6";
const indigo = "#5e5ce6";
const orange = "#ff9500";

// Names macOS uses for KDE pages, in lists; others keep KDE's.
const pageNames = {
    "kcm_about-distro": "About",
    "kcm_updates": "Software Update",
    "kcm_kwallet5": "Passwords",
    "kcm_clock": "Date & Time",
    "kcm_autostart": "Login Items",
    "kcm_regionandlang": "Language & Region",
    "kcm_krdpserver": "Sharing",
    "kcm_componentchooser": "Default Apps",
    "kcm_kwinscreenedges": "Hot Corners & Screen Edges",
    "kcm_nightlight": "Night Shift",
    "kcm_kscreen": "Displays",
    "kcm_soundtheme": "Sound Effects",
    "kcm_cursortheme": "Pointer",
    "kcm_keys": "Keyboard Shortcuts",
    "kcm_plasmasearch": "Spotlight",
    "kcm_kwinxwayland": "Legacy X11 Apps",
    "kcm_feedback": "Analytics",
};

// Groups, separated by space in the sidebar, in macOS's order (macOS 26).
// KDE pages go where macOS keeps the same settings: the default browser in
// Desktop & Dock, alert sounds in Sound, the pointer and motion in
// Accessibility, passwords in General, spelling in Keyboard. Hardware macOS
// has no pane for comes last, where macOS lists other makers' panes.
const groups = [
    [
        { key: "wifi", name: "Wi‑Fi", glyph: "network-wireless-symbolic", color: blue, page: "wifi", sections: [["kcm_networkmanagement"]] },
        { key: "bluetooth", name: "Bluetooth", glyph: "bluetooth-symbolic", color: blue, page: "bluetooth", sections: [["kcm_bluetooth"]] },
        { key: "network", name: "Network", glyph: "globe-symbolic", color: blue, sections: [
            ["kcm_networkmanagement", "kcm_proxy", "kcm_netpref"],
        ] },
        { key: "battery", name: "Battery", glyph: "battery-full-symbolic", color: green, sections: [["kcm_powerdevilprofilesconfig"]] },
    ],
    [
        { key: "general", name: "General", glyph: "settings-configure-symbolic", color: gray, sections: [
            ["kcm_about-distro", "kcm_updates"],
            ["kcm_kwallet5", "kcm_clock", "kcm_regionandlang", "kcm_autostart", "kcm_kded", "kcm_krdpserver"],
            ["kcm_filetypes", "kcm_desktoppaths", "kcm_smserver", "kcm_qtquicksettings"],
        ] },
        { key: "accessibility", name: "Accessibility", glyph: "preferences-desktop-accessibility-symbolic", color: blue, sections: [
            ["kcm_access"],
            ["kcm_cursortheme", "kcm_animations"],
        ] },
        { key: "appearance", name: "Appearance", glyph: "contrast-symbolic", color: dark, sections: [
            ["kcm_colors", "kcm_lookandfeel", "kcm_nighttime"],
            ["kcm_icons", "kcm_style", "kcm_desktoptheme", "kcm_kwindecoration"],
            ["kcm_fonts", "kcm_fontinst"],
        ] },
        { key: "desktop", name: "Desktop & Dock", glyph: "dock-symbolic", color: dark, sections: [
            ["kcm_workspace", "kcm_componentchooser"],
            ["kcm_kwinoptions", "kcm_kwintabbox", "kcm_kwinrules"],
            ["kcm_kwin_virtualdesktops", "kcm_activities", "kcm_kwinscreenedges", "kcm_kwintouchscreen"],
            ["kcm_kwin_effects", "kcm_kwin_scripts"],
        ] },
        { key: "displays", name: "Displays", glyph: "display-brightness-symbolic", color: blue, sections: [
            ["kcm_kscreen", "kcm_nightlight", "kcm_colord"],
        ] },
        { key: "spotlight", name: "Spotlight", glyph: "system-search-symbolic", color: gray, sections: [
            ["kcm_plasmasearch", "kcm_baloofile", "kcm_webshortcuts"],
        ] },
        { key: "wallpaper", name: "Wallpaper", glyph: "preferences-desktop-wallpaper-symbolic", color: cyan, sections: [["kcm_wallpaper"]] },
    ],
    [
        { key: "notifications", name: "Notifications", glyph: "notification-symbolic", color: red, sections: [["kcm_notifications"]] },
        { key: "sound", name: "Sound", glyph: "audio-volume-high-symbolic", color: pink, sections: [
            ["kcm_pulseaudio"],
            ["kcm_soundtheme"],
        ] },
    ],
    [
        { key: "lockscreen", name: "Lock Screen", glyph: "system-lock-screen-symbolic", color: dark, sections: [
            ["kcm_screenlocker", "kcm_plasmalogin", "kcm_splashscreen"],
        ] },
        { key: "privacy", name: "Privacy & Security", glyph: "hand-symbolic", color: blue, sections: [
            ["kcm_app-permissions", "kcm_kwinxwayland"],
            ["kcm_recentFiles", "kcm_feedback"],
        ] },
        { key: "users", name: "Users & Groups", glyph: "system-users-symbolic", color: blue, sections: [["kcm_users"]] },
    ],
    [
        { key: "accounts", name: "Internet Accounts", glyph: "mail-message-symbolic", color: blue, sections: [["kcm_kaccounts"]] },
    ],
    [
        { key: "keyboard", name: "Keyboard", glyph: "input-keyboard-symbolic", color: gray, sections: [
            ["kcm_keyboard", "kcm_keys"],
            ["kcmspellchecking"],
            ["kcm_virtualkeyboard", "kcm_plasmakeyboard"],
        ] },
        { key: "mouse", name: "Mouse", glyph: "input-mouse-symbolic", color: gray, sections: [["kcm_mouse"]] },
        { key: "trackpad", name: "Trackpad", glyph: "input-touchpad-symbolic", color: gray, sections: [["kcm_touchpad"]] },
        { key: "games", name: "Game Controllers", glyph: "input-gaming-symbolic", color: gray, sections: [["kcm_gamecontroller"]] },
        { key: "printers", name: "Printers & Scanners", glyph: "printer-symbolic", color: gray, sections: [["kcm_printer_manager"]] },
    ],
    [
        { key: "tablet", name: "Drawing Tablet", glyph: "input-tablet-symbolic", color: indigo, sections: [["kcm_tablet"]] },
        { key: "touchscreen", name: "Touchscreen", glyph: "input-tablet-symbolic", color: indigo, sections: [["kcm_touchscreen"]] },
        { key: "thunderbolt", name: "Thunderbolt", glyph: "emblem-system-symbolic", color: orange, sections: [["kcm_bolt"]] },
        { key: "disks", name: "Disks & Cameras", glyph: "drive-removable-media-symbolic", color: orange, sections: [
            ["kcm_device_automounter", "kcm_solid_actions", "kcm_kamera"],
        ] },
        { key: "audiocd", name: "Audio CDs", glyph: "media-optical-symbolic", color: orange, sections: [["kcm_audiocd", "kcm_cddb"]] },
    ],
];

// `has(id)` tells whether a page is available. Returns the groups with
// unavailable pages, empty sections and empty entries removed; each entry
// gains `group` (its group's number) and `modules` (all its pages).
function available(has) {
    const result = [];
    groups.forEach((group, g) => {
        for (const entry of group) {
            const sections = entry.sections
                .map(section => section.filter(id => has(id)))
                .filter(section => section.length > 0);
            if (sections.length === 0) {
                continue;
            }
            const modules = [].concat(...sections);
            result.push(Object.assign({}, entry, { group: g, sections: sections, modules: modules }));
        }
    });
    return result;
}
