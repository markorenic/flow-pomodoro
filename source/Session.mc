using Toybox.Lang;

class Session {
    var durations as Lang.Array<Lang.Number> = [25 * 60, 5 * 60, 15 * 60];
    var phase = 0;
    var completed = 0;
    var remaining = 25 * 60;
    var total = 25 * 60;
    var running = false;
    var started = false;
    var deadline = 0;
    var haptics = true;

    function initialize() {}

    function left(now) {
        if (!running) { return remaining; }
        return deadline > now ? deadline - now : 0;
    }

    function toggle(now) {
        if (running) {
            pause(now);
        } else {
            running = true;
            started = true;
            deadline = now + remaining;
        }
    }

    function pause(now) {
        remaining = left(now);
        running = false;
    }

    function prepare(nextPhase as Lang.Number) {
        phase = nextPhase;
        total = durations[phase];
        remaining = total;
        running = false;
        started = false;
    }

    // A late timer callback completes exactly one block, never several cycles.
    function tick(now) {
        if (!running || left(now) > 0) { return false; }
        if (phase == 0) {
            completed += 1;
            prepare(completed % 4 == 0 ? 2 : 1);
        } else {
            prepare(0);
        }
        return true;
    }

    function skip() {
        // Skipping focus does not earn a completed block.
        prepare(phase == 0 ? 1 : 0);
    }

    function reset() { prepare(phase); }

    function setDuration(index as Lang.Number, seconds as Lang.Number) {
        durations[index] = seconds;
        if (phase == index && !started) { prepare(phase); }
    }

    function snapshot(now) {
        return {
            "durations" => durations, "phase" => phase,
            "completed" => completed, "remaining" => left(now),
            "total" => total, "started" => started, "haptics" => haptics
        };
    }

    function restore(data) {
        if (!(data instanceof Lang.Dictionary)) { return; }
        if (!(data["durations"] instanceof Lang.Array) || data["durations"].size() != 3) { return; }
        var values = data["durations"] as Lang.Array;
        for (var i = 0; i < 3; i += 1) {
            var seconds = values[i];
            if (!(seconds instanceof Lang.Number) || seconds < 60 || seconds > 5400) { return; }
        }
        var p = data["phase"];
        var t = data["total"];
        var r = data["remaining"];
        var c = data["completed"];
        if (!(p instanceof Lang.Number) || p < 0 || p > 2 ||
            !(t instanceof Lang.Number) || t < 60 || t > 5400 ||
            !(r instanceof Lang.Number) || r < 0 || r > t ||
            !(c instanceof Lang.Number) || c < 0) { return; }
        durations = values as Lang.Array<Lang.Number>;
        phase = p;
        total = t;
        remaining = r;
        completed = c;
        started = data["started"] == true;
        haptics = data["haptics"] != false;
        running = false;
        if (remaining == 0) { prepare(phase); }
    }
}
