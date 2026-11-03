#!/usr/bin/env python3
"""Install the Android example and verify real logcat output."""

import argparse
import pathlib
import re
import shutil
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
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
            [args.adb, "-s", args.serial, *command], text=True, stderr=subprocess.STDOUT)

    package = "dev.nanaloveyuki.runtimebinding.demo"
    print(adb("install", "-r", apk_path), end="")
    expected = {
        ("V", "smoke verbose"), ("D", "smoke debug"),
        ("I", "smoke info"), ("W", "smoke warn"),
        ("E", "smoke error"), ("I", "资源索引 ready: 月亮 🌙"),
        ("I", "pre-init rejected: NotInitialized"),
        ("I", "PASS android-log"),
    }
    for run in range(1, 3):
        adb("shell", "am", "force-stop", package)
        adb("logcat", "-c")
        print(adb("shell", "am", "start", "-W", "-n", f"{package}/.MainActivity"), end="")
        deadline = time.monotonic() + 15
        while True:
            logs = adb("logcat", "-d", "-v", "brief", "RuntimeBindingSmoke:V", "AndroidRuntime:E", "*:S")
            messages = set(re.findall(r"^([VDIWE])/RuntimeBindingSmoke\s*\(\s*\d+\): (.*)$", logs, re.MULTILINE))
            if expected <= messages:
                print(logs, end="")
                print(f"PASS launch {run}: five priorities, Unicode, and pre-initialization rejection")
                break
            if "FAIL" in logs or "FATAL EXCEPTION" in logs or time.monotonic() >= deadline:
                raise SystemExit(f"Android log smoke failed; missing {expected - messages}\n{logs}")
            time.sleep(0.25)


if __name__ == "__main__":
    main()
