/*
    SPDX-FileCopyrightText: 2026 Brhett

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <QPointer>
#include <QRegion>

class KWindowShadow;
class QMainWindow;
class QWidget;

/**
 * MacSettings: macOS's System Settings window. No title bar: a rounded,
 * shadowed window whose glass sidebar runs to the top (the stoplights are
 * drawn by the sidebar's QML), with KWin blurring behind the sidebar.
 * The window is moved from empty space at the top (SidebarMode::startMove)
 * and resized from its edges.
 */
class SettingsChrome : public QObject
{
    Q_OBJECT

public:
    explicit SettingsChrome(QMainWindow *window);
    ~SettingsChrome() override;

    /** The sidebar: glass behind it, and the hairline after it. */
    void setSidebar(QWidget *sidebar);

    bool isMaximized() const;
    int radius() const;

    /** Translucent tint of the sidebar (KWin blurs behind it). */
    static QColor sidebarColor();
    /** The content side's background. */
    QColor contentColor() const;

Q_SIGNALS:
    void activeChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    Qt::Edges edgesAt(const QPointF &pos) const;
    void paintBackground();
    void updateWindowEffects();
    void updateShadow();

    QMainWindow *m_window;
    QPointer<QWidget> m_sidebar;
    KWindowShadow *m_shadow = nullptr;
    Qt::Edges m_cursorEdges;
    QRegion m_appliedBlur;
    bool m_blurApplied = false;
    bool m_surfaceReady = false;
};
