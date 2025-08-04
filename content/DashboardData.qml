import QtQuick 6.4

Item {
    id: dashboardData
    
    // Properties that can be bound to from UI files
    property int currentSpeed: 50
    property int currentRpm: 1200
    property string currentGear: "N"
    
    // Simple cycling animation for demonstration
    SequentialAnimation {
        running: true
        loops: Animation.Infinite
        
        PropertyAction { target: dashboardData; property: "currentGear"; value: "P" }
        PropertyAction { target: dashboardData; property: "currentSpeed"; value: 0 }
        PropertyAction { target: dashboardData; property: "currentRpm"; value: 800 }
        PauseAnimation { duration: 2000 }
        
        PropertyAction { target: dashboardData; property: "currentGear"; value: "R" }
        PropertyAction { target: dashboardData; property: "currentSpeed"; value: 8 }
        PropertyAction { target: dashboardData; property: "currentRpm"; value: 1200 }
        PauseAnimation { duration: 2000 }
        
        PropertyAction { target: dashboardData; property: "currentGear"; value: "N" }
        PropertyAction { target: dashboardData; property: "currentSpeed"; value: 0 }
        PropertyAction { target: dashboardData; property: "currentRpm"; value: 700 }
        PauseAnimation { duration: 2000 }
        
        PropertyAction { target: dashboardData; property: "currentGear"; value: "D" }
        PropertyAction { target: dashboardData; property: "currentSpeed"; value: 65 }
        PropertyAction { target: dashboardData; property: "currentRpm"; value: 2800 }
        PauseAnimation { duration: 2000 }
        
        PropertyAction { target: dashboardData; property: "currentGear"; value: "S" }
        PropertyAction { target: dashboardData; property: "currentSpeed"; value: 95 }
        PropertyAction { target: dashboardData; property: "currentRpm"; value: 4200 }
        PauseAnimation { duration: 2000 }
    }
}
