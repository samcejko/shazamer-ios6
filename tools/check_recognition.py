"""Integration check: send the app's native fingerprint, never a replacement implementation."""
import base64
import json
import struct
import sys
import time
import uuid
from pathlib import Path
from urllib.request import Request, urlopen

binary = Path(sys.argv[1]).read_bytes()
samples = struct.unpack_from('<I', binary, 40)[0] - 3840
timestamp = int(time.time() * 1000)
body = {
    'signature': {'samplems': samples * 1000 // 16000, 'timestamp': timestamp,
                  'uri': 'data:audio/vnd.shazam.sig;base64,' + base64.b64encode(binary).decode()},
    'timestamp': timestamp, 'timezone': 'Europe/Prague',
}
url = ('https://amp.shazam.com/discovery/v5/en/US/android/-/tag/'
       f'{str(uuid.uuid4()).upper()}/{uuid.uuid4()}?sync=true&webv3=true&sampling=true')
request = Request(url, data=json.dumps(body).encode(), headers={
    'Content-Type': 'application/json', 'Content-Language': 'en_US',
    'User-Agent': 'Shazam/14.2.0 (iPhone; iOS 14.2; Scale/2.00)',
})
with urlopen(request, timeout=45) as response:
    result = json.load(response)
track = result.get('track') or {}
if not track.get('title') or not track.get('subtitle'):
    raise SystemExit('Native fingerprint was not recognized: ' + str(list(result)))
print('Live recognition PASS:', track['title'], '—', track['subtitle'])
