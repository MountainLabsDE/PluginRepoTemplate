#!/usr/bin/env python3
"""Test module validator for GitHub Actions CI"""
import json, sys, os

uplugin_file = os.environ.get('UPLUGIN', 'UniversalInteractionSystem.uplugin')

if not os.path.exists(uplugin_file):
    print(f"::error::Plugin file not found: {uplugin_file}")
    sys.exit(1)

with open(uplugin_file) as f:
    data = json.load(f)

modules = [m['Name'] for m in data.get('Modules', [])]
if 'UniversalInteractionSystemTests' not in modules:
    print('::error::UniversalInteractionSystemTests module not registered in UniversalInteractionSystem.uplugin')
    sys.exit(1)

test_mod = next(m for m in data['Modules'] if m['Name'] == 'UniversalInteractionSystemTests')
if test_mod.get('Type') != 'Editor':
    print('::warning::UniversalInteractionSystemTests module should be Type: Editor (not Runtime)')
    
print(f'✓ Test module registered as: {test_mod["Type"]} (LoadingPhase: {test_mod["LoadingPhase"]})')
print(f'✓ Available modules: {", ".join(modules)}')
sys.exit(0)