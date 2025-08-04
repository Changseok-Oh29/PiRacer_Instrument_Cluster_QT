pragma Singleton
import QtQuick 6.4

QtObject {
    readonly property int width: 1280
    readonly property int height: 400

    property string relativeFontDirectory: "fonts"

    /* Edit this comment to add your custom font */
    readonly property font font: Qt.font({
                                             family: "Arial",
                                             pixelSize: 12
                                         })
    readonly property font largeFont: Qt.font({
                                                  family: "Arial",
                                                  pixelSize: 19
                                              })

    readonly property color backgroundColor: "#c2c2c2"
}
