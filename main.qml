import QtQuick
import content

App {
    Component.onCompleted: {
        // Disable all console logging for release build
        console.log = function() {}
        console.debug = function() {}
        console.info = function() {}
        console.warn = function() {}
        console.error = function() {}
    }
}