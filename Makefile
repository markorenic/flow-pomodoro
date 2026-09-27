JAVA_HOME ?= /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk
export JAVA_HOME
PATH := /opt/homebrew/opt/openjdk@17/bin:/opt/homebrew/bin:$(PATH)
export PATH

.PHONY: build package test

build:
	mkdir -p bin
	monkeyc -f monkey.jungle -d fenix7x -y bin/developer_key.der -o bin/Flow.prg -w

package:
	mkdir -p bin
	monkeyc -e -r -f monkey.jungle -y bin/developer_key.der -o bin/Flow.iq -w

test:
	mkdir -p bin
	monkeyc -f monkey.jungle -d fenix7x -t -y bin/developer_key.der -o bin/Flow-tests.prg -w
	@monkeydo bin/Flow-tests.prg fenix7x -t > bin/test-results.txt 2>&1 || true
	@cat bin/test-results.txt
	@grep -Eq '^PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)$$' bin/test-results.txt
