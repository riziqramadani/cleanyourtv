# CHiQ L43G7P Pro ("Zea TV") — debloat + Apple-TV launcher

What was done on **2026-10-21**, and how to undo or change any of it.

- **TV:** CHiQ L43G7P Pro, friendly name "Zea TV". Changhong **AI PONT**, device `osaka`,
  product `DVB86`, **Google TV 14** (API 34), firmware `UKNV.260603.001`, MediaTek mt5867, ~1 GB RAM.
- **IP:** `192.168.1.7`  •  **ADB:** network ADB on port 5555 (`ro.adb.secure=1`).
- **Stock launcher (disabled):** `com.google.android.apps.tv.launcherx`
- **New launcher:** `com.gathin.tvhome` (this repo's `launcher/`), Apple-TV style, set as Home.
- **Dock apps:** Netflix, YouTube (the two free dock slots auto-fill with Play Store + Settings).

Everything is reversible. Nothing was uninstalled — packages are **disabled for user 0** only.

---

## Connecting to the TV (every command below needs this)

This Mac has no working `adb` over the network (macOS Local Network privacy blocks the stock binary),
so all commands go through the Python client `tools/tv.py`. From the repo root:

```bash
export TV_HOST=192.168.1.7
tools/venv/bin/python tools/tv.py --probe      # confirm it answers
```

If port 5555 is closed (after a debugging-off / power cycle), re-enable debugging on the TV and
re-bootstrap with the stock adb once:

```bash
# On the TV: Settings > System > Developer options > Wireless debugging > Pair device with pairing code
adb pair 192.168.1.7:<pairing-port> <6-digit-code>
adb connect 192.168.1.7:<connect-port>
adb -s 192.168.1.7:<connect-port> tcpip 5555
```

Find the ports with `dns-sd -B _adb-tls-pairing._tcp local` (pairing) and
`dns-sd -L adb-<serial>-<suffix> _adb-tls-connect._tcp local` (connect).

---

## Undo everything (full restore)

Two ways. The simplest re-enables every app that was enabled at backup time and puts Home back:

```bash
TV_HOST=192.168.1.7 backups/chiq-l43g7p-20261021-161630/restore-all.sh
TV_HOST=192.168.1.7 tools/tv.py reboot
```

The precise, list-aware undo (leaves factory-disabled apps as they were):

```bash
TV_HOST=192.168.1.7 tools/restore.sh examples/chiq-l43g7p/debloat.txt com.google.android.apps.tv.launcherx
TV_HOST=192.168.1.7 tools/tv.py reboot
```

After either, press Home — the stock Google TV launcher is back. To also remove the new launcher:
`tools/tv.py 'pm uninstall com.gathin.tvhome'`.

**Re-enable the setup wizard before any factory reset:** both restores above re-enable
`com.google.android.tungsten.setupwraith`. Leaving it disabled is fine for daily use.

---

## Re-enable a single app

```bash
TV_HOST=192.168.1.7 tools/tv.py 'pm enable <package>'
```

Package names are in `packages-all.txt` (all), `packages-disabled.txt` (factory-disabled at backup).
What was disabled in this session — the categories and exact names — is in
`examples/chiq-l43g7p/debloat.txt`. Examples:

```bash
# Bring back Vidio
TV_HOST=192.168.1.7 tools/tv.py 'pm enable com.vidio.android.tv'
# Bring back the Google TV / Play Movies app
TV_HOST=192.168.1.7 tools/tv.py 'pm enable com.google.android.videos'
```

---

## Change the dock order or which apps are in the dock

Edit `launcher/app/src/main/res/values/config.xml`, the `dock_apps` array (top to bottom = left to
right in the dock). Use the package name from `tools/tv.py 'pm list packages'`. Then rebuild + install:

```xml
<string-array name="dock_apps">
    <item>com.netflix.ninja</item>
    <item>com.google.android.youtube.tv</item>
</string-array>
```

```bash
TV_HOST=192.168.1.7 JAVA_HOME="$(/usr/libexec/java_home -v 17)" \
  ANDROID_HOME=/opt/homebrew/share/android-commandlinetools \
  INPUT_KEY_SERVICE=1 launcher/build-and-install.sh
```

With fewer than 4 dock apps, the free slots auto-fill with the first grid apps (`fill_dock` = true).
Set `fill_dock` to false in config.xml to leave them empty instead.

## Change the wallpaper (no rebuild needed)

The design is a pure-black ambient background by default (no wallpaper). To set one, drop an image and
push a theme:

```bash
TV_HOST=192.168.1.7 tools/theme.sh themes/<name>     # see themes/README.md for the config.json keys
```

A theme's `config.json` can also override `dock_apps`, colours, `sky_intensity`, etc. without a rebuild.

Quickest single wallpaper (keep it dark, 1920x1080, under ~300 KB):

```bash
mkdir -p themes/mine && cp /path/to/image.jpg themes/mine/wallpaper.jpg
echo '{ "wallpaper": true, "wallpaper_dim": 40 }' > themes/mine/config.json
TV_HOST=192.168.1.7 tools/theme.sh themes/mine
```

A rotating collection: put images in `themes/mine/wallpapers/` and use
`{ "wallpaper": true, "wallpaper_rotation_minutes": 30, "wallpaper_dim": 40 }`.
On the TV, the Settings pill > Wallpaper row also picks one image or None.
Back to plain black: `TV_HOST=192.168.1.7 tools/theme.sh --reset`.

## Change the screensaver

The screensaver is set to the launcher's clean clock, `com.gathin.tvhome/.ClockDream` (the old
recommendation screensaver `dreamx` was disabled in the debloat). To change it:

