/*
 *   SPDX-FileCopyrightText: 2009 Ben Cooksley <bcooksley@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef SIDEBARMODE_H
#define SIDEBARMODE_H

#include <KSelectionProxyModel>

#include <QIcon>
#include <QWidget>
#include <qqmlregistration.h>

class ModuleView;
class KAboutData;
class QModelIndex;
class QAbstractItemView;
class QAbstractItemModel;
class QAction;
class SidebarMode;
class SettingsChrome;
class MenuItem;
class KActionCollection;

class FocusHackWidget : public QWidget
{
    Q_OBJECT
public:
    explicit FocusHackWidget(QWidget *parent = nullptr);
    ~FocusHackWidget() override;

public Q_SLOTS:
    void focusNext();
    void focusPrevious();
};

class SubcategoryModel : public KSelectionProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QIcon icon READ icon NOTIFY iconChanged)
    Q_PROPERTY(bool categoryOwnedByKCM READ categoryOwnedByKCM NOTIFY categoryOwnedByKCMChanged)

public:
    explicit SubcategoryModel(QAbstractItemModel *parentModel, SidebarMode *parent = nullptr);

    QString title() const;
    QIcon icon() const;
    bool categoryOwnedByKCM() const;

    void setParentIndex(const QModelIndex &activeModule);

    Q_INVOKABLE void loadParentCategoryModule();

Q_SIGNALS:
    void titleChanged();
    void iconChanged();
    void categoryOwnedByKCMChanged();

private:
    QAbstractItemModel *m_parentModel;
    SidebarMode *m_sidebarMode;
    QPersistentModelIndex m_activeModuleIndex;
};

class SidebarMode : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Not creatable, use the systemsettings attached property")

    Q_PROPERTY(QAbstractItemModel *categoryModel READ categoryModel CONSTANT)
    Q_PROPERTY(QAbstractItemModel *searchModel READ searchModel CONSTANT)
    Q_PROPERTY(QAbstractItemModel *subCategoryModel READ subCategoryModel CONSTANT)
    Q_PROPERTY(int activeCategoryRow READ activeCategoryRow NOTIFY activeCategoryRowChanged)
    Q_PROPERTY(int activeSearchRow READ activeSearchRow NOTIFY activeSearchRowChanged)
    Q_PROPERTY(int activeSubCategoryRow READ activeSubCategoryRow NOTIFY activeSubCategoryRowChanged)
    Q_PROPERTY(int width READ width NOTIFY widthChanged)
    Q_PROPERTY(bool actionMenuVisible READ actionMenuVisible NOTIFY actionMenuVisibleChanged)
    Q_PROPERTY(bool defaultsIndicatorsVisible READ defaultsIndicatorsVisible NOTIFY defaultsIndicatorsVisibleChanged)
    Q_PROPERTY(qreal headerHeight READ headerHeight WRITE setHeaderHeight NOTIFY headerHeightChanged)
    // TODO Plasma 6.6 use new Kirigami api instead
    Q_PROPERTY(qreal devicePixelRatio READ devicePixelRatio NOTIFY devicePixelRatioChanged)
    // MacSettings: the Mac sidebar picks pages by plugin id rather than by
    // KDE's category tree. The open page, the grouped entry whose list of
    // pages is showing (or was, before one of them was opened), and whether
    // there is a list to go back to.
    Q_PROPERTY(QString activeModuleId READ activeModuleId NOTIFY activeModuleIdChanged)
    Q_PROPERTY(QVariantMap landing READ landing NOTIFY landingChanged)
    Q_PROPERTY(bool landingShown READ landingShown NOTIFY landingChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY landingChanged)
    // MacSettings: the window has no title bar; the sidebar draws the
    // stoplights (grayed while inactive) and moves the window.
    Q_PROPERTY(bool windowActive READ windowActive NOTIFY windowActiveChanged)
    Q_PROPERTY(bool windowMaximized READ windowMaximized NOTIFY windowActiveChanged)

public:
    enum ApplicationMode {
        SystemSettings = 0,
        InfoCenter,
    };
    Q_ENUM(ApplicationMode)

    SidebarMode(QObject *parent,
                ApplicationMode mode,
                const QString &startupModule,
                const QStringList &startupModuleArgs,
                KActionCollection *actions,
                MenuItem *homeItem,
                MenuItem *rootItem);
    ~SidebarMode() override;
    QWidget *mainWidget();
    void initEvent();
    Q_INVOKABLE void giveFocus();
    ModuleView *moduleView() const;
    void reloadStartupModule();

    QAbstractItemModel *categoryModel() const;
    QAbstractItemModel *searchModel() const;
    QAbstractItemModel *subCategoryModel() const;

    int activeCategoryRow() const;
    int activeSubCategoryRow() const;
    int activeSearchRow() const;

    int width() const;

    bool actionMenuVisible() const;

    qreal headerHeight() const;
    void setHeaderHeight(qreal height);

    qreal devicePixelRatio() const;

    bool defaultsIndicatorsVisible() const;
    void toggleDefaultsIndicatorsVisibility();

    void toggleShowIrrelevantModules();

    Q_INVOKABLE QAction *action(const QString &name) const;
    // QML doesn't understand QIcon, otherwise we could get it from the QAction itself
    Q_INVOKABLE QString actionIconName(const QString &name) const;
    Q_INVOKABLE QString actionIconName(const QAction *action) const;
    Q_INVOKABLE void showActionMenu(const QPoint &position);

    Q_INVOKABLE void loadModule(const QModelIndex &activeModule, const QStringList &args = QStringList());

    /**
     * Helper function to move focus to the next/previous QQuickWidget
     */
    Q_INVOKABLE void focusNext();
    Q_INVOKABLE void focusPrevious();

    // MacSettings: pages by plugin id.
    QString activeModuleId() const;
    QVariantMap landing() const;
    bool landingShown() const;
    bool canGoBack() const;
    /** Whether the page is installed and relevant here (a touchpad page
     *  without a touchpad isn't). */
    Q_INVOKABLE bool hasModule(const QString &pluginId) const;
    /** name, icon, comment */
    Q_INVOKABLE QVariantMap moduleInfo(const QString &pluginId) const;
    /** Opens a page straight from the sidebar. */
    Q_INVOKABLE void openModule(const QString &pluginId);
    /** Shows a grouped entry's list of pages (`entry` as the sidebar has it:
     *  key, name, sections). */
    Q_INVOKABLE void openLanding(const QVariantMap &entry);
    /** Opens a page from the list; back returns to the list. */
    Q_INVOKABLE void openFromLanding(const QString &pluginId);
    Q_INVOKABLE void goBack();
    /** For checking without clicking: the sidebar entry to open at startup
     *  (MAC_TEST_ENTRY, e.g. "wifi"), or empty. */
    Q_INVOKABLE QString testEntry() const;
    /** The names pages go by here (plugin id → name), for their titles. */
    Q_INVOKABLE void setPageTitles(const QVariantMap &titles);
    /** MAC_TEST_TOUR=<dir>: the sidebar visits every page and saves a
     *  picture of the window for each (testShot), then quits. */
    Q_INVOKABLE QString testTour() const;
    /** MAC_TEST_TOUR_ONLY=<pictures,…>: just these (as named by the tour). */
    Q_INVOKABLE QStringList testTourOnly() const;
    Q_INVOKABLE void testShot(const QString &name);

    // MacSettings: window controls.
    QWidget *sidebarWidget() const;
    void setChrome(SettingsChrome *chrome);
    bool windowActive() const;
    bool windowMaximized() const;
    Q_INVOKABLE void closeWindow();
    Q_INVOKABLE void minimizeWindow();
    Q_INVOKABLE void toggleMaximized();
    Q_INVOKABLE void startMove();

    void setStartupModule(const QString &startupModule);
    QString startupModule() const;

    void setStartupModuleArgs(const QStringList &startupModuleArgs);
    QStringList startupModuleArgs() const;

    void retranslateQml();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private Q_SLOTS:
    void moduleLoaded();
    void updateDefaults();
    void initWidget();

private:
    void initPlaceHolderWidget();
    void updateModelMenuItem(MenuItem *item);
    void updateCategoryModel(const QModelIndex &categoryIdx);
    void refreshDefaults();
    void setActionMenuVisible(bool visible);
    MenuItem *rootItem() const;
    MenuItem *homeItem() const;

Q_SIGNALS:
    void activeModuleIdChanged();
    void landingChanged();
    void windowActiveChanged();
    void activeCategoryRowChanged();
    void activeSubCategoryRowChanged();
    void activeSearchRowChanged();
    void widthChanged();
    void actionMenuVisibleChanged();
    void headerHeightChanged();
    void devicePixelRatioChanged();
    void defaultsIndicatorsVisibleChanged();
    void viewChanged(bool state);

private:
    class Private;
    Private *const d;
};

#endif
