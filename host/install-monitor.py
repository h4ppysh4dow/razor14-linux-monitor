#!/usr/bin/env python3
"""Update the existing Razer monitor as the logged-in desktop user."""
import argparse
import configparser
import datetime
import os
from pathlib import Path
import shutil
import subprocess

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--ssd-root',default='/mnt/external')
a=p.parse_args()
if os.geteuid()==0: raise SystemExit('Run as the desktop user, without sudo.')
if not Path(a.ssd_root).is_absolute(): raise SystemExit('SSD path must be absolute.')
home=Path.home();repo=Path(__file__).resolve().parent
for name in ['razer-cli','razor14-power-client']:
 if not (home/'.local/bin'/name).exists(): raise SystemExit('Existing Razer backend missing: '+name)
backup=home/'.local/state/rhinux'/('monitor-backup-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
def copy(source,target):
 if target.exists():
  dest=backup/target.relative_to(home);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,dest)
 target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
for name in ['razor14-thermal-status','rhinux_telemetry.py']:
 copy(repo/name,home/'.local/bin'/name)
(home/'.local/bin/razor14-thermal-status').chmod(0o755)
module=home/'.local/bin/rhinux_telemetry.py'
module.write_text(module.read_text().replace("Path('/mnt/external/shared/rhinux-telemetry/gpu.json')",'Path('+repr(str(Path(a.ssd_root)/'shared/rhinux-telemetry/gpu.json'))+')'))
for source,target in [(repo/'widget',home/'.local/share/plasma/plasmoids/local.razor14.history'),(repo/'monitor-placement',home/'.local/share/kwin/scripts/rhinux-monitor-placement')]:
 for f in source.rglob('*'):
  if f.is_file():copy(f,target/f.relative_to(source))
config=home/'.config/kwinrc'
if config.exists():
 dest=backup/'.config/kwinrc';dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(config,dest)
c=configparser.ConfigParser(interpolation=None,strict=False);c.optionxform=str;c.read(config)
if not c.has_section('Plugins'):c.add_section('Plugins')
c['Plugins']['rhinux-monitor-placementEnabled']='true'
with config.open('w') as f:c.write(f,space_around_delimiters=False)
subprocess.run(['/usr/lib64/qt6/bin/qdbus','org.kde.KWin','/KWin','org.kde.KWin.reconfigure'],check=True)
subprocess.run(['systemctl','--user','restart','plasma-plasmashell.service'],check=True)
print('Monitor updated. Backup:',backup)
