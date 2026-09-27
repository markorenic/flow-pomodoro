using Toybox.Application;
using Toybox.Attention;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class FlowApp extends Application.AppBase {
    var session as Session;
    var pulse;
    var frame = 0;
    var view;
    var visible = false;
    var checkpoint = 0;

    function initialize() {
        AppBase.initialize();
        session = new Session();
    }

    function now() { return (System.getTimer() / 1000).toNumber(); }

    function onStart(state) {
        session.restore(Application.Storage.getValue("session-v1"));
        checkpoint = now();
        pulse = new Timer.Timer();
        pulse.start(method(:tick), 500, true);
    }

    function getInitialView() {
        view = new FlowView(self);
        return [view, new FlowDelegate(self)];
    }

    function save() { Application.Storage.setValue("session-v1", session.snapshot(now())); }

    function onStop(state) {
        pulse.stop();
        session.tick(now());
        session.pause(now());
        save();
    }

    function tick() as Void {
        var clock = now();
        if (session.tick(clock)) {
            save();
            if (session.haptics && Attention has :vibrate) {
                Attention.vibrate([
                    new Attention.VibeProfile(70, 350),
                    new Attention.VibeProfile(0, 180),
                    new Attention.VibeProfile(70, 350)
                ]);
            }
        }
        if (session.running) { frame = (frame + 1) % 24; }
        if (clock - checkpoint >= 60) { save(); checkpoint = clock; }
        if (visible) { WatchUi.requestUpdate(); }
    }

    function toggle() {
        // Resolve expiry before interpreting a button press at the boundary.
        if (!session.tick(now())) { session.toggle(now()); }
        save();
        WatchUi.requestUpdate();
    }

    function menu() {
        var menu = new WatchUi.Menu2({:title => "Flow"});
        menu.addItem(new WatchUi.MenuItem("Return", null, :returnToTimer, null));
        menu.addItem(new WatchUi.MenuItem("Skip session", null, :skip, null));
        menu.addItem(new WatchUi.MenuItem("Restart session", null, :reset, null));
        menu.addItem(new WatchUi.MenuItem("Durations", null, :durations, null));
        menu.addItem(new WatchUi.MenuItem("Vibration", session.haptics ? "On" : "Off", :haptics, null));
        menu.addItem(new WatchUi.MenuItem("Save & exit", null, :exit, null));
        WatchUi.pushView(menu, new FlowMenuDelegate(self), WatchUi.SLIDE_UP);
    }
}

class FlowDelegate extends WatchUi.BehaviorDelegate {
    var app as FlowApp;
    function initialize(owner) { BehaviorDelegate.initialize(); app = owner; }
    function onSelect() { app.toggle(); return true; }
    function onBack() { app.menu(); return true; }
    function onMenu() { app.menu(); return true; }
}

class FlowMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app as FlowApp;
    function initialize(owner) { Menu2InputDelegate.initialize(); app = owner; }
    function onSelect(item) {
        var id = item.getId();
        if (id == :exit) { System.exit(); }
        if (id == :durations) {
            var menu = new WatchUi.Menu2({:title => "Durations"});
            var labels = ["Focus", "Short break", "Long break"] as Lang.Array<Lang.String>;
            for (var i = 0; i < 3; i += 1) {
                menu.addItem(new WatchUi.MenuItem(labels[i],
                    (app.session.durations[i] / 60).toString() + " min", i, null));
            }
            WatchUi.pushView(menu, new DurationDelegate(app), WatchUi.SLIDE_UP);
            return;
        }
        if (id == :skip || id == :reset) {
            var title = id == :skip ? "Skip session?" : "Restart session?";
            WatchUi.pushView(new WatchUi.Confirmation(title),
                new SessionConfirm(app, id), WatchUi.SLIDE_UP);
            return;
        }
        if (id == :haptics) {
            app.session.haptics = !app.session.haptics;
            item.setSubLabel(app.session.haptics ? "On" : "Off");
            app.save();
            WatchUi.requestUpdate();
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class SessionConfirm extends WatchUi.ConfirmationDelegate {
    var app as FlowApp;
    var action;
    function initialize(owner, id) { ConfirmationDelegate.initialize(); app = owner; action = id; }
    function onResponse(yes) {
        if (yes) {
            if (action == :skip) { app.session.skip(); } else { app.session.reset(); }
            app.save();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        }
        return true;
    }
}

class DurationDelegate extends WatchUi.Menu2InputDelegate {
    var app as FlowApp;
    function initialize(owner) { Menu2InputDelegate.initialize(); app = owner; }
    function onSelect(item) {
        var index = item.getId() as Lang.Number;
        var options = index == 0 ? [15, 25, 30, 45, 50, 60, 90] : [1, 3, 5, 10, 15, 20, 30];
        var menu = new WatchUi.Menu2({:title => item.getLabel()});
        for (var i = 0; i < options.size(); i += 1) {
            menu.addItem(new WatchUi.MenuItem(options[i].toString() + " min", null, options[i], null));
        }
        WatchUi.pushView(menu, new DurationChoice(app, index, item), WatchUi.SLIDE_UP);
    }
}

class DurationChoice extends WatchUi.Menu2InputDelegate {
    var app as FlowApp;
    var index;
    var parentItem;
    function initialize(owner, phaseIndex, item) {
        Menu2InputDelegate.initialize(); app = owner; index = phaseIndex; parentItem = item;
    }
    function onSelect(item) {
        app.session.setDuration(index, (item.getId() as Lang.Number) * 60);
        parentItem.setSubLabel(item.getId().toString() + " min");
        app.save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
