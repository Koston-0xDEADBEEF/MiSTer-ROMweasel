# MiSTer-ROMweasel

ROM downloader tool for MiSTer FPGA (preview version 0.9.5)

Thread in official MiSTer Forum: https://misterfpga.org/viewtopic.php?p=63089

## Usage

Place `romweasel.sh` to `/media/fat/Scripts` directory on the MiSTer. Run
either from shell via SSH or from the MiSTer UI.

Simple Mode (on by default) only allows downloading a single file at a time
and game list cannot be filtered, but it works entirely with a joystick.

Use normal mode with a keyboard for more features.

## Configuration

The script sources `/media/fat/Scripts/.config/romweasel/settings.sh` for user
configurable settings, or if the file doesn't exist, creates it.

## Features

- Filter ROM lists by keyword
- Separate simpler mode for joystic-only operation
- Verify each ROM checksum after donwloading
- If an interrupted download is retried, attempts to continue where it left off

## Tips

Run it from a shell via SSH, it can be left to download in the background while
you play games. Just don't cold-reboot the system.

If executed from cmdline with a directory path as argument, `.chd` files in that
directory are sorted into their own subdirectories. If it fails to automatically
determine correct subdirectory name, that file is simply not moved.

Licensed under BSD 2-clause license.
