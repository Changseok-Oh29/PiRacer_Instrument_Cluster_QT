// Example usage of VectorIcon component with states
import QtQuick 6.4

Rectangle {
    id: exampleScreen
    width: 600
    height: 500
    color: "#f0f0f0"
    
    Column {
        anchors.centerIn: parent
        spacing: 30
        
        Text {
            text: "Vector Icon with States Examples"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // Direction examples
        Row {
            spacing: 40
            anchors.horizontalCenter: parent.horizontalCenter
            
            Column {
                spacing: 10
                VectorIcon {
                    id: rightArrow
                    direction: "right"
                    iconWidth: 32
                    iconHeight: 34
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Right Arrow"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            Column {
                spacing: 10
                VectorIcon {
                    id: leftArrow
                    direction: "left"
                    iconWidth: 32
                    iconHeight: 34
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Left Arrow"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            Column {
                spacing: 10
                VectorIcon {
                    id: upArrow
                    direction: "up"
                    iconWidth: 32
                    iconHeight: 34
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Up Arrow"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            Column {
                spacing: 10
                VectorIcon {
                    id: downArrow
                    direction: "down"
                    iconWidth: 32
                    iconHeight: 34
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Down Arrow"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        
        // Interactive state examples
        Row {
            spacing: 40
            anchors.horizontalCenter: parent.horizontalCenter
            
            Column {
                spacing: 10
                VectorIcon {
                    id: hoverIcon
                    currentState: "hover"
                    iconWidth: 28
                    iconHeight: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Hover State"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            Column {
                spacing: 10
                VectorIcon {
                    id: pressedIcon
                    currentState: "pressed"
                    iconWidth: 28
                    iconHeight: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Pressed State"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        
        // Interactive demo
        Column {
            spacing: 15
            anchors.horizontalCenter: parent.horizontalCenter
            
            VectorIcon {
                id: interactiveIcon
                iconWidth: 40
                iconHeight: 42
                anchors.horizontalCenter: parent.horizontalCenter
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    onEntered: interactiveIcon.setHover()
                    onExited: interactiveIcon.setNormal()
                    onPressed: interactiveIcon.setPressed()
                    onReleased: interactiveIcon.setHover()
                    onClicked: {
                        // Cycle through directions
                        if (interactiveIcon.direction === "right") {
                            interactiveIcon.pointDown()
                        } else if (interactiveIcon.direction === "down") {
                            interactiveIcon.pointLeft()
                        } else if (interactiveIcon.direction === "left") {
                            interactiveIcon.pointUp()
                        } else {
                            interactiveIcon.pointRight()
                        }
                    }
                }
            }
            
            Text {
                text: "Interactive: Hover, click to rotate"
                font.pixelSize: 12
                color: "#666666"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        // Animation demo
        Row {
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter
            
            VectorIcon {
                id: animatedIcon
                iconWidth: 36
                iconHeight: 38
                
                SequentialAnimation on direction {
                    loops: Animation.Infinite
                    running: true
                    
                    PropertyAction { value: "right" }
                    PauseAnimation { duration: 800 }
                    PropertyAction { value: "down" }
                    PauseAnimation { duration: 800 }
                    PropertyAction { value: "left" }
                    PauseAnimation { duration: 800 }
                    PropertyAction { value: "up" }
                    PauseAnimation { duration: 800 }
                }
            }
            
            Text {
                text: "Auto-rotating"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
