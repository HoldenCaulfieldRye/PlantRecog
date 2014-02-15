#!/bin/bash
# xCode Unit Tests
xcodebuild -scheme beLeafUnitTest -sdk iphonesimulator7.0 ONLY_ACTIVE_ARCH=YES test > "UnitTestLog.txt"
