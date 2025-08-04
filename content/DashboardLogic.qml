import QtQuick 6.4

Item {
    id: dashboardLogic
    
    // Reference to the data container
    property alias dataContainer: dashboardData
    
    // Data container with properties
    DashboardData {
        id: dashboardData
    }
    
    // Speed limits based on gear
    property var gearSpeedLimits: {
        "P": { min: 0, max: 0 },
        "R": { min: 0, max: 15 },
        "N": { min: 0, max: 0 },
        "D": { min: 0, max: 120 },
        "S": { min: 0, max: 180 }
    }
    
    // RPM calculation function
    function calculateRpm(speed, gear) {
        if (gear === "P" || gear === "N") return Math.random() * 800 + 600;
        if (gear === "R") return speed * 50 + Math.random() * 200 + 800;
        return speed * 25 + Math.random() * 500 + 1000;
    }
    
    // Function to update values based on current gear
    function updateValues() {
        var gear = dashboardData.currentGear;
        var limits = gearSpeedLimits[gear];
        
        // Generate random speed within gear limits
        if (limits.max > 0) {
            dashboardData.currentSpeed = Math.floor(Math.random() * (limits.max - limits.min + 1)) + limits.min;
        } else {
            dashboardData.currentSpeed = 0;
        }
        
        // Calculate corresponding RPM
        dashboardData.currentRpm = Math.floor(calculateRpm(dashboardData.currentSpeed, gear));
        
        // Trigger update notification
        dashboardData.updateTrigger++;
    }
    
    // Function to handle gear changes
    function onGearChanged(newGear) {
        dashboardData.currentGear = newGear;
        updateValues();
    }
    
    // Random value generator
    Timer {
        id: dataSimulator
        interval: 2000
        running: true
        repeat: true
        
        onTriggered: {
            dashboardLogic.updateValues();
        }
    }
}
