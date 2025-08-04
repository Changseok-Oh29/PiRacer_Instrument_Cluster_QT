import QtQuick 6.4

Item {
    id: vectorIcon
    
    // Public properties
    property real iconWidth: 18
    property real iconHeight: 19
    property real iconRotation: 0
    property real iconOpacity: 1.0
    property color iconColor: "#77C000"
    property color hoverColor: "#88DD00"
    property color pressedColor: "#66AA00"
    property string direction: "right" // "left", "right", "up", "down"
    property string currentState: "normal" // "normal", "hover", "pressed"

    // Set default size based on SVG dimensions
    width: iconWidth
    height: iconHeight
    
    // Simple polygon representation using Canvas
    Canvas {
        id: arrowCanvas
        width: parent.width
        height: parent.height
        rotation: vectorIcon.iconRotation
        opacity: vectorIcon.iconOpacity
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            // Scale to fit canvas
            var scaleX = width / 17.1416;
            var scaleY = height / 18.907;
            
            ctx.fillStyle = vectorIcon.iconColor;
            ctx.beginPath();
            
            // Draw the arrow shape using the exact SVG coordinates
            ctx.moveTo(0.0603714 * scaleX, 9.5969 * scaleY);
            ctx.lineTo(9.61012 * scaleX, 0.280151 * scaleY);
            ctx.lineTo(9.61145 * scaleX, 6.53237 * scaleY);
            ctx.lineTo(17.1416 * scaleX, 6.53237 * scaleY);
            ctx.lineTo(17.1416 * scaleX, 12.6543 * scaleY);
            ctx.lineTo(9.61279 * scaleX, 12.6543 * scaleY);
            ctx.lineTo(9.61412 * scaleX, 18.907 * scaleY);
            ctx.lineTo(0.0603714 * scaleX, 9.5969 * scaleY);
            ctx.closePath();
            ctx.fill();
        }
        
        // Repaint when color changes
        Component.onCompleted: requestPaint()
        
        Connections {
            target: vectorIcon
            function onIconColorChanged() { arrowCanvas.requestPaint() }
        }
    }
    
    states: [
        State {
            name: "normal_right"
            when: currentState === "normal" && direction === "right"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.iconColor
                iconRotation: 0
                iconOpacity: 1.0
            }
        },
        State {
            name: "normal_left"
            when: currentState === "normal" && direction === "left"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.iconColor
                iconRotation: 180
                iconOpacity: 1.0
            }
        },
        State {
            name: "normal_up"
            when: currentState === "normal" && direction === "up"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.iconColor
                iconRotation: -90
                iconOpacity: 1.0
            }
        },
        State {
            name: "normal_down"
            when: currentState === "normal" && direction === "down"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.iconColor
                iconRotation: 90
                iconOpacity: 1.0
            }
        },
        State {
            name: "hover_right"
            when: currentState === "hover" && direction === "right"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.hoverColor
                iconRotation: 0
                iconOpacity: 1.0
            }
        },
        State {
            name: "hover_left"
            when: currentState === "hover" && direction === "left"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.hoverColor
                iconRotation: 180
                iconOpacity: 1.0
            }
        },
        State {
            name: "hover_up"
            when: currentState === "hover" && direction === "up"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.hoverColor
                iconRotation: -90
                iconOpacity: 1.0
            }
        },
        State {
            name: "hover_down"
            when: currentState === "hover" && direction === "down"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.hoverColor
                iconRotation: 90
                iconOpacity: 1.0
            }
        },
        State {
            name: "pressed_right"
            when: currentState === "pressed" && direction === "right"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.pressedColor
                iconRotation: 0
                iconOpacity: 0.8
            }
        },
        State {
            name: "pressed_left"
            when: currentState === "pressed" && direction === "left"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.pressedColor
                iconRotation: 180
                iconOpacity: 0.8
            }
        },
        State {
            name: "pressed_up"
            when: currentState === "pressed" && direction === "up"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.pressedColor
                iconRotation: -90
                iconOpacity: 0.8
            }
        },
        State {
            name: "pressed_down"
            when: currentState === "pressed" && direction === "down"
            PropertyChanges {
                target: vectorIcon
                iconColor: vectorIcon.pressedColor
                iconRotation: 90
                iconOpacity: 0.8
            }
        }
    ]
    
    transitions: [
        Transition {
            from: "*"
            to: "*"
            ColorAnimation {
                properties: "iconColor"
                duration: 200
                easing.type: Easing.OutQuart
            }
            NumberAnimation {
                properties: "iconRotation,iconOpacity"
                duration: 300
                easing.type: Easing.OutQuart
            }
        }
    ]
    
    // Public functions
    function rotate(degrees) {
        iconRotation = degrees
    }
    
    function setOpacity(value) {
        iconOpacity = value
    }
    
    function setColor(newColor) {
        iconColor = newColor
    }
    
    // State control functions
    function setDirection(dir) {
        direction = dir
    }
    
    function setState(state) {
        currentState = state
    }
    
    function pointLeft() {
        direction = "left"
    }
    
    function pointRight() {
        direction = "right"
    }
    
    function pointUp() {
        direction = "up"
    }
    
    function pointDown() {
        direction = "down"
    }
    
    function setNormal() {
        currentState = "normal"
    }
    
    function setHover() {
        currentState = "hover"
    }
    
    function setPressed() {
        currentState = "pressed"
    }
}
