/****************************************************************************
**
** Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/
**
** This file is part of the Qt Graphical Effects module.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Nokia Corporation and its Subsidiary(-ies) nor
**     the names of its contributors may be used to endorse or promote
**     products derived from this software without specific prior written
**     permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 1.1
import Qt.labs.shaders 1.0
import "internal"

Item {
    id: rootItem
    property bool cached: false
    property real angle: 0.0
    property real horizontalOffset: 0.0
    property real verticalOffset: 0.0
    property variant source

    property Gradient gradient: Gradient {
        GradientStop { position: 0.0; color: "white" }
        GradientStop { position: 1.0; color: "black" }
    }

    SourceProxy {
        id: maskSourceProxy
        input: rootItem.source
    }

    Rectangle {
        id: gradientRect
        width: 16
        height: 256
        gradient: rootItem.gradient
        smooth: true
   }

    ShaderEffectSource {
        id: cacheItem
        anchors.fill: parent
        visible: rootItem.cached
        smooth: true
        rotation: shaderItem.rotation
        sourceItem: shaderItem
        live: true
        hideSource: visible
    }

    ShaderEffectItem {
        id: shaderItem
        property variant gradientSource: ShaderEffectSource {
            sourceItem: gradientRect
            smooth: true
            hideSource: true
            visible: false
        }
        property variant maskSource: maskSourceProxy.output
        property real startAngle: (rootItem.angle - 90) * Math.PI/180
        property variant center: Qt.point(0.5 + horizontalOffset / width, 0.5 + verticalOffset / height)

        anchors.fill: parent

        fragmentShader: maskSource == undefined ? noMaskShader : maskShader

        onFragmentShaderChanged: startAngleChanged()

        property string noMaskShader: "
            varying mediump vec2 qt_TexCoord0;
            uniform lowp sampler2D gradientSource;
            uniform highp float qt_Opacity;
            uniform highp float startAngle;
            uniform highp vec2 center;

            void main() {
                const highp float PI = 3.14159265;
                const highp float PIx2inv = 0.1591549;
                highp float a = (atan((center.y - qt_TexCoord0.t), (center.x - qt_TexCoord0.s)) + PI - startAngle) * PIx2inv;
                gl_FragColor = texture2D(gradientSource, vec2(0.0, fract(a))) * qt_Opacity;
            }
        "

        property string maskShader: "
            varying mediump vec2 qt_TexCoord0;
            uniform lowp sampler2D gradientSource;
            uniform lowp sampler2D maskSource;
            uniform highp float qt_Opacity;
            uniform highp float startAngle;
            uniform highp vec2 center;

            void main() {
                lowp float maskAlpha = texture2D(maskSource, qt_TexCoord0).a;
                const highp float PI = 3.14159265;
                const highp float PIx2inv = 0.1591549;
                highp float a = (atan((center.y - qt_TexCoord0.t), (center.x - qt_TexCoord0.s)) + PI - startAngle) * PIx2inv;
                gl_FragColor = texture2D(gradientSource, vec2(0.0, fract(a))) * maskAlpha * qt_Opacity;
            }
        "
    }
}
