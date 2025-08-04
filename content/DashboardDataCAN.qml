import QtQuick 6.4

Item {
    id: dashboardDataCAN
    
    // Properties for speed and RPM data - use internal properties that update explicitly
    property real currentSpeed: 0.0
    property real currentRpm: 0.0
    property bool canConnected: canReceiver.connected
    property string connectionStatus: canConnected ? "Connected" : "Disconnected"
    
    // Auto-connect to CAN interface on startup
    Component.onCompleted: {
        console.log("DashboardData: Connecting to CAN interface...")
        canReceiver.connectToCan("can10")
        canReceiver.startListening()
        
        // Initialize with current values if already connected
        updateValues()
    }
    
    // Function to update values from CAN receiver
    function updateValues() {
        currentSpeed = canReceiver.speed
        currentRpm = canReceiver.rpm
    }
    
    // Handle CAN connection errors
    Connections {
        target: canReceiver
        function onErrorOccurred(error) {
            console.error("CAN Error:", error)
        }
        
        function onDataReceived(speed, rpm) {
            console.log("CAN Data - Speed:", speed, "cm/s, RPM:", rpm)
            console.log("CAN Connection Status:", dashboardDataCAN.canConnected)
            // Update our properties when new data is received
            dashboardDataCAN.currentSpeed = speed
            dashboardDataCAN.currentRpm = rpm
            console.log("Updated properties - Speed:", dashboardDataCAN.currentSpeed, "RPM:", dashboardDataCAN.currentRpm)
        }
        
        function onSpeedChanged() {
            dashboardDataCAN.updateValues()
        }
        
        function onRpmChanged() {
            dashboardDataCAN.updateValues()
        }
        
        function onConnectedChanged() {
            if (canReceiver.connected) {
                console.log("CAN: Connected successfully")
                dashboardDataCAN.updateValues()
            } else {
                console.log("CAN: Disconnected")
            }
        }
    }
    
    // Methods to control CAN connection
    function reconnectCan() {
        canReceiver.disconnectFromCan()
        canReceiver.connectToCan("can10")
        canReceiver.startListening()
    }
    
    function disconnectCan() {
        canReceiver.disconnectFromCan()
    }
}
