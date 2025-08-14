import QtQuick 6.4
import QtQuick.Controls 6.4
import UntitledProject

Rectangle {
    id: batteryBar
    width: 548
    height: 24
    color: "transparent"
    
    property int batteryLevel: 100 // Battery level from 0-100
    property color batteryColor: "#77C000" // Default green color
    property bool useRealData: true // Set to false to use demo animation

    // Animation to cycle battery level from 100 to 0 and back to 100 (for demo purposes)
    SequentialAnimation {
        id: batteryAnimation
        running: !useRealData
        loops: Animation.Infinite
        
        NumberAnimation {
            target: batteryBar
            property: "batteryLevel"
            from: 100
            to: 0
            duration: 3000 // 3 seconds to go from 100 to 0
            easing.type: Easing.InOutQuad
        }
        
        NumberAnimation {
            target: batteryBar
            property: "batteryLevel"
            from: 0
            to: 100
            duration: 3000 // 3 seconds to go from 0 to 100
            easing.type: Easing.InOutQuad
        }
    }

    states: [
        State {
            name: "critical"
            when: batteryLevel < 20
            PropertyChanges { target: batteryBar; batteryColor: "#F44336" }
        },
        State {
            name: "low"
            when: batteryLevel >= 20 && batteryLevel <= 40
            PropertyChanges { target: batteryBar; batteryColor: "#FF9800" }
        },
        State {
            name: "medium"
            when: batteryLevel > 40 && batteryLevel <= 70
            PropertyChanges { target: batteryBar; batteryColor: "#FFEB3B" }
        },
        State {
            name: "normal"
            when: batteryLevel > 70
            PropertyChanges { target: batteryBar; batteryColor: "#77C000" }
        }
    ]

    // Battery percentage indicator (%)
    Text {
        id: percentageSymbol
        x: 17.5
        y: 10.7
        width: 5
        height: 6.3
        color: "#FFFFFF"
        text: "%"
        font.pixelSize: 4
        font.family: "Arial"
        font.weight: Font.Bold
        opacity: 0.32
    }

    // Battery fill area - dashed rectangles that fill continuously like a bar
    Repeater {
        model: 25
        Rectangle {
            x: 29.45 + index * 18
            y: 10.69
            width: 17
            height: 6
            color: batteryLevel >= (index + 1) * 4 ? batteryBar.batteryColor : "transparent"
        }
    }

    Text {
        id: text3
        x: 506
        y: 0
        width: 42
        height: 24
        color: batteryBar.batteryColor
        text: batteryLevel + "%"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: "Arial"
        font.weight: Font.Bold
    }
}
