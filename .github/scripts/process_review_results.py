#!/usr/bin/env python3
"""Review result processor for GitHub Actions CI"""
import json, sys

try:
    results = json.load(sys.stdin)
except json.JSONDecodeError:
    print("Error: Invalid JSON input")
    sys.exit(1)

for check in results.get('checks', []):
    status = check.get('status', '?')
    name = check.get('name', 'unknown')
    desc = check.get('description', '')
    icon = {'pass': 'PASS', 'fail': 'FAIL', 'warn': 'WARN', 'skip': 'SKIP'}.get(status, '????')
    print(f'  [{icon}] {name}: {desc}')

failed = [c for c in results.get('checks', []) if c.get('status') == 'fail']
if failed:
    print(f'\nFAIL: {len(failed)} check(s) failed')
    sys.exit(1)
else:
    print('\nAll checks passed')
    sys.exit(0)