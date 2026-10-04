Local Blade 14 (1532:0270) tachometer extension

Base commit: 2c224ef.
Read actual speeds: ~/.local/bin/razer-cli read actual-fan
Protocol: class 0x0d, command 0x88, size 4, args [0, zone]; zones 1 and 2. RPM is reply args[2] * 100, resolution 100 RPM.
Validated on this device: maximum readings 5000/4900, automatic readings 4300/4400. These are distinct from commanded setpoints. Physical CPU/GPU fan mapping not established.
Protocol reference: https://github.com/TimandXiyu/razerblade-cli (Blade 16; independently verified here on Blade 14).
Queries run through the existing daemon to serialize hardware access. Failed readings are null, not zero. Original IPC variants retain ordering; new variants appended.
Installed widget: ~/.local/share/plasma/plasmoids/local.razor14.cooling
Helper: ~/.local/bin/razor14-thermal-status
Original binaries: ~/.local/bin/*.before-tachometer
Local source changes must be retained/reapplied when updating upstream.

RTX idle diagnosis: runtime D3 fine-grained already enabled (DynamicPowerManagement=3, power/control=auto). ksystemstats spawned nvidia-smi dmon every 2 seconds and kept GPU active. Pausing widget-only queries did not resolve it; temporarily pausing ksystemstats did. Reloading plasma-plasmashell released stale sensor subscriptions after old standard widgets were removed. ksystemstats restored, runtime mask removed, widget polling restored with suspended guard. New widget ID local.razor14.monitor, blue text mode indicator. No kernel/NVIDIA module configuration changes. Recheck after game exit and external-monitor removal; battery-life improvement not measured.