```bash
# launcher clock (current)
TV_HOST=192.168.1.7 tools/tv.py 'settings put secure screensaver_components com.gathin.tvhome/.ClockDream'
# plain colours instead
TV_HOST=192.168.1.7 tools/tv.py 'settings put secure screensaver_components com.android.dreams.basic/.Colors'
# turn the screensaver off
TV_HOST=192.168.1.7 tools/tv.py 'settings put secure screensaver_enabled 0'
```

Idle timer and on/off are also under Settings > System > Screensaver on the TV.

---

## Rebuild the launcher from scratch

```bash
TV_HOST=192.168.1.7 JAVA_HOME="$(/usr/libexec/java_home -v 17)" \
  ANDROID_HOME=/opt/homebrew/share/android-commandlinetools \
  INPUT_KEY_SERVICE=1 launcher/build-and-install.sh
```

`INPUT_KEY_SERVICE=1` keeps the remote's Input button working from inside apps (Google TV routes it
through the stock launcher otherwise, which is now disabled). Re-pass it on every install — Android
switches the accessibility service off on each reinstall.

---

## Notes / quirks specific to this TV

- **Wi-Fi pill shows "Wi-Fi", not the network name.** The launcher can only read the SSID when
  Location is on. Turn on **Settings > (Device) > Location** to see "MECCA" in the pill. Cosmetic.
- **setupwraith owns Home at priority 1.** It had to be disabled alongside the stock launcher or Home
  falls to the setup wizard's RecoveryActivity. The saved Wi-Fi here belongs to `android.uid.system`
  (checked), so disabling setupwraith did NOT drop Wi-Fi. If you ever factory-reset, re-enable it first.
- **This firmware does NOT re-enable packages at boot** (checked across two reboots). No per-boot
  re-disabling needed.
- **HDMI / Live TV screenshots come out black** (protected video layer) — that's normal, not a fault.
- **Kept on purpose, despite bloaty names:** `com.mediatek.tvinput` (HDMI/AV/tuner), `com.mediatek.tv.service`,
  `com.google.android.tv.inputplayer` (input passthrough), `com.mediatek.tv.factorykey` (it registers a
  real TvInputService), `com.homwee.factory` (input-key broadcasts), `com.mediatek.wwtv.setupwizard`
  (tuner + global keys), `com.mediatek.autopair` (BT remote pairing), `com.google.android.tv.remote.service`
  (remote + mic), `com.mediatek.wwtv.tvcenter` (Live TV), the Homwee updaters, Play Services + Store,
  Chromecast (`mediashell`) and voice (`katniss`). **Never launch the factory/factorykey packages** —
  on these boards opening a factory app can flip a factory-mode flag that breaks inputs and CEC.

## Files in this backup folder

- `restore-all.sh` — one-shot full restore (re-enable everything, Home back to stock).
- `packages-*.txt` — package lists at backup time (all / enabled / disabled / system / 3rd-party).
- `getprop.txt`, `settings-*.txt` — full device properties and all three settings namespaces.
- `home-resolve.txt`, `home-claimants.txt`, `accessibility.txt` — Home + a11y state at backup.
- `disabled-before-reboot.txt` / `disabled-after-reboot.txt` — reboot-persistence check.
- `00`..`11` `*.png` — screenshots taken through the whole process.

The list-aware restore also uses a recovery record at
`~/.cleanyourtv/recovery-192.168.1.7-*.json` (created before the first change). Keep it.

---

## When you're finished: close network ADB

Leaving port 5555 open is a security hole on the LAN. When you no longer need to tweak things:

1. On the TV: **Settings > System > Developer options** → turn **USB debugging** and **Wireless
   debugging** OFF.
2. Revoke authorisations: **Developer options > Revoke USB debugging authorisations**.
3. Reboot the TV.
4. Confirm the port refuses connections (don't trust `nc` on macOS):

   ```bash
   tools/venv/bin/python tools/adb-closed.py 192.168.1.7
   ```

   "closed: the TV refused the connection" is what you want. The launcher keeps working without ADB.
