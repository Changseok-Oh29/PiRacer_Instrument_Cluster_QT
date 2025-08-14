

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick 6.4
import QtQuick.Controls 6.4
import UntitledProject
import QtQuick.Layouts 1.3
import content

Rectangle {
    id: rectangle
    width: Constants.width
    height: Constants.height
    color: "#000000"

    // Properties for dynamic values - sourced from CAN data
    property int currentSpeed: 0
    property int currentRpm: 0
    property string currentGear: "N"
    property bool canDataAvailable: dashboardDataCAN.canConnected
    
    // Battery data from DBus
    property int currentBatteryLevel: Math.round(dashboardDataDBus.batteryLevel)
    
    // Animated properties for smooth transitions
    property real animatedSpeed: 0
    property real animatedRpm: 0
    
    // Smooth animation for speed changes
    Behavior on animatedSpeed {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }
    
    // Smooth animation for RPM changes
    Behavior on animatedRpm {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuad
        }
    }
    
    // One Euro Filter properties for adaptive smoothing
    property real minCutoff: 1.0      // Minimum cutoff frequency (Hz) - controls baseline smoothing
    property real beta: 0.1           // Cutoff slope - how much filtering adapts to speed of change
    property real derivateCutoff: 1.0 // Cutoff for derivative calculation
    
    // Speed filter state
    property real speedFilterState: 0
    property real speedDerivativeState: 0
    property real speedPreviousTime: 0
    
    // RPM filter state  
    property real rpmFilterState: 0
    property real rpmDerivativeState: 0
    property real rpmPreviousTime: 0
    
    // Low-pass filter function
    function lowPassFilter(current, previous, alpha) {
        return alpha * current + (1.0 - alpha) * previous
    }
    
    // Calculate smoothing factor (alpha) from cutoff frequency and time delta
    function calculateAlpha(cutoff, dt) {
        if (dt <= 0) return 1.0
        var tau = 1.0 / (2.0 * Math.PI * cutoff)
        return 1.0 / (1.0 + tau / dt)
    }
    
    // One Euro Filter for speed
    function oneEuroFilterSpeed(value, timestamp) {
        if (speedPreviousTime === 0) {
            // First sample - initialize
            speedFilterState = value
            speedDerivativeState = 0
            speedPreviousTime = timestamp
            return value
        }
        
        var dt = (timestamp - speedPreviousTime) / 1000.0 // Convert ms to seconds
        speedPreviousTime = timestamp
        
        if (dt <= 0) return speedFilterState // Avoid division by zero
        
        // Calculate derivative (rate of change)
        var derivative = (value - speedFilterState) / dt
        
        // Smooth the derivative
        var derivativeAlpha = calculateAlpha(derivateCutoff, dt)
        speedDerivativeState = lowPassFilter(derivative, speedDerivativeState, derivativeAlpha)
        
        // Calculate adaptive cutoff frequency
        var adaptiveCutoff = minCutoff + beta * Math.abs(speedDerivativeState)
        
        // Apply main filter with adaptive cutoff
        var alpha = calculateAlpha(adaptiveCutoff, dt)
        speedFilterState = lowPassFilter(value, speedFilterState, alpha)
        
        // Debug logging
        console.log("Speed OneEuro - Raw:", value, "Filtered:", speedFilterState.toFixed(1), "Derivative:", speedDerivativeState.toFixed(1), "Cutoff:", adaptiveCutoff.toFixed(2))
        
        return Math.round(speedFilterState)
    }
    
    // One Euro Filter for RPM
    function oneEuroFilterRpm(value, timestamp) {
        if (rpmPreviousTime === 0) {
            // First sample - initialize
            rpmFilterState = value
            rpmDerivativeState = 0
            rpmPreviousTime = timestamp
            return value
        }
        
        var dt = (timestamp - rpmPreviousTime) / 1000.0 // Convert ms to seconds
        rpmPreviousTime = timestamp
        
        if (dt <= 0) return rpmFilterState // Avoid division by zero
        
        // Calculate derivative (rate of change)
        var derivative = (value - rpmFilterState) / dt
        
        // Smooth the derivative
        var derivativeAlpha = calculateAlpha(derivateCutoff, dt)
        rpmDerivativeState = lowPassFilter(derivative, rpmDerivativeState, derivativeAlpha)
        
        // Calculate adaptive cutoff frequency
        var adaptiveCutoff = minCutoff + beta * Math.abs(rpmDerivativeState)
        
        // Apply main filter with adaptive cutoff
        var alpha = calculateAlpha(adaptiveCutoff, dt)
        rpmFilterState = lowPassFilter(value, rpmFilterState, alpha)
        
        // Debug logging
        console.log("RPM OneEuro - Raw:", value, "Filtered:", rpmFilterState.toFixed(1), "Derivative:", rpmDerivativeState.toFixed(1), "Cutoff:", adaptiveCutoff.toFixed(2))
        
        var result = Math.round(rpmFilterState)
        return result < 50 ? 0 : result  // Consider anything below 50 RPM as stopped
    }

    // Timer to continuously sample CAN data regardless of value changes
    Timer {
        id: canDataTimer
        interval: 100  // Sample every 100ms (10Hz)
        running: dashboardDataCAN.canConnected
        repeat: true
        onTriggered: {
            if (dashboardDataCAN.canConnected) {
                var currentTime = Date.now()
                
                // Apply One Euro Filter to both speed and RPM
                var newSmoothedSpeed = rectangle.oneEuroFilterSpeed(dashboardDataCAN.currentSpeed, currentTime)
                var newSmoothedRpm = rectangle.oneEuroFilterRpm(dashboardDataCAN.currentRpm, currentTime)
                
                // Update our properties if the smoothed values changed
                if (rectangle.currentSpeed !== newSmoothedSpeed) {
                    rectangle.currentSpeed = newSmoothedSpeed
                    rectangle.animatedSpeed = rectangle.currentSpeed  // Trigger smooth animation
                }
                
                if (rectangle.currentRpm !== newSmoothedRpm) {
                    rectangle.currentRpm = newSmoothedRpm
                    rectangle.animatedRpm = rectangle.currentRpm  // Trigger smooth animation
                }
                
                console.log("CAN sample - Raw Speed:", dashboardDataCAN.currentSpeed, "Filtered:", rectangle.currentSpeed, "Raw RPM:", dashboardDataCAN.currentRpm, "Filtered:", rectangle.currentRpm)
            }
        }
    }

    // Handle CAN connection status changes
    Connections {
        target: dashboardDataCAN
        function onCanConnectedChanged() {
            console.log("Screen01 CAN connection changed to:", dashboardDataCAN.canConnected)
            if (dashboardDataCAN.canConnected) {
                // Reset One Euro Filter state when connecting
                rectangle.speedFilterState = 0
                rectangle.speedDerivativeState = 0
                rectangle.speedPreviousTime = 0
                rectangle.rpmFilterState = 0
                rectangle.rpmDerivativeState = 0
                rectangle.rpmPreviousTime = 0
                // Timer will start automatically due to running: binding
                console.log("Screen01 CAN connected - reset One Euro Filter state")
            } else {
                // Clear everything when disconnected
                rectangle.speedFilterState = 0
                rectangle.speedDerivativeState = 0
                rectangle.speedPreviousTime = 0
                rectangle.rpmFilterState = 0
                rectangle.rpmDerivativeState = 0
                rectangle.rpmPreviousTime = 0
                rectangle.currentSpeed = 0
                rectangle.currentRpm = 0
                rectangle.animatedSpeed = 0
                rectangle.animatedRpm = 0
                console.log("Screen01 CAN disconnected - cleared all data")
            }
        }
    }

    // Debug the binding
    onCurrentSpeedChanged: console.log("Screen01 currentSpeed changed to:", currentSpeed, "(smoothed)", "CAN connected:", dashboardDataCAN.canConnected, "Raw CAN speed:", dashboardDataCAN.currentSpeed)
    onCurrentRpmChanged: console.log("Screen01 currentRpm changed to:", currentRpm, "(smoothed)", "CAN connected:", dashboardDataCAN.canConnected, "Raw CAN RPM:", dashboardDataCAN.currentRpm)
    onCanDataAvailableChanged: console.log("Screen01 canDataAvailable changed to:", canDataAvailable)
    onCurrentBatteryLevelChanged: console.log("Screen01 battery level changed to:", currentBatteryLevel + "%")

    // Debug timer to check binding status and One Euro Filter state
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            console.log("DEBUG - Screen01 One Euro Filter and animation status:")
            console.log("  dashboardDataCAN.canConnected:", dashboardDataCAN.canConnected)
            console.log("  Raw CAN Speed:", dashboardDataCAN.currentSpeed, "Filtered:", rectangle.currentSpeed, "Animated:", Math.round(rectangle.animatedSpeed))
            console.log("  Raw CAN RPM:", dashboardDataCAN.currentRpm, "Filtered:", rectangle.currentRpm, "Animated:", Math.round(rectangle.animatedRpm))
            console.log("  Speed filter state:", rectangle.speedFilterState.toFixed(1), "derivative:", rectangle.speedDerivativeState.toFixed(1))
            console.log("  RPM filter state:", rectangle.rpmFilterState.toFixed(1), "derivative:", rectangle.rpmDerivativeState.toFixed(1))
        }
    }

    // Weather data component
    WeatherData {
        id: weatherData
    }

    // CAN data component for real vehicle data
    DashboardDataCAN {
        id: dashboardDataCAN
    }
    
    // DBus data component for battery and other PiRacer data
    DashboardDataDBus {
        id: dashboardDataDBus
    }

    Image {
        id: group1
        x: 156
        y: 17
        source: "images/Group 1.svg"
        fillMode: Image.PreserveAspectFit

        Image {
            id: group4
            x: -9
            y: 40
            source: "images/Group 4.svg"
            fillMode: Image.PreserveAspectFit

            Image {
                id: vector6
                x: 600
                y: 257
                source: "images/Vector 6.svg"
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: vector7
                x: 251
                y: 257
                source: "images/Vector 7.svg"
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    Image {
        id: subtract
        x: 156
        y: 18
        source: "images/Subtract.svg"
        fillMode: Image.PreserveAspectFit

        Text {
            id: text1
            x: 431
            y: 98
            width: implicitWidth
            height: 88
            color: "#bebebe"
            text: Math.round(rectangle.animatedSpeed).toString()
            font.pixelSize: 90
            anchors.verticalCenterOffset: -41
            anchors.horizontalCenterOffset: 0
            font.weight: Font.Bold
            font.bold: false
            font.family: "Arial"
            anchors.centerIn: parent
        }

        // Left arrow - decrease value
        VectorIcon {
            id: leftArrow
            x: 401
            y: 66
            rotation: 180
            iconWidth: 24
            iconHeight: 26
            direction: "left"
            iconColor: "#77C000"
            hoverColor: "#88DD00"
            pressedColor: "#66AA00"

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 0
                anchors.bottomMargin: 0
                anchors.leftMargin: 0
                anchors.topMargin: 0
                rotation: 180
                hoverEnabled: true

                onEntered: leftArrow.currentState = "hover"
                onExited: leftArrow.currentState = "normal"
                onPressed: leftArrow.currentState = "pressed"
                onReleased: leftArrow.currentState = "hover"
                
                onClicked: {
                    // Manual control removed - data now comes from CAN bus only
                    console.log("Manual speed control disabled - using CAN data only")
                }
            }
        }

        // Right arrow - increase value
        VectorIcon {
            id: rightArrow
            x: 544
            y: 66
            rotation: 180
            iconWidth: 24
            iconHeight: 26
            direction: "right"
            iconColor: "#77C000"
            hoverColor: "#88DD00"
            pressedColor: "#66AA00"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: rightArrow.currentState = "hover"
                onExited: rightArrow.currentState = "normal"
                onPressed: rightArrow.currentState = "pressed"
                onReleased: rightArrow.currentState = "hover"
                
                onClicked: {
                    // Manual control removed - data now comes from CAN bus only
                    console.log("Manual speed control disabled - using CAN data only")
                }
            }
        }

        RowLayout {
            id: rowContainer
            x: 366
            y: 5
            width: 221
            height: 24
            spacing: 10

            Text {
                id: timeText
                color: "#ffffff"
                text: weatherData.currentTime + " • " + weatherData.currentLocation
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }

            // CAN connection status indicator
            Text {
                id: canStatusText
                color: dashboardDataCAN.canConnected ? "#77C000" : "#FF6B6B"
                text: dashboardDataCAN.canConnected ? "CAN ●" : "SIM ●"
                font.pixelSize: 10
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                opacity: 0.8
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                id: weatherRow
                spacing: 5
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                MouseArea {
                    width: parent.width
                    height: parent.height
                    onClicked: {
                        weatherData.nextLocation() // Cycle through locations
                    }
                    hoverEnabled: true
                    
                    Row {
                        spacing: 5
                        anchors.centerIn: parent

                        Image {
                            id: weatherIcon
                            width: 32
                            height: 32
                            source: weatherData.weatherIconUrl
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            
                            // Fallback for when image fails to load
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "images/weather-icon.svg" // Fallback to local icon
                                }
                            }
                            
                            Behavior on source {
                                PropertyAnimation { duration: 300 }
                            }
                        }

                        Text {
                            id: temperatureText
                            color: "#ffffff"
                            text: "16°C"
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                        }
                    }
                }
            }
        }

        Text {
            id: text2
            x: 434
            y: 192
            width: 100
            height: 21
            color: "#bebebe"
            text: qsTr("cm/s")
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Medium
            font.family: "Arial"
        }

        RowLayout {
            id: rowLayout1
            x: 394
            y: 219
            width: 174
            height: 48
            spacing: 5

            Image {
                id: frame
                width: 48
                height: 48
                source: "images/Frame.svg"
                sourceSize.height: 48
                sourceSize.width: 48
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: text4
                width: 121
                height: 48
                color: "#6b4339"
                text: Math.round(rectangle.animatedRpm).toString() + " rpm"
                font.pixelSize: 32
                lineHeight: 1
                font.weight: Font.Medium
                font.family: "Arial"
            }
        }

        BatteryBar {
            id: frame13
            x: 210
            y: 333
            
            // Connect to real battery data
            batteryLevel: rectangle.currentBatteryLevel
            useRealData: true
        }

        // Up arrow - faster increment

        // Down arrow - faster decrement
    }

    states: [
        State {
            name: "interactive"
        }
    ]
}
