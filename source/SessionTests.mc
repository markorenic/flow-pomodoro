using Toybox.Test;

(:test)
function pauseResume(logger) {
    var s = new Session();
    s.toggle(100);
    Test.assertEqual(s.left(160), 1440);
    s.pause(160);
    Test.assertEqual(s.left(800), 1440);
    s.toggle(800);
    Test.assertEqual(s.left(860), 1380);
    return true;
}

(:test)
function fourFocusBlocks(logger) {
    var s = new Session();
    for (var i = 1; i <= 4; i += 1) {
        s.toggle(0);
        Test.assert(s.tick(1500));
        Test.assertEqual(s.completed, i);
        Test.assertEqual(s.phase, i == 4 ? 2 : 1);
        Test.assert(!s.running);
        Test.assert(!s.tick(9000));
        s.toggle(0);
        Test.assert(s.tick(i == 4 ? 900 : 300));
        Test.assertEqual(s.phase, 0);
    }
    return true;
}

(:test)
function skipDoesNotEarnBlock(logger) {
    var s = new Session();
    s.toggle(10);
    s.skip();
    Test.assertEqual(s.completed, 0);
    Test.assertEqual(s.progress, 1);
    Test.assertEqual(s.phase, 1);
    s.skip();
    Test.assertEqual(s.phase, 0);
    Test.assertEqual(s.progress, 1);
    var restored = new Session();
    restored.restore(s.snapshot(20));
    Test.assertEqual(restored.progress, 1);
    return true;
}

(:test)
function restorePausedSession(logger) {
    var s = new Session();
    s.toggle(0);
    var restored = new Session();
    restored.restore(s.snapshot(123));
    Test.assertEqual(restored.remaining, 1377);
    Test.assert(!restored.running);
    Test.assert(restored.started);
    restored.toggle(500);
    Test.assertEqual(restored.left(600), 1277);
    return true;
}

(:test)
function settingsApplyToNextSession(logger) {
    var s = new Session();
    s.setDuration(0, 3000);
    Test.assertEqual(s.remaining, 3000);
    s.toggle(0);
    s.setDuration(0, 900);
    Test.assertEqual(s.left(10), 2990);
    s.reset();
    Test.assertEqual(s.remaining, 900);
    Test.assert(!s.running);
    return true;
}

(:test)
function invalidSavedData(logger) {
    var s = new Session();
    s.restore(null);
    s.restore({"durations" => [1, 2, 3]});
    Test.assertEqual(s.remaining, 1500);
    Test.assertEqual(s.phase, 0);
    return true;
}
