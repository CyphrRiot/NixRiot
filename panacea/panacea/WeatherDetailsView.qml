pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: view

    property var sys
    property var forecastData: null
    property int selectedDayIndex: 0

    implicitWidth: 920
    implicitHeight: 560

    function dayName(dateStr, idx) {
        if (idx === 0) return "Today";
        if (idx === 1) return "Tomorrow";
        if (!dateStr) return "";
        var parts = dateStr.split("-");
        if (parts.length < 3) return dateStr;
        var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        var daysEn = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var monthsEn = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var dayArr = daysEn;
        var monArr = monthsEn;
        return dayArr[d.getDay()] + ", " + d.getDate() + " " + monArr[d.getMonth()];
    }

    function iconGlyph(code) {
        var k = String(code).slice(0, 2);
        return String.fromCodePoint(
              k === "01" ? 0xF0599
            : k === "02" ? 0xF0595
            : (k === "03" || k === "04") ? 0xF0590
            : (k === "09" || k === "10") ? 0xF0597
            : k === "11" ? 0xF0593
            : k === "13" ? 0xF0598
            : k === "50" ? 0xF0591
                         : 0xF0590);
    }

    readonly property var currentObj: (view.forecastData && view.forecastData.current) ? view.forecastData.current : null
    readonly property var dailyList: (view.forecastData && view.forecastData.daily) ? view.forecastData.daily : []
    readonly property var hourlyList: (view.forecastData && view.forecastData.hourly) ? view.forecastData.hourly : []
    readonly property var activeDay: (dailyList.length > selectedDayIndex) ? dailyList[selectedDayIndex] : null

    readonly property int weekMinTemp: {
        if (!dailyList || !dailyList.length) return 0;
        var m = dailyList[0].tempMin;
        for (var i = 1; i < dailyList.length; i++) {
            if (dailyList[i].tempMin < m) m = dailyList[i].tempMin;
        }
        return m;
    }

    readonly property int weekMaxTemp: {
        if (!dailyList || !dailyList.length) return 30;
        var m = dailyList[0].tempMax;
        for (var i = 1; i < dailyList.length; i++) {
            if (dailyList[i].tempMax > m) m = dailyList[i].tempMax;
        }
        return m;
    }

    readonly property int weekRange: Math.max(1, weekMaxTemp - weekMinTemp)

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 26
        color: Qt.rgba(0.065, 0.065, 0.075, 0.98)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: view.sys ? view.sys.colCrit : "#d71921"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: (view.forecastData && view.forecastData.city)
                              ? view.forecastData.city : (view.sys && view.sys.weatherPlace ? view.sys.weatherPlace : "...")
                        color: view.sys ? view.sys.colFg : "#ffffff"
                        font {
                            family: view.sys ? view.sys.fontFam : "sans-serif"
                            pixelSize: 17
                            bold: true
                        }
                        elide: Text.ElideRight
                    }

                    Text {
                        text: ("Weather forecast") +
                              (view.activeDay ? " · " + view.dayName(view.activeDay.date, view.selectedDayIndex) : "")
                        color: view.sys ? view.sys.colMuted : "#888888"
                        font {
                            family: view.sys ? view.sys.fontFam : "sans-serif"
                            pixelSize: 11
                        }
                    }
                }

                Rectangle {
                    id: refBtn
                    width: 32; height: 32; radius: 16
                    color: refMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: refIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: (view.sys && view.sys.weatherBusy) ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colFg : "#ffffff")
                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 14 }

                        RotationAnimation on rotation {
                            running: view.sys && view.sys.weatherBusy
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 900
                        }
                    }

                    MouseArea {
                        id: refMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (view.sys) view.sys.refreshWeatherForecast(); }
                    }
                }

                Rectangle {
                    id: closeBtn
                    width: 32; height: 32; radius: 16
                    color: closeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMa.containsMouse ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colFg : "#ffffff")
                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 12; bold: true }
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (view.sys) view.sys.weatherDetailsOpen = false; }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18

                ColumnLayout {
                    Layout.preferredWidth: 520
                    Layout.minimumWidth: 520
                    Layout.maximumWidth: 520
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.035)
                        border.color: Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 14

                            Text {
                                text: view.iconGlyph(view.activeDay ? view.activeDay.icon : (view.currentObj ? view.currentObj.icon : (view.sys ? view.sys.weatherIcon : "03d")))
                                color: view.sys ? view.sys.colFg : "#ffffff"
                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 42 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 10
                                    Text {
                                        text: (view.activeDay ? view.activeDay.tempMax : (view.currentObj ? view.currentObj.temp : (view.sys && view.sys.weatherTemp ? view.sys.weatherTemp : "--"))) + "°"
                                        color: view.sys ? view.sys.colFg : "#ffffff"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 36; bold: true }
                                    }

                                    Rectangle {
                                        visible: view.activeDay !== null
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 6
                                        color: Qt.rgba(1, 1, 1, 0.06)
                                        implicitWidth: rangeText.implicitWidth + 12
                                        implicitHeight: 20
                                        Text {
                                            id: rangeText
                                            anchors.centerIn: parent
                                            text: view.activeDay ? (view.activeDay.tempMin + "° … " + view.activeDay.tempMax + "°") : ""
                                            color: view.sys ? view.sys.colMuted : "#888"
                                            font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 10; bold: true }
                                        }
                                    }
                                }

                                Text {
                                    text: view.activeDay
                                          ? view.activeDay.desc
                                          : (view.currentObj ? view.currentObj.desc : (view.sys && view.sys.weatherDesc ? view.sys.weatherDesc : "—"))
                                    color: view.sys ? view.sys.colFg : "#ffffff"
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 12; bold: true }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 168
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.035)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: "󰔄"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 15 }
                                    }
                                    Text {
                                        text: "FEELS LIKE"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; letterSpacing: 0.9; bold: true }
                                    }
                                }
                                Text {
                                    text: (view.activeDay ? view.activeDay.feelsMax : (view.currentObj ? view.currentObj.feels : (view.sys && view.sys.weatherTemp ? view.sys.weatherTemp : "--"))) + "°"
                                    color: view.sys ? view.sys.colFg : "#fff"
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 26; bold: true }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.035)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: view.activeDay ? "󰖖" : "󰖉"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 15 }
                                    }
                                    Text {
                                        text: view.activeDay ? "RAIN" : "HUMIDITY"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; letterSpacing: 0.9; bold: true }
                                    }
                                }
                                Text {
                                    text: view.activeDay ? (view.activeDay.pop + "%") : ((view.currentObj ? view.currentObj.humidity : (view.sys && view.sys.weatherHumidity ? view.sys.weatherHumidity : "--")) + "%")
                                    color: (view.activeDay && view.activeDay.pop > 40) ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colFg : "#fff")
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 26; bold: true }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.035)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: "󰖝"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 15 }
                                    }
                                    Text {
                                        text: "WIND"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; letterSpacing: 0.9; bold: true }
                                    }
                                }
                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: String(view.activeDay ? view.activeDay.wind : (view.currentObj ? view.currentObj.wind : (view.sys && view.sys.weatherWind ? view.sys.weatherWind : "--")))
                                        color: view.sys ? view.sys.colFg : "#fff"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 26; bold: true }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignBaseline
                                        text: "m/s"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 13; bold: true }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.035)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: "󰈵"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 15 }
                                    }
                                    Text {
                                        text: "PRESSURE"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; letterSpacing: 0.9; bold: true }
                                    }
                                }
                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: view.currentObj ? String(view.currentObj.pressure) : "--"
                                        color: view.sys ? view.sys.colFg : "#fff"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 26; bold: true }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignBaseline
                                        text: "hPa"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 13; bold: true }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.035)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: "󰋘"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 15 }
                                    }
                                    Text {
                                        text: "UV INDEX"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; letterSpacing: 0.9; bold: true }
                                    }
                                }
                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: view.activeDay ? String(view.activeDay.uv) : "--"
                                        color: (view.activeDay && view.activeDay.uv >= 6) ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colFg : "#fff")
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 26; bold: true }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignBaseline
                                        visible: view.activeDay !== null
                                        text: (view.activeDay && view.activeDay.uv >= 6) ? "High" : "Moderate"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 12; bold: true }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.035)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: "󰖚"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 15 }
                                    }
                                    Text {
                                        text: "SUN"
                                        color: view.sys ? view.sys.colMuted : "#888"
                                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; letterSpacing: 0.9; bold: true }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: (view.activeDay && view.activeDay.sunrise && view.activeDay.sunset) ? (view.activeDay.sunrise + " / " + view.activeDay.sunset) : "--:--"
                                    color: view.sys ? view.sys.colFg : "#fff"
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 17; bold: true }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 130
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "HOURLY FORECAST"
                                color: view.sys ? view.sys.colMuted : "#888"
                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 10; letterSpacing: 1.1; bold: true }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "◀  ▶"
                                color: Qt.rgba(1, 1, 1, 0.25)
                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 9 }
                            }
                        }

                        Flickable {
                            id: hourlyFlick
                            implicitWidth: 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 104
                            contentWidth: hourlyRow.implicitWidth
                            contentHeight: height
                            clip: true
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                orientation: Qt.Horizontal
                                onWheel: ev => {
                                    var step = ev.pixelDelta.x !== 0 ? ev.pixelDelta.x : (ev.angleDelta.y !== 0 ? ev.angleDelta.y : ev.angleDelta.x);
                                    var max = Math.max(0, hourlyFlick.contentWidth - hourlyFlick.width);
                                    hourlyFlick.contentX = Math.max(0, Math.min(max, hourlyFlick.contentX - step));
                                }
                            }

                            RowLayout {
                                id: hourlyRow
                                spacing: 8
                                height: parent.height

                                Repeater {
                                    model: view.hourlyList
                                    Rectangle {
                                        id: superreg
                                        required property var modelData
                                        required property int index
                                        width: 66
                                        height: 100
                                        radius: 13
                                        color: superreg.index === 0 ? Qt.rgba(1, 1, 1, 0.10)
                                                           : (hMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.025))
                                        border.color: superreg.index === 0 ? (view.sys ? view.sys.colCrit : "#d71921") : Qt.rgba(1, 1, 1, 0.06)
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: superreg.index === 0 ? "Now" : superreg.modelData.time
                                                color: superreg.index === 0 ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colMuted : "#888")
                                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 10; bold: superreg.index === 0 }
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: view.iconGlyph(superreg.modelData.icon)
                                                color: view.sys ? view.sys.colFg : "#ffffff"
                                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 18 }
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: superreg.modelData.temp + "°"
                                                color: view.sys ? view.sys.colFg : "#ffffff"
                                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 12; bold: true }
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: superreg.modelData.pop > 0 ? ("💧" + superreg.modelData.pop + "%") : " "
                                                color: superreg.modelData.pop > 40 ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colMuted : "#888")
                                                font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 9 }
                                            }
                                        }

                                        MouseArea {
                                            id: hMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: rightCol
                    Layout.fillWidth: true
                    Layout.minimumWidth: 320
                    Layout.fillHeight: true
                    spacing: 8

                    Text {
                        text: "7-DAY FORECAST"
                        color: view.sys ? view.sys.colMuted : "#888"
                        font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 10; letterSpacing: 1.1; bold: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        Repeater {
                            model:  view.dailyList

                            Rectangle {
                                id: dayItem
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: view.selectedDayIndex === index
                                       ? Qt.rgba(1, 1, 1, 0.12)
                                       : (dayMa.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.025))
                                border.color: view.selectedDayIndex === index ? (view.sys ? view.sys.colCrit : "#d71921") : Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: dayLbl
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 74
                                    text: view.dayName(dayItem.modelData.date, dayItem.index)
                                    color: dayItem.index === 0 ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colFg : "#ffffff")
                                    font {
                                        family: view.sys ? view.sys.fontFam : "sans-serif"
                                        pixelSize: 11
                                        bold: dayItem.index === 0 || view.selectedDayIndex === dayItem.index
                                    }
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: dayIcon
                                    anchors.left: dayLbl.right
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    text: view.iconGlyph(dayItem.modelData.icon)
                                    color: view.sys ? view.sys.colFg : "#ffffff"
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 16 }
                                }

                                Text {
                                    id: dayPop
                                    anchors.left: dayIcon.right
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 34
                                    horizontalAlignment: Text.AlignRight
                                    text: dayItem.modelData.pop > 0 ? (dayItem.modelData.pop + "%") : ""
                                    color: dayItem.modelData.pop > 40 ? (view.sys ? view.sys.colCrit : "#d71921") : (view.sys ? view.sys.colMuted : "#888888")
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 10 }
                                }

                                Text {
                                    id: dayMin
                                    anchors.left: dayPop.right
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    horizontalAlignment: Text.AlignRight
                                    text: dayItem.modelData.tempMin + "°"
                                    color: view.sys ? view.sys.colMuted : "#888"
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11 }
                                }

                                Text {
                                    id: dayMax
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    horizontalAlignment: Text.AlignLeft
                                    text: dayItem.modelData.tempMax + "°"
                                    color: view.sys ? view.sys.colFg : "#fff"
                                    font { family: view.sys ? view.sys.fontFam : "sans-serif"; pixelSize: 11; bold: true }
                                }

                                Item {
                                    id: dayBar
                                    anchors.left: dayMin.right
                                    anchors.leftMargin: 6
                                    anchors.right: dayMax.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 5

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 2.5
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                    }

                                    Rectangle {
                                        x: Math.max(0, Math.min(parent.width - 8, ((dayItem.modelData.tempMin - view.weekMinTemp) / view.weekRange) * parent.width))
                                        width: Math.max(10, Math.min(parent.width - x, ((dayItem.modelData.tempMax - dayItem.modelData.tempMin) / view.weekRange) * parent.width))
                                        height: parent.height
                                        radius: 2.5
                                        color: view.selectedDayIndex === dayItem.index
                                               ? (view.sys ? view.sys.colCrit : "#d71921")
                                               : Qt.rgba(1, 1, 1, 0.75)
                                    }
                                }

                                MouseArea {
                                    id: dayMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: view.selectedDayIndex = dayItem.index
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
