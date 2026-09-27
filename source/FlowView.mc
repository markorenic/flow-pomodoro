using Toybox.Graphics;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class FlowView extends WatchUi.View {
    var app;
    function initialize(owner) { View.initialize(); app = owner; }
    function onShow() { app.visible = true; WatchUi.requestUpdate(); }
    function onHide() { app.visible = false; }

    function text(dc, y, font, value) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(140, y, font, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onUpdate(dc) {
        var model = app.session;
        var remaining = model.left(app.now());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // A sparse perimeter keeps the circular screen's center quiet.
        for (var i = 0; i < 48; i += 1) {
            var angle = (i * 7.5 - 90) * Math.PI / 180;
            var active = i < 48 * remaining / model.total;
            dc.setColor(active ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            var inner = i % 4 == 0 ? 130 : 133;
            dc.drawLine(140 + Math.cos(angle) * inner, 140 + Math.sin(angle) * inner,
                140 + Math.cos(angle) * 135, 140 + Math.sin(angle) * 135);
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        var clock = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        text(dc, 33, Graphics.FONT_XTINY, clock.hour.format("%02d") + ":" + clock.min.format("%02d"));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        text(dc, 66, Graphics.FONT_SMALL, model.phase == 0 ? "FOCUS" : (model.phase == 1 ? "BREAK" : "LONG BREAK"));
        var timer = (remaining / 60).toNumber().format("%02d") + ":" + (remaining % 60).format("%02d");
        text(dc, 111, Graphics.FONT_NUMBER_HOT, timer);
        var f = model.running ? app.frame : 0;
        if (model.phase == 0) { terminal(dc, f); } else { cup(dc, f); }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        text(dc, 216, Graphics.FONT_XTINY, model.running ? "" : (model.started ? "PAUSED" : "READY"));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var done = model.completed % 4;
        if (model.phase == 2) { done = 4; }
        for (var j = 0; j < 4; j += 1) {
            var x = 113 + j * 18;
            if (j < done) { dc.fillCircle(x, 240, 3); }
            else { dc.drawCircle(x, 240, 3); }
        }
        // Familiar play/pause glyph beside the physical START button.
        if (model.running) {
            dc.fillRectangle(247, 101, 3, 10);
            dc.fillRectangle(253, 101, 3, 10);
        } else {
            dc.fillPolygon([[247, 100], [247, 112], [256, 106]]);
        }
    }

    function terminal(dc, frame) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(102, 151, 76, 44, 3);
        dc.drawLine(102, 160, 177, 160);
        dc.fillRectangle(108, 155, 2, 2);
        dc.fillRectangle(113, 155, 2, 2);
        dc.fillRectangle(118, 155, 2, 2);
        dc.drawLine(108, 167, 112, 170);
        dc.drawLine(112, 170, 108, 173);
        var count = (frame % 12) + 1;
        for (var i = 0; i < count; i += 1) {
            var row = i < 6 ? 0 : 1;
            var col = i % 6;
            dc.fillRectangle(119 + col * 8, 169 + row * 9, col == 2 ? 3 : 5, 2);
        }
        if (frame % 2 == 0) {
            var cursor = count % 6;
            dc.fillRectangle(119 + cursor * 8, count < 6 ? 168 : 177, 3, 5);
        }
        dc.drawLine(94, 200, 186, 200);
        dc.drawLine(97, 196, 94, 200);
        dc.drawLine(183, 196, 186, 200);
        dc.drawLine(131, 197, 149, 197);
        dc.setPenWidth(1);
    }

    function cup(dc, frame) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);
        var sway = frame % 4 < 2 ? -1 : 1;
        for (var i = 0; i < 3; i += 1) {
            var x = 124 + i * 12;
            dc.drawLine(x, 160, x + sway * 2, 155);
            dc.drawLine(x + sway * 2, 155, x, 150);
            dc.drawLine(x, 150, x - sway * 2, 145);
        }
        dc.drawRoundedRectangle(164, 171, 15, 18, 5);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(159, 168, 7, 26);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawRoundedRectangle(113, 166, 53, 34, 7);
        dc.drawLine(113, 169, 165, 169);
        if (frame % 12 == 9) {
            dc.drawLine(125, 180, 130, 180);
            dc.drawLine(147, 180, 152, 180);
        } else {
            dc.fillRectangle(127, 178, 2, 4);
            dc.fillRectangle(149, 178, 2, 4);
        }
        dc.drawLine(136, 185, 139, 188);
        dc.drawLine(139, 188, 143, 185);
        dc.drawLine(107, 204, 175, 204);
        dc.setPenWidth(1);
    }
}
