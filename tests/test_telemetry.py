import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('telemetry',Path(__file__).resolve().parents[1]/'host/rhinux_telemetry.py')
telemetry=importlib.util.module_from_spec(spec);spec.loader.exec_module(telemetry)

class TelemetryTests(unittest.TestCase):
 def test_fresh_stale_future_and_previous_vm(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp);sample=root/'gpu.json';lease=root/'lease'
   sample.write_text(json.dumps(dict(schema=1,temperature=57,utilization=36)));lease.touch()
   os.utime(lease,(90,90));os.utime(sample,(100,100))
   self.assertEqual(telemetry.guest_gpu(sample,lease,105)['load'],'36%')
   self.assertEqual(telemetry.guest_gpu(sample,lease,121)['load'],'—')
   self.assertEqual(telemetry.guest_gpu(sample,lease,95)['load'],'—')
   os.utime(lease,(101,101))
   self.assertEqual(telemetry.guest_gpu(sample,lease,105)['load'],'—')
 def test_rejects_invalid_missing_and_oversized_samples(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp);sample=root/'gpu.json';lease=root/'lease';lease.touch();os.utime(lease,(90,90))
   self.assertEqual(telemetry.guest_gpu(sample,lease,105)['temp'],'—')
   for payload in ['{}','null','[1]','bad','x'*4097,json.dumps(dict(schema=1,temperature=-1,utilization=0)),json.dumps(dict(schema=1,temperature=True,utilization=0)),json.dumps(dict(schema=1,temperature=50,utilization=101))]:
    sample.write_text(payload);os.utime(sample,(100,100))
    self.assertEqual(telemetry.guest_gpu(sample,lease,105)['temp'],'—')
