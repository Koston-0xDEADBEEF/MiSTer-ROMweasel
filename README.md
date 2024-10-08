# MiSTer-ROMweasel

ROM downloader tool for MiSTer FPGA (release version 0.9.13)

Thread in official MiSTer Forum: https://misterfpga.org/viewtopic.php?p=63089

## Usage

Place `romweasel.sh` to `/media/fat/Scripts` directory on the MiSTer. Run
either from shell via SSH or from the MiSTer UI.

Simple Mode (OFF by default) only allows downloading a single file at a time
and game list cannot be filtered, but it works with button-deprived joysticks.

MiSTer has now added support for controlling the normal mode entirely with a
joystick, including tagging multiple games at once and PgUp/PgDn. You still
won't be able to type anything, though.

On startup, ROMweasel asks if you want to re-download ROM repository metadata.
This is required, if any of the ROM repositories have been updated or the local
metadata is corrupted.

## Configuration

The script sources `/media/fat/Scripts/.config/romweasel/settings.sh` for user
configurable settings, or if the file doesn't exist, creates it.

Some game repositories on archive.org have been recently locked, meaning you
need to login to access them. Since the same problem affects other MiSTer
scripts as well, ROMweasel has adopted the same solution. Place following
lines in your `/root/.profile` file:

```
export IA_USER="login@email"
export IA_PASS="secret123"
```

If you experience problems with downloads, make sure you have the above setup
and then re-download ROM repository metadata.

## Features

- Filter ROM lists by keyword
- Separate simple mode for operating with joysticks with only few buttons
- Verify each ROM checksum after downloading
- If an interrupted download is retried, attempts to continue where it left off

## Tips

Run it from a shell via SSH, it can be left to download in the background while
you play games. Just don't cold-reboot the system.

If executed from cmdline with a directory path as argument, `.chd` files in that
directory are sorted into their own subdirectories. If it fails to automatically
determine correct subdirectory name, that file is simply not moved.

## Automatic updates

To enable experimental automatic updates via `update_all.sh`, add these lines
to your `downloader.ini` file:

```
[romweasel]
db_url = https://raw.githubusercontent.com/Koston-0xDEADBEEF/MiSTer-ROMweasel/main/romweasel.json
```


Licensed under BSD 2-clause license.
