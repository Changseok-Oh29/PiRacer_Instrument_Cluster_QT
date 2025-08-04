import QtQuick 6.4
import QtQuick.Controls 6.4

Rectangle {
    id: gearIndicator
    width: 98
    height: 47
    color: "transparent"
    
    property string currentGear: "N" // Current gear: S, D, N, P, R
    property var gearOrder: ["S", "D", "N", "P", "R"]
    property int currentIndex: gearOrder.indexOf(currentGear)
    property real centerX: 49 // Center position
    property real spacing: 24 // Increased spacing for more separation between center and side texts
    
    // Background rectangle for the highlighted gear (always in center)
    Rectangle {
        id: highlightBackground
        width: 34
        height: 45.5
        x: 32
        y: 0.672
        color: "#000000"
        visible: true
    }
    
    // Rotating gear container with wrapping effect
    Item {
        id: gearContainer
        width: parent.width
        height: 30
        y: 15
        clip: true // Hide gears outside the visible area
        
        property real rotationOffset: centerX - (currentIndex * spacing) - spacing/2
        
        Behavior on rotationOffset {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        
        Repeater {
            model: 5 // Only the 5 fundamental gears
            Item {
                id: gearWrapper
                width: spacing
                height: 30
                x: (index * spacing) + gearContainer.rotationOffset
                
                property int gearIndex: index
                property string gearText: gearOrder[gearIndex]
                property bool isCenter: gearIndex === gearIndicator.currentIndex
                property bool isVisible: x > -spacing && x < parent.width
                
                visible: isVisible
                
                Text {
                    anchors.centerIn: parent
                    width: 16
                    height: 10
                    color: parent.isCenter ? "#D2B48C" : "#FFFFFF"
                    text: parent.gearText
                    font.pixelSize: parent.isCenter ? 32 : 13
                    font.family: "Arial"
                    font.weight: Font.Bold
                    opacity: parent.isCenter ? 1.0 : 0.16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    // Move the center gear up
                    y: parent.isCenter ? -10 : 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 200 }
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                    
                    Behavior on y {
                        NumberAnimation { duration: 200 }
                    }
                }
            }
        }
    }
    
    // Animation to cycle through gears for demonstration
    SequentialAnimation {
        id: gearAnimation
        running: true
        loops: Animation.Infinite
        
        PropertyAction { target: gearIndicator; property: "currentGear"; value: "P" }
        PauseAnimation { duration: 1000 }
        
        PropertyAction { target: gearIndicator; property: "currentGear"; value: "R" }
        PauseAnimation { duration: 1000 }
        
        PropertyAction { target: gearIndicator; property: "currentGear"; value: "N" }
        PauseAnimation { duration: 1000 }
        
        PropertyAction { target: gearIndicator; property: "currentGear"; value: "D" }
        PauseAnimation { duration: 1000 }
        
        PropertyAction { target: gearIndicator; property: "currentGear"; value: "S" }
        PauseAnimation { duration: 1000 }
    }
}
