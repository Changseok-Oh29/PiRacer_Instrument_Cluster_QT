// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick 6.4
import UntitledProject

Window {
    width: mainScreen.width
    height: mainScreen.height

    visible: true
    // flags: Qt.FramelessWindowHint
    // visibility: Window.FullScreen
    title: "UntitledProject"


    Screen01 {
        focus: true
        id: mainScreen

        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_Escape) {
                Qt.quit();
            }
        }
    }

}

