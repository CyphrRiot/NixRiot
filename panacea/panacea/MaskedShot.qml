import QtQuick
import QtQuick.Effects

//
MultiEffect {
    property Item src
    property Item mask

    source: shot.src
    maskEnabled: true
    maskSource: shot.mask

    id: shot
}
