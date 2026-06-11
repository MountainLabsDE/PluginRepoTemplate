#!/usr/bin/env python3
"""C++ syntax checker for GitHub Actions CI"""
import re, sys, os

file_path = os.environ.get('FILE', '')

if not file_path or not os.path.exists(file_path):
    print(f"::error file={file_path}::Invalid file path")
    sys.exit(1)

with open(file_path) as f:
    content = f.read()

errors = []
warnings = []

# Check for unmatched braces (rough check)
open_braces = content.count('{')
close_braces = content.count('}')
if open_braces != close_braces:
    errors.append(f'Unmatched braces: {{ = {open_braces}, }} = {close_braces}}')

# Check for unterminated strings (simple heuristic)
lines = content.split('\n')
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    # Skip comments
    if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
        continue
    # Check for missing semicolons after statements (heuristic)
    if re.search(r'^\s*(return|break|continue)\s*[^;{]\s*$', line) and 'return' not in stripped:
        warnings.append(f'Line {i}: possible missing semicolon')

for e in errors:
    print(f'::error file={file_path}::{e}')
for w in warnings:
    print(f'::warning file={file_path}::{w}')

sys.exit(len(errors))