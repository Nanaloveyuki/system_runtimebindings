#!/usr/bin/env python3
"""Install the HiLog example and verify structured records across two launches."""

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--hdc', default='hdc')
    parser.add_argument('--target', required=True)
    parser.add_argument('--hap', type=Path, default=Path('examples/ohos/_build/artifacts/entry-default-unsigned.hap'))
    args = parser.parse_args()
    hap = str(args.hap.resolve(strict=True))
    if args.hdc.endswith('.exe') and shutil.which('wslpath'):
        hap = subprocess.check_output(['wslpath', '-w', hap], text=True).strip()

    def hdc(*command):
        return subprocess.check_output([args.hdc, '-t', args.target, *command], text=True, stderr=subprocess.STDOUT, timeout=30)

    print(hdc('install', '-r', hap), end='')
    expected = {
        'smoke trace': ('D', 'TRACE'), 'smoke debug': ('D', 'DEBUG'),
        'smoke info': ('I', 'INFO'), 'smoke warn': ('W', 'WARN'),
        'smoke error': ('E', 'ERROR'), '资源索引 ready: 月亮 🌙': ('I', 'INFO'),
        'target override': ('I', 'INFO'), 'PASS ohos-log': ('I', 'INFO'),
    }
    for launch in range(1, 3):
        hdc('shell', 'aa', 'force-stop', 'com.moonohos.runtimebinding')
        hdc('shell', 'hilog', '-r')
        print(hdc('shell', 'aa', 'start', '-b', 'com.moonohos.runtimebinding', '-a', 'EntryAbility'), end='')
        deadline = time.monotonic() + 15
        while True:
            logs = hdc('shell', 'hilog', '-x', '-t', 'app', '-T', 'RuntimeBinding')
            records = [(priority, json.loads(payload)) for priority, payload in re.findall(r'\s([DIWEF]) A05254/RuntimeBinding: (.+)$', logs, re.MULTILINE)]
            observed = {}
            for priority, record in records:
                message = record['message']
                if message not in expected:
                    raise SystemExit(f'Unexpected record: {record}')
                if (priority, record['level']) != expected[message]:
                    raise SystemExit(f'Wrong severity: {record}')
                target = 'ResourceIndex' if message == 'target override' else 'RuntimeBindingSmoke'
                if record['target'] != target:
                    raise SystemExit(f'Lost target: {record}')
                fields = {'resource_count': '1'} if message == '资源索引 ready: 月亮 🌙' else {}
                if record['fields'] != fields:
                    raise SystemExit(f'Lost fields: {record}')
                observed[message] = True
            if expected.keys() <= observed.keys():
                print(logs, end='')
                print(f'PASS launch {launch}: severity mapping, Unicode, fields, targets, filtering, ArkTS-to-MoonBit call')
                break
            if time.monotonic() >= deadline:
                raise SystemExit(f'Missing records: {expected.keys() - observed.keys()}\n{logs}')
            time.sleep(0.25)


if __name__ == '__main__':
    main()
