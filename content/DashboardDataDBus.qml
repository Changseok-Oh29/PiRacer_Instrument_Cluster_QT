import QtQuick 6.4

QtObject {
    id: root
    
    // Properties exposed to the UI
    property real batteryLevel: 0.0
    property bool dbusConnected: false
    
    // Monitor DBus connection and data
    Component.onCompleted: {
        console.log("DashboardDataDBus: Component completed, checking for dbusReceiver...")
        console.log("DashboardDataDBus: typeof dbusReceiver:", typeof dbusReceiver)
        
        if (typeof dbusReceiver !== 'undefined' && dbusReceiver !== null) {
            console.log("DashboardDataDBus: ✅ Connected to DBus receiver")
            dbusConnected = true
            
            // Initial battery level
            batteryLevel = dbusReceiver.battery
            console.log("DashboardDataDBus: Initial battery level:", batteryLevel.toFixed(1) + "%")
            
            // Connect to battery changes
            dbusReceiver.batteryChanged.connect(function() {
                batteryLevel = dbusReceiver.battery
                console.log("DashboardDataDBus: 🔋 Battery updated to", batteryLevel.toFixed(1) + "%")
            })
        } else {
            console.warn("DashboardDataDBus: ❌ DBus receiver not available")
            dbusConnected = false
            // Set a default test value to verify UI binding
            batteryLevel = 50.0
        }
    }
    
    // Debug logging
    onBatteryLevelChanged: {
        console.log("DashboardDataDBus: 📊 Battery level changed to", batteryLevel.toFixed(1) + "%")
    }
    
    onDbusConnectedChanged: {
        console.log("DashboardDataDBus: 📡 DBus connection status:", dbusConnected)
    }
}
