#!/usr/bin/env python3
"""Publish the HarmonyOS module from a staged copy.

`ohos_runtimebinding` lives inside the Android module directory, and `moon`
applies ancestor `.moonignore` rules when packaging. The Android module must
exclude that directory from its own package, which in turn makes a nested
`moon publish` produce an empty zip. Staging the module in a temporary
directory breaks that inheritance and produces the expected package.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

MODULE_FILES = ["moon.mod", "moon.work", ".moonignore", "LICENSE", "README.md"]
MODULE_DIRS = ["src"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="validate the package without publishing")
    parser.add_argument("--module", type=Path, default=Path(__file__).resolve().parent.parent / "ohos_runtimebinding")
    args = parser.parse_args()

    module = args.module.resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix="ohos-publish-") as scratch:
        staging = Path(scratch) / module.name
        staging.mkdir()
        for name in MODULE_FILES:
            source = module / name
            if source.is_file():
                shutil.copy2(source, staging / name)
        for name in MODULE_DIRS:
            source = module / name
            if source.is_dir():
                shutil.copytree(source, staging / name, ignore=shutil.ignore_patterns("_build", ".mooncakes"))
        if not (staging / "moon.mod").is_file():
            raise SystemExit(f"staged module is missing moon.mod: {staging}")

        command = ["moon", "publish"]
        if args.dry_run:
            command.append("--dry-run")
        completed = subprocess.run(command, cwd=staging)
        if completed.returncode != 0:
            return completed.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main())
