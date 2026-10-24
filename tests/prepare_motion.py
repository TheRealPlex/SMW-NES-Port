#!/usr/bin/env python3
import json
from pathlib import Path
r=json.loads(Path('tests/fixtures/smw-motion-reference.json').read_text())
def lua(x):
 if isinstance(x,str):return json.dumps(x)
 if isinstance(x,list):return '{'+','.join(lua(v) for v in x)+'}'
 if isinstance(x,dict):return '{'+','.join(k+'='+lua(v) for k,v in x.items())+'}'
 return str(x)
Path('build/motion-reference.lua').write_text('return '+lua(r['cases'])+'\n')
