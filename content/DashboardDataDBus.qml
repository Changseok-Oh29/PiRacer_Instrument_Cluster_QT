import QtQuick 6.4

QtObject {
    id: root

    // Properties exposed to the UI
    property real batteryLevel: 0.0
    property real chargingCurrent: 0.0
    property bool leftTurnSignal: false
    property bool rightTurnSignal: false
    property bool dbusConnected: false

    // Monitor DBus connection and data
    Component.onCompleted: {
        console.log("DashboardDataDBus: Component completed, checking for dbusReceiver...")
        console.log("DashboardDataDBus: typeof dbusReceiver:", typeof dbusReceiver)

        if (typeof dbusReceiver !== 'undefined' && dbusReceiver !== null) {
            console.log("DashboardDataDBus: ✅ Connected to DBus receiver")
            dbusConnected = true

            // Initial values
            batteryLevel = dbusReceiver.battery
            chargingCurrent = dbusReceiver.chargingCurrent || 0
            leftTurnSignal = dbusReceiver.leftTurnSignal || false
            rightTurnSignal = dbusReceiver.rightTurnSignal || false
            console.log("DashboardDataDBus: Initial battery level:", batteryLevel.toFixed(1) + "%")
            console.log("DashboardDataDBus: Initial charging current:", chargingCurrent.toFixed(1) + "mA")
            console.log("DashboardDataDBus: Initial turn signals - Left:", leftTurnSignal, "Right:", rightTurnSignal)

            // Connect to battery changes
            dbusReceiver.batteryChanged.connect(function() {
                batteryLevel = dbusReceiver.battery
                console.log("DashboardDataDBus: 🔋 Battery updated to", batteryLevel.toFixed(1) + "%")
            })

            // Connect to charging current changes
            if (dbusReceiver.chargingCurrentChanged) {
                dbusReceiver.chargingCurrentChanged.connect(function() {
                    chargingCurrent = dbusReceiver.chargingCurrent
                    console.log("DashboardDataDBus: ⚡ Charging current updated to", chargingCurrent.toFixed(1) + "mA")
                })
            }
            
            // Connect to turn signal changes
            if (dbusReceiver.leftTurnSignalChanged) {
                dbusReceiver.leftTurnSignalChanged.connect(function() {
                    leftTurnSignal = dbusReceiver.leftTurnSignal
                    console.log("DashboardDataDBus: 🔄 Left turn signal updated to", leftTurnSignal)
                })
            }
            
            if (dbusReceiver.rightTurnSignalChanged) {
                dbusReceiver.rightTurnSignalChanged.connect(function() {
                    rightTurnSignal = dbusReceiver.rightTurnSignal
                    console.log("DashboardDataDBus: 🔄 Right turn signal updated to", rightTurnSignal)
                })
            }
        } else {
            console.warn("DashboardDataDBus: ❌ DBus receiver not available")
            dbusConnected = false
            // Set default test values to verify UI binding
            batteryLevel = 50.0
            chargingCurrent = 800.0  // Below threshold - icon should be invisible
            leftTurnSignal = false
            rightTurnSignal = false
        }
    }

    // Debug logging
    onBatteryLevelChanged: {
        console.log("DashboardDataDBus: 📊 Battery level changed to", batteryLevel.toFixed(1) + "%")
    }

    onChargingCurrentChanged: {
        console.log("DashboardDataDBus: ⚡ Charging current changed to", chargingCurrent.toFixed(1) + "mA")
    }
    
    onLeftTurnSignalChanged: {
        console.log("DashboardDataDBus: 🔄 Left turn signal changed to", leftTurnSignal)
    }
    
    onRightTurnSignalChanged: {
        console.log("DashboardDataDBus: 🔄 Right turn signal changed to", rightTurnSignal)
    }

    onDbusConnectedChanged: {
        console.log("DashboardDataDBus: 📡 DBus connection status:", dbusConnected)
    }
}
