"""Read bounded, fresh guest GPU samples. Guest data is never executable."""
import json
from pathlib import Path
import time


def guest_gpu(sample=Path('/mnt/external/shared/rhinux-telemetry/gpu.json'),
              lease=Path('/run/rhinux-gpu-owner'), now=None):
    result = dict(state='Windows · wartet', source='windows', temp='—', load='—')
    try:
        now = time.time() if now is None else now
        metadata = sample.stat()
        age = now - metadata.st_mtime
        if age < -2 or age > 20 or metadata.st_mtime < lease.stat().st_mtime:
            result['state'] = 'Windows · veraltet'
            return result
        with sample.open('rb') as handle:
            payload = handle.read(4097)
        if len(payload) > 4096:
            return result
        value = json.loads(payload)
        if not isinstance(value, dict) or value.get('schema') != 1:
            return result
        temperature, load = value.get('temperature'), value.get('utilization')
        if type(temperature) is not int or type(load) is not int:
            return result
        if not 0 <= temperature <= 120 or not 0 <= load <= 100:
            return result
        result.update(state='Windows', temp=f'{temperature} °C', load=f'{load}%')
    except (OSError, ValueError, TypeError):
        pass
    return result
