

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

    // Properties for dynamic values - now sourced from CAN data
    property int currentSpeed: 50  // Default fallback value
    property int currentRpm: 100   // Default fallback value
    property string currentGear: "N"
    property bool manualSpeedControl: false
    property bool canDataAvailable: dashboardDataCAN.canConnected

    // Update speed and RPM when CAN data changes
    Connections {
        target: dashboardDataCAN
        function onCurrentSpeedChanged() {
            if (dashboardDataCAN.canConnected) {
                rectangle.currentSpeed = Math.round(dashboardDataCAN.currentSpeed)
                console.log("Screen01 updated currentSpeed to:", rectangle.currentSpeed, "from CAN:", dashboardDataCAN.currentSpeed)
            }
        }
        function onCurrentRpmChanged() {
            if (dashboardDataCAN.canConnected) {
                rectangle.currentRpm = Math.round(dashboardDataCAN.currentRpm)
                console.log("Screen01 updated currentRpm to:", rectangle.currentRpm, "from CAN:", dashboardDataCAN.currentRpm)
            }
        }
        function onCanConnectedChanged() {
            console.log("Screen01 CAN connection changed to:", dashboardDataCAN.canConnected)
            if (dashboardDataCAN.canConnected) {
                rectangle.currentSpeed = Math.round(dashboardDataCAN.currentSpeed)
                rectangle.currentRpm = Math.round(dashboardDataCAN.currentRpm)
                console.log("Screen01 initialized from CAN - Speed:", rectangle.currentSpeed, "RPM:", rectangle.currentRpm)
            }
        }
    }

    // Debug the binding
    onCurrentSpeedChanged: console.log("Screen01 currentSpeed changed to:", currentSpeed, "CAN connected:", dashboardDataCAN.canConnected, "CAN speed:", dashboardDataCAN.currentSpeed)
    onCurrentRpmChanged: console.log("Screen01 currentRpm changed to:", currentRpm, "CAN connected:", dashboardDataCAN.canConnected, "CAN RPM:", dashboardDataCAN.currentRpm)
    onCanDataAvailableChanged: console.log("Screen01 canDataAvailable changed to:", canDataAvailable)

    // Debug timer to check binding status
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            console.log("DEBUG - Screen01 binding check:")
            console.log("  dashboardDataCAN.canConnected:", dashboardDataCAN.canConnected)
            console.log("  dashboardDataCAN.currentSpeed:", dashboardDataCAN.currentSpeed)
            console.log("  dashboardDataCAN.currentRpm:", dashboardDataCAN.currentRpm)
            console.log("  rectangle.currentSpeed:", rectangle.currentSpeed)
            console.log("  rectangle.currentRpm:", rectangle.currentRpm)
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

    // Speed limits based on gear
    property var gearSpeedLimits: {
        "P": { min: 0, max: 0 },
        "R": { min: 0, max: 15 },
        "N": { min: 0, max: 0 },
        "D": { min: 0, max: 120 },
        "S": { min: 0, max: 180 }
    }

    // RPM limits based on gear and speed
    function calculateRpm(speed, gear) {
        if (gear === "P" || gear === "N") return Math.random() * 800 + 600; // Idle RPM
        if (gear === "R") return speed * 50 + Math.random() * 200 + 800;
        return speed * 25 + Math.random() * 500 + 1000;
    }

    // Fallback data simulator (only runs when CAN data is not available)
    Timer {
        id: dataSimulator
        interval: 2000 // Update every 2 seconds
        running: !dashboardDataCAN.canConnected // Only run when CAN is not connected
        repeat: true

        onTriggered: {
            // Only auto-update if not in manual control mode and CAN is not connected
            if (!rectangle.manualSpeedControl && !dashboardDataCAN.canConnected) {
                var gear = rectangle.currentGear;
                var limits = gearSpeedLimits[gear];

                // Generate random speed within gear limits
                if (limits.max > 0) {
                    currentSpeed = Math.floor(Math.random() * (limits.max - limits.min + 1)) + limits.min;
                } else {
                    currentSpeed = 0;
                }

                // Calculate corresponding RPM
                currentRpm = Math.floor(calculateRpm(currentSpeed, gear));
            }
        }

        function triggerUpdate() {
            dataSimulator.stop();
            dataSimulator.start();
            dataSimulator.triggered();
        }
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
            text: rectangle.currentSpeed.toString()
            font.pixelSize: 90
            anchors.verticalCenterOffset: -41
            anchors.horizontalCenterOffset: 0
            font.weight: Font.Bold
            font.bold: false
            font.family: "Arial"
            anchors.centerIn: parent
            
            Behavior on text {
                PropertyAnimation { duration: 200 }
            }
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
                    rectangle.manualSpeedControl = true;
                    if (rectangle.currentSpeed > 1) {
                        rectangle.currentSpeed -= 1;
                    } else {
                        rectangle.currentSpeed = 100; // Wrap to 100 when going below 1
                    }
                    // Update RPM based on new speed
                    rectangle.currentRpm = Math.floor(rectangle.calculateRpm(rectangle.currentSpeed, rectangle.currentGear));
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
                    rectangle.manualSpeedControl = true;
                    if (rectangle.currentSpeed < 100) {
                        rectangle.currentSpeed += 1;
                    } else {
                        rectangle.currentSpeed = 1; // Wrap to 1 when going above 100
                    }
                    // Update RPM based on new speed
                    rectangle.currentRpm = Math.floor(rectangle.calculateRpm(rectangle.currentSpeed, rectangle.currentGear));
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
                text: rectangle.currentRpm.toString() + " rpm"
                font.pixelSize: 32
                lineHeight: 1
                font.weight: Font.Medium
                font.family: "Arial"

                Behavior on text {
                    PropertyAnimation { duration: 300 }
                }
            }
        }

        BatteryBar {
            id: frame13
            x: 210
            y: 333

        }

        GearIndicator {
            id: gearIndicator
            x: 428
            y: 280

            // Connect gear changes to update screen data
            onCurrentGearChanged: {
                rectangle.currentGear = currentGear;
                rectangle.manualSpeedControl = false; // Reset to automatic when gear changes
                dataSimulator.triggerUpdate(); // Trigger immediate update when gear changes
            }
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
