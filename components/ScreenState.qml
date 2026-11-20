import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar
    property bool sylvie // Sylvie's chat drawer (modules/sylvie)

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
