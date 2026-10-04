# Fixed-purpose telemetry only: no command receiver, no credentials, no listener.
$ErrorActionPreference='Stop'
$directory='\\host.lan\Data\rhinux-telemetry'
$smi=Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'
$utf8=New-Object System.Text.UTF8Encoding($false)
while ($true) {
 try {
  $values=& $smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>$null
  if ($LASTEXITCODE -ne 0) { throw 'NVIDIA telemetry unavailable' }
  $parts=(@($values)[0] -split ',').Trim()
  $temperature=[int]$parts[0]; $load=[int]$parts[1]
  if ($temperature -lt 0 -or $temperature -gt 120 -or $load -lt 0 -or $load -gt 100) { throw 'Invalid GPU sample' }
  New-Item -ItemType Directory -Force $directory | Out-Null
  $sample=@{schema=1;temperature=$temperature;utilization=$load;utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Compress
  $temporary=Join-Path $directory "gpu-$PID.tmp"
  [System.IO.File]::WriteAllText($temporary,$sample,$utf8)
  Move-Item -Force $temporary (Join-Path $directory 'gpu.json')
 } catch { # Host discards stale samples after 20 seconds; retry when the share/GPU returns.
 }
 Start-Sleep -Seconds 5
}
