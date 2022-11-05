# MiSTer-ROMweasel

ROM downloader tool for MiSTer FPGA (preview version 0.9)

Thread in official MiSTer Forum: https://misterfpga.org/viewtopic.php?p=63089

## Usage

Place `romweasel.sh` to `/media/fat/Scripts` directory on the MiSTer. Run
either from shell via SSH or from the MiSTer UI.

Select ROM(s) with spacebar, usage with controller only is not (yet) supported.

## Configuration

The script sources `/media/fat/Scripts/.config/romweasel/settings.sh` for user
configurable settings, or if the file doesn't exist, creates it.

## Features

- Filter ROM lists by keyword
- Verify each ROM checksum after donwloading
- If an interrupted download is retried, attempts to continue where it left off

Licensed under BSD 2-clause license.
