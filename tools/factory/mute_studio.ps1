# Mute or unmute Roblox Studio's sound only (Windows volume mixer, per app), e.g. while tests play.
#   powershell -ExecutionPolicy Bypass -File tools\mute_studio.ps1           # mute every open Studio window
#   powershell -ExecutionPolicy Bypass -File tools\mute_studio.ps1 -Unmute
#   powershell -ExecutionPolicy Bypass -File tools\mute_studio.ps1 -Process chrome   # another program
# Only affects windows open now; a Studio opened later starts unmuted (test_all.py mutes the ones it opens).
param([string]$Process = 'RobloxStudioBeta', [switch]$Unmute)

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorCo {}

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator { void EnumAudioEndpoints(int flow, int mask, out IMMDeviceCollection devices); }

[Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceCollection { void GetCount(out int n); void Item(int i, out IMMDevice dev); }

[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice { void Activate(ref Guid iid, int ctx, IntPtr p, [MarshalAs(UnmanagedType.IUnknown)] out object o); }

[Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionManager2 {
  void GetAudioSessionControl(IntPtr g, int f, out IntPtr c);
  void GetSimpleAudioVolume(IntPtr g, int f, out IntPtr v);
  void GetSessionEnumerator(out IAudioSessionEnumerator e);
}

[Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionEnumerator { void GetCount(out int n); void GetSession(int i, out IAudioSessionControl2 s); }

[Guid("bfb7ff88-7239-4fc9-8fa2-07c950be9c6d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionControl2 {
  void GetState(out int s); void GetDisplayName(out IntPtr n); void SetDisplayName(IntPtr n, IntPtr g);
  void GetIconPath(out IntPtr p); void SetIconPath(IntPtr p, IntPtr g); void GetGroupingParam(out Guid g);
  void SetGroupingParam(IntPtr a, IntPtr b); void RegisterAudioSessionNotification(IntPtr n);
  void UnregisterAudioSessionNotification(IntPtr n); void GetSessionIdentifier(out IntPtr s);
  void GetSessionInstanceIdentifier(out IntPtr s); void GetProcessId(out uint pid);
}

[Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface ISimpleAudioVolume {
  void SetMasterVolume(float v, ref Guid ctx); void GetMasterVolume(out float v);
  void SetMute([MarshalAs(UnmanagedType.Bool)] bool m, ref Guid ctx); void GetMute([MarshalAs(UnmanagedType.Bool)] out bool m);
}

public static class AppMute {
  // Sets mute on every audio session (all output devices) owned by one of the pids; returns how many it changed.
  public static int Set(HashSet<uint> pids, bool mute) {
    var en = (IMMDeviceEnumerator)new MMDeviceEnumeratorCo();
    IMMDeviceCollection devs; en.EnumAudioEndpoints(0, 1, out devs);  // render, active
    int nd; devs.GetCount(out nd); int hit = 0;
    for (int d = 0; d < nd; d++) {
      IMMDevice dev; devs.Item(d, out dev);
      Guid iid = typeof(IAudioSessionManager2).GUID; object o;
      dev.Activate(ref iid, 23, IntPtr.Zero, out o);  // CLSCTX_ALL
      IAudioSessionEnumerator se; ((IAudioSessionManager2)o).GetSessionEnumerator(out se);
      int ns; se.GetCount(out ns);
      for (int i = 0; i < ns; i++) {
        IAudioSessionControl2 s; se.GetSession(i, out s);
        uint pid; s.GetProcessId(out pid);
        if (!pids.Contains(pid)) continue;
        Guid none = Guid.Empty; ((ISimpleAudioVolume)s).SetMute(mute, ref none); hit++;
      }
    }
    return hit;
  }
}
'@

$procs = @(Get-Process -Name $Process -ErrorAction SilentlyContinue)
if (-not $procs) { Write-Output "$Process is not running"; exit 1 }
$pids = New-Object 'System.Collections.Generic.HashSet[uint32]'
$procs | ForEach-Object { [void]$pids.Add([uint32]$_.Id) }
$n = [AppMute]::Set($pids, -not $Unmute)
$what = if ($Unmute) { 'unmuted' } else { 'muted' }
if ($n -eq 0) { Write-Output "$Process has no open audio session yet (it opens one when it first plays sound): nothing $what"; exit 2 }
Write-Output "$Process $what ($n audio session(s))"
