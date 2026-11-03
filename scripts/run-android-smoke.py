#!/usr/bin/env python3
"""Install the Android example and verify real logcat output."""

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--adb-port", type=int, default=5037)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--apk", type=pathlib.Path, default=pathlib.Path(
        "examples/android/app/build/outputs/apk/debug/app-debug.apk"))
    args = parser.parse_args()
    apk = args.apk.resolve(strict=True)
    if args.adb.endswith(".exe") and shutil.which("wslpath"):
        apk_path = subprocess.check_output(["wslpath", "-w", str(apk)], text=True).strip()
    else:
        apk_path = str(apk)

    def adb(*command):
        return subprocess.check_output(
            [args.adb, "-P", str(args.adb_port), "-s", args.serial, *command], text=True, stderr=subprocess.STDOUT)

    package = "dev.nanaloveyuki.runtimebinding.demo"
    print(adb("install", "-r", apk_path), end="")
    expected = {
        ("V", "smoke trace"), ("D", "smoke debug"),
        ("I", "smoke info"), ("W", "smoke warn"),
        ("E", "smoke error"), ("I", "资源索引 ready: 月亮 🌙"),
        ("I", "pre-init rejected: NotInitialized"),
        ("I", "target override"),
        ("I", "PASS android-context"),
        ("I", "PASS android-log"),
    }
    for run in range(1, 3):
        adb("shell", "am", "force-stop", package)
        adb("logcat", "-c")
        print(adb("shell", "am", "start", "-W", "-n", f"{package}/.MainActivity"), end="")
        deadline = time.monotonic() + 15
        while True:
            logs = adb("logcat", "-d", "-v", "brief", "RuntimeBinding:V", "AndroidRuntime:E", "*:S")
            records = [
                (priority, json.loads(payload))
                for priority, payload in re.findall(
                    r"^([VDIWE])/RuntimeBinding\s*\(\s*\d+\): (.*)$", logs, re.MULTILINE)
            ]
            messages = {(priority, record["message"]) for priority, record in records}
            for priority, record in records:
                if record["message"] == "must be filtered":
                    raise SystemExit("Filtered record reached Android logcat")
                target = "ResourceIndex" if record["message"] == "target override" else "RuntimeBindingSmoke"
                if record.get("target") != target:
                    raise SystemExit(f"Record target was lost: {record}")
                levels = {"V": "TRACE", "D": "DEBUG", "I": "INFO", "W": "WARN", "E": "ERROR"}
                if record["level"] != levels[priority]:
                    raise SystemExit(f"Wrong Android priority for record: {record}")
                if record["message"] == "资源索引 ready: 月亮 🌙" and record["fields"] != {"resource_count": "1"}:
                    raise SystemExit(f"Structured fields were lost: {record}")
            if expected <= messages:
                print(logs, end="")
                print(f"PASS launch {run}: application Context, priorities, Unicode, fields, targets, filtering, and pre-init rejection")
                break
            if "FAIL" in logs or "FATAL EXCEPTION" in logs or time.monotonic() >= deadline:
                raise SystemExit(f"Android log smoke failed; missing {expected - messages}\n{logs}")
            time.sleep(0.25)


if __name__ == "__main__":
    main()
