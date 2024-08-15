/*
 *
 *   SPDX-FileCopyrightText: 2015 Teo Mrnjavac <teo@kde.org>
 *   SPDX-FileCopyrightText: 2018 Adriaan de Groot <groot@kde.org>
 *   SPDX-FileCopyrightText: 2022 Victor Fuentes <vmfuentes64@gmail.com>
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Calamares is Free Software: see the License-Identifier above.
 *
 */

import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        console.log("QML Component (default slideshow) Next slide");
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 20000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Text {
            id: text1
            anchors.centerIn: parent
            text: "Text 1"
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
            color: "#6586C8"
        }
        Image {
            id: background1
            source: "gfx-landing-1.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.bottom: text1.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            anchors.horizontalCenter: background1.horizontalCenter
            anchors.top: text1.bottom
            text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod<br/>"+
                  "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,<br/>"+
                  "quis nostrud exercitation ullamco laboris nisi ut aliquip ex <b>ea commodo<br/>"+
                  "consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse.</b>"
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Text {
            id: text2
            anchors.centerIn: parent
            text: "Text 2"
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
            color: "#6586C8"
        }
        Image {
            id: background2
            source: "gfx-landing-2.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.bottom: text2.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            anchors.horizontalCenter: background2.horizontalCenter
            anchors.top: text2.bottom
            text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod<br/>"+
                  "quis nostrud exercitation ullamco laboris nisi ut aliquip ex <b>ea commodo<br/>"+
                  "consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse.</b>"
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Text {
            id: text3
            anchors.centerIn: parent
            text: "Text 3"
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
            color: "#6586C8"
        }
        Image {
            id: background3
            source: "gfx-landing-3.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.bottom: text3.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            anchors.horizontalCenter: background3.horizontalCenter
            anchors.top: text3.bottom
            text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod<br/>"+
                  "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,<br/>"+
                  "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,<br/>"+
                  "quis nostrud exercitation ullamco laboris nisi ut aliquip ex <b>ea commodo<br/>"+
                  "consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse.</b>"
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    // When this slideshow is loaded as a V1 slideshow, only
    // activatedInCalamares is set, which starts the timer (see above).
    //
    // In V2, also the onActivate() and onLeave() methods are called.
    // These example functions log a message (and re-start the slides
    // from the first).
    function onActivate() {
        console.log("QML Component (default slideshow) activated");
        presentation.currentSlide = 0;
    }

    function onLeave() {
        console.log("QML Component (default slideshow) deactivated");
    }

}
