#!/bin/zsh

# Script sets its own options and restores caller options on exit
setopt localoptions extendedglob pipefail warnnestedvar nullglob

# Initialise all readonly global variables
init_static_globals () {
    typeset -gr ROMWEASEL_VERSION="MiSTer ROMweasel v0.9.13"

    # Required software to run
    typeset -gr XMLLINT=$(which xmllint)    || { print "ERROR: 'xmllint' not found" ; return 1 }
    typeset -gr CURL=$(which curl)          || { print "ERROR: 'curl' not found" ; return 1 }
    typeset -gr DIALOG=$(which dialog)      || { print "ERROR: 'dialog' not found" ; return 1 }
    typeset -gr SHA1SUM=$(which sha1sum)    || { print "ERROR: 'sha1sum' not found" ; return 1 }
    typeset -gr SZR=$(which 7zr)            || { print "ERROR: '7zr' not found" ; return 1 }
    # Why use zip. Sigh.
    typeset -gr UNZIP=$(which unzip)        || { print "ERROR: 'unzip' not found" ; return 1 }
    typeset -gr NUMFMT=$(which numfmt)      || { print "ERROR: 'numfmt' not found" ; return 1 }
    typeset -gr BC=$(which bc)              || { print "ERROR: 'bc' not found" ; return 1 }
    typeset -gr JQ=$(which jq)              || { print "ERROR: 'jq' not found" ; return 1 }

    # Stash all metadata here
    typeset -gr WRK_DIR="/media/fat/Scripts/.config/romweasel"
    #typeset -gr WRK_DIR="$(PWD)/metadata"
    # User configurable settings
    typeset -gr SETTINGS_SH="${WRK_DIR}/settings.sh"
    # Temporary location for compressed ROMs
    typeset -gr CACHE_DIR="${WRK_DIR}/cache"
    # If this file exists, skip downloading XML metadata files
    typeset -gr DLDONE="${WRK_DIR}/.dl_done"

    # Supported ROM repositories
    typeset -gra SUPPORTED_CORES=( \
        "NES"       "Nintendo Entertainment System" \
        "SNES"      "Super Nintendo" \
        "N64"       "Nintendo 64" \
        "GB"        "Nintendo GameBoy" \
        "GBC"       "Nintendo GameBoy Color" \
        "GBA"       "GameBoy Advance" \
        "TG16"      "NEC TurboGrafx16 / PC-Engine" \
        "TG16CD"    "NEC TurboGrafx16-CD / PC-Engine CD" \
        "SMS"       "SEGA Master System" \
        "GG"        "SEGA Game Gear" \
        "MD"        "SEGA Mega Drive" \
        "MCD"       "SEGA MegaCD / SegaCD" \
        "SS"        "SEGA Saturn" \
        "PSXUS"     "Sony PlayStation USA" \
        "PSXEU"     "Sony PlayStation Europe" \
        "PSXJP"     "Sony PlayStation Japan" \
        "PSXJP2"    "Sony PlayStation Japan #2" \
        "PSXMISC"   "Sony PlayStation Miscellaneous" \
        "AO486"     "0MHz DOS Collection" \
        "CD32"      "Amiga CD32" \
        "GNW"       "Game & Watch" \
        "WS"        "WonderSwan" \
        "WSC"       "WonderSwan Color" \
        "PV1000"    "Casio PV-1000" \
    )

    # The prefix "NAME_" must match the core name in above list
    typeset -gr NES_URL="https://archive.org/download/nointro.nes-headered"
    typeset -gr NES_FILES_XML="nointro.nes-headered_files.xml"
    typeset -gr NES_META_XML="nointro.nes-headered_meta.xml"
    typeset -gr SNES_URL="https://archive.org/download/nointro.snes"
    typeset -gr SNES_FILES_XML="nointro.snes_files.xml"
    typeset -gr SNES_META_XML="nointro.snes_meta.xml"
    typeset -gr N64_URL="https://archive.org/download/nointro.n64"
    typeset -gr N64_FILES_XML="nointro.n64_files.xml"
    typeset -gr N64_META_XML="nointro.n64_meta.xml"
    typeset -gr GB_URL="https://archive.org/download/nointro.gb"
    typeset -gr GB_FILES_XML="nointro.gb_files.xml"
    typeset -gr GB_META_XML="nointro.gb_meta.xml"
    typeset -gr GBC_URL="https://archive.org/download/nointro.gbc"
    typeset -gr GBC_FILES_XML="nointro.gbc_files.xml"
    typeset -gr GBC_META_XML="nointro.gbc_meta.xml"
    typeset -gr GBA_URL="https://archive.org/download/nointro.gba"
    typeset -gr GBA_FILES_XML="nointro.gba_files.xml"
    typeset -gr GBA_META_XML="nointro.gba_meta.xml"
    typeset -gr TG16_URL="https://archive.org/download/nointro.tg-16"
    typeset -gr TG16_FILES_XML="nointro.tg-16_files.xml"
    typeset -gr TG16_META_XML="nointro.tg-16_meta.xml"
    typeset -gr TG16CD_URL="https://archive.org/download/chd_pcecd"
    typeset -gr TG16CD_FILES_XML="chd_pcecd_files.xml"
    typeset -gr TG16CD_META_XML="chd_pcecd_meta.xml"
    typeset -gr SMS_URL="https://archive.org/download/nointro.ms-mkiii"
    typeset -gr SMS_FILES_XML="nointro.ms-mkiii_files.xml"
    typeset -gr SMS_META_XML="nointro.ms-mkiii_meta.xml"
    typeset -gr GG_URL="https://archive.org/download/nointro.gg"
    typeset -gr GG_FILES_XML="nointro.gg_files.xml"
    typeset -gr GG_META_XML="nointro.gg_meta.xml"
    typeset -gr MD_URL="https://archive.org/download/nointro.md"
    typeset -gr MD_FILES_XML="nointro.md_files.xml"
    typeset -gr MD_META_XML="nointro.md_meta.xml"
    typeset -gr MCD_URL="https://archive.org/download/chd_segacd"
    typeset -gr MCD_FILES_XML="chd_segacd_files.xml"
    typeset -gr MCD_META_XML="chd_segacd_meta.xml"
    typeset -gr SS_URL="https://archive.org/download/chd_saturn"
    typeset -gr SS_FILES_XML="chd_saturn_files.xml"
    typeset -gr SS_META_XML="chd_saturn_meta.xml"
    typeset -gr PSXUS_URL="https://archive.org/download/chd_psx"
    typeset -gr PSXUS_FILES_XML="chd_psx_files.xml"
    typeset -gr PSXUS_META_XML="chd_psx_meta.xml"
    typeset -gr PSXEU_URL="https://archive.org/download/chd_psx_eur"
    typeset -gr PSXEU_FILES_XML="chd_psx_eur_files.xml"
    typeset -gr PSXEU_META_XML="chd_psx_eur_meta.xml"
    typeset -gr PSXJP_URL="https://archive.org/download/chd_psx_jap"
    typeset -gr PSXJP_FILES_XML="chd_psx_jap_files.xml"
    typeset -gr PSXJP_META_XML="chd_psx_jap_meta.xml"
    typeset -gr PSXJP2_URL="https://archive.org/download/chd_psx_jap_p2"
    typeset -gr PSXJP2_FILES_XML="chd_psx_jap_p2_files.xml"
    typeset -gr PSXJP2_META_XML="chd_psx_jap_p2_meta.xml"
    typeset -gr PSXMISC_URL="https://archive.org/download/chd_psx_misc"
    typeset -gr PSXMISC_FILES_XML="chd_psx_misc_files.xml"
    typeset -gr PSXMISC_META_XML="chd_psx_misc_meta.xml"
    typeset -gr AO486_URL="https://archive.org/download/0mhz-dos"
    typeset -gr AO486_FILES_XML="0mhz-dos_files.xml"
    typeset -gr AO486_META_XML="0mhz-dos_meta.xml"
    typeset -gr CD32_URL="https://archive.org/download/commodore-amiga-cd32-redump-collection"
    typeset -gr CD32_FILES_XML="commodore-amiga-cd32-redump-collection_files.xml"
    typeset -gr CD32_META_XML="commodore-amiga-cd32-redump-collection_meta.xml"
    typeset -gr GNW_URL="https://archive.org/download/gnw-games"
    typeset -gr GNW_FILES_XML="gnw-games_files.xml"
    typeset -gr GNW_META_XML="gnw-games_meta.xml"
    typeset -gr WS_URL="https://archive.org/download/nointro-bandai-wonderswanwonderswan-color"
    typeset -gr WS_FILES_XML="nointro-bandai-wonderswanwonderswan-color_files.xml"
    typeset -gr WS_META_XML="nointro-bandai-wonderswanwonderswan-color_meta.xml"
    typeset -gr WSC_URL="https://archive.org/download/nointro-bandai-wonderswanwonderswan-color"
    typeset -gr WSC_FILES_XML="nointro-bandai-wonderswanwonderswan-color_files.xml"
    typeset -gr WSC_META_XML="nointro-bandai-wonderswanwonderswan-color_meta.xml"
    typeset -gr PV1000_URL="https://archive.org/download/nointro-casio-loopy-pv-1000"
    typeset -gr PV1000_FILES_XML="nointro-casio-loopy-pv-1000_files.xml"
    typeset -gr PV1000_META_XML="nointro-casio-loopy-pv-1000_meta.xml"

    # Dialog box maximum size, leave a small border in case of overscan
    typeset -gr MAXHEIGHT=$(( $LINES - 4 ))
    typeset -gr MAXWIDTH=$(( $COLUMNS - 4 ))

    typeset -gr DIALOG_OK=0
    typeset -gr DIALOG_CANCEL=1
    typeset -gr DIALOG_HELP=2
    typeset -gr DIALOG_EXTRA=3
    typeset -gr DIALOG_ITEM_HELP=4
    typeset -gr DIALOG_ESC=255

    # Fixes ncurses output with many terminals (eg. PuTTY)
    typeset -grx NCURSES_NO_UTF8_ACS=1
    #export NCURSES_NO_UTF8_ACS

    # Common curl options
    typeset -ga CURL_OPTS=(--connect-timeout 5 --retry 3 --retry-delay 5)

    # dialog(1) writes results to a tempfile via stderr
    typeset -gr DIALOG_TEMPFILE=$(mktemp 2>/dev/null) || DIALOG_TEMPFILE=/tmp/test$$

    typeset -gr SIG_NONE=0
    typeset -gr SIG_HUP=1
    typeset -gr SIG_INT=2
    typeset -gr SIG_QUIT=3
    typeset -gr SIG_KILL=9
    typeset -gr SIG_TERM=15
}

# User configurable options
set_conf_opts () {
    typeset -gr NES_GAMEDIR=${NES_GAMEDIR:-/media/fat/games/NES}
    typeset -gr SNES_GAMEDIR=${SNES_GAMEDIR:-/media/fat/games/SNES}
    typeset -gr N64_GAMEDIR=${N64_GAMEDIR:-/media/fat/games/N64}
    typeset -gr GB_GAMEDIR=${GB_GAMEDIR:-/media/fat/games/GAMEBOY}
    typeset -gr GBC_GAMEDIR=${GBC_GAMEDIR:-/media/fat/games/GAMEBOY}
    typeset -gr GBA_GAMEDIR=${GBA_GAMEDIR:-/media/fat/games/GBA}
    typeset -gr TG16_GAMEDIR=${TG16_GAMEDIR:-/media/fat/games/TGFX16}
    typeset -gr TG16CD_GAMEDIR=${TG16CD_GAMEDIR:-/media/fat/games/TGFX16-CD}
    typeset -gr SMS_GAMEDIR=${SMS_GAMEDIR:-/media/fat/games/SMS}
    typeset -gr GG_GAMEDIR=${GG_GAMEDIR:-/media/fat/games/SMS}
    typeset -gr MD_GAMEDIR=${MD_GAMEDIR:-/media/fat/games/MegaDrive}
    typeset -gr MCD_GAMEDIR=${MCD_GAMEDIR:-/media/fat/games/MegaCD}
    typeset -gr SS_GAMEDIR=${SS_GAMEDIR:-/media/fat/games/Saturn}
    typeset -gr PSXUS_GAMEDIR=${PSXUS_GAMEDIR:-/media/fat/games/PSX}
    typeset -gr PSXEU_GAMEDIR=${PSXEU_GAMEDIR:-/media/fat/games/PSX}
    typeset -gr PSXJP_GAMEDIR=${PSXJP_GAMEDIR:-/media/fat/games/PSX}
    typeset -gr PSXJP2_GAMEDIR=${PSXJP2_GAMEDIR:-/media/fat/games/PSX}
    typeset -gr PSXMISC_GAMEDIR=${PSXMISC_GAMEDIR:-/media/fat/games/PSX}
    # The 0MHz DOS zips have required directory structure builtin (smart!)
    typeset -gr AO486_GAMEDIR=${AO486_GAMEDIR:-/media/fat}
    typeset -gr CD32_GAMEDIR=${CD32_GAMEDIR:-/media/fat/games/AmigaCD32}
    typeset -gr GNW_GAMEDIR=${GNW_GAMEDIR:-/media/fat/games/GameNWatch}
    typeset -gr WS_GAMEDIR=${WS_GAMEDIR:-/media/fat/games/WonderSwan}
    typeset -gr WSC_GAMEDIR=${WSC_GAMEDIR:-/media/fat/games/WonderSwanColor}
    typeset -gr PV1000_GAMEDIR=${PV1000_GAMEDIR:-/media/fat/games/Casio_PV-1000}
    # Simplified mode for use without a keyboard (true/false toggle)
    typeset -g JOY_MODE=${JOY_MODE:-false}
}

# Dynamically set environment variables to point to currently selected repository
select_core () {
    typeset -g CORE=${1}
    typeset -g CORE_URL=${(P)${:-${CORE}_URL}}
    typeset -g CORE_GAMEDIR=${(P)${:-${CORE}_GAMEDIR}}
    typeset -g CORE_FILES_XML=${(P)${:-${CORE}_FILES_XML}}
    typeset -g CORE_META_XML=${(P)${:-${CORE}_META_XML}}
}

get_config () {
    typeset -g TITLE=${ROMWEASEL_VERSION}
    if [[ -f ${SETTINGS_SH} ]]; then
        local t=$(source ${SETTINGS_SH} 2>&1)
        [[ -n $t ]] && { print "Error parsing user configuration file: $t" ; cleanup }
        source ${SETTINGS_SH}
        set_conf_opts ; return
    fi

    # If configuration ddfile doesn't exist, create one from scratch
    set_conf_opts
    tmpl=("# Automatically generated romweasel configuration template\n")
    tmpl+="# Root directories per core / ROM repository"
    for (( i=1; i<${#SUPPORTED_CORES}; i+=2 )) ; do
        tmpl+="#${SUPPORTED_CORES[i]}_GAMEDIR=\"${(P)${:-${SUPPORTED_CORES[i]}_GAMEDIR}}\""
    done
    tmpl+="\n# Simplified mode for use without a keyboard (true/false)"
    tmpl+="#JOY_MODE=false"
    print -l $tmpl > ${SETTINGS_SH}
    unset tmpl i
}

# Helper functions, fetch metadata from XML based on tag name (always same as full path filename)
get_tag_filename () {
    local tag="${1}"
    # This should always just return same as input was
    print $($XMLLINT ${CORE_FILES_XML} --xpath "string(files/file[@name=\""$tag"\"]/@name)")
}
get_tag_filesize () {
    local tag="${1}"
    local human_readable=${2:-false}
    local res=$($XMLLINT ${CORE_FILES_XML} --xpath "string(files/file[@name=\""$tag"\"]/size)")
    $human_readable && print $(humanise $res) || print $res
}
get_tag_sha1sum () {
    local tag="${1}"
    print $($XMLLINT ${CORE_FILES_XML} --xpath "string(files/file[@name=\""$tag"\"]/sha1)")
}

# Convert input bytes into more human-readable form
humanise () { print $(${NUMFMT} --to=iec-i --suffix=B --format="%9.2f" ${1}) }

# URL encode a string, including parenthesis but not a slash
urlencode () {
    local input=(${(s::)1})
    # Set by backreference glob (#b), and since they get set for each character to
    # encode, option WARN_NESTED_VAR will complain loudly if they're not declared local.
    local match mbegin mend
    print ${(j::)input/(#b)([^A-Za-z0-9_.!~*\-\/])/%${(l:2::0:)$(([##16]#match))}}
}

cleanup () {
    [[ -f $DIALOG_TEMPFILE ]] && rm $DIALOG_TEMPFILE
    [[ -f cookie.tmp ]] && rm cookie.tmp
    [[ $(ls -A $CACHE_DIR) ]] && print "Warning: cache dir $CACHE_DIR not empty"
    exit 0
}

# Login to archive.org and setup a cookie for all downloads, if IA_USER/IA_PASS
# variables are set.
ia_login () {
    # Variables are sourced from ~/.profile by other scripts as well
    if [[ -f ~/.profile ]]; then source ~/.profile; fi
    if [[ -z $IA_USER ]] || [[ -z $IA_PASS ]]; then return; fi

    unsetopt warnnestedvar
    CURL_OPTS+=(-c cookie.tmp -b cookie.tmp)
    setopt warnnestedvar

    local u=$(urlencode "$IA_USER")
    local p=$(urlencode "$IA_PASS")

    # Capture login results to a temporary file
    local tmpf=$(mktemp) ; exec 5>$tmpf
    {
        # Initiate login process (session id and that shazba)
        print "Initializing session.."
        $CURL $CURL_OPTS -skLo /dev/null https://archive.org/account/login
        # Send credentials
        print "Sending credentials.."
        $CURL $CURL_OPTS -skL -X POST \
            --data-raw "username=$u&password=$p&remember=true" \
            https://archive.org/account/login 2>&1 1>&5
    } | $DIALOG --title $TITLE --progressbox "Logging in to archive.org" 8 78
    # Cleanup and put login result to $res
    exec 5>- ; local res=$(<$tmpf) ; rm $tmpf

    # Check if login succeeded (this is a silly amount of trouble just to get 0/1 exit code.. sigh)
    $JQ -er 'if .status == "ok" then . else null | halt_error(1) end' <<< $res >/dev/null 2>&1
    [[ $? -eq 0 ]] && return

    # It didn't
    $DIALOG --title $TITLE \
        --msgbox "Error logging in to archive.org. Please check IA_USER / IA_PASS variables." 5 78
    cleanup
}

# Download XML files containing all ROM metadata
fetch_metadata () {
    # If any XML files already exist, ask the user if forced re-download is desired.
    #
    # A technically more correct method would be always re-downloading only when remote file
    # has a newer timestamp than the local (which is trivially doable), but this approach is
    # in practice just as slow as unconditionally re-downloading all of the files.
    local -a xmls=($(print *.xml(N)))
    if [[ -n $xmls ]]; then
        $DIALOG --title $TITLE --defaultno \
            --yesno "Do you want to re-download ROM repository metadata?" 5 58
        [[ $? -eq $DIALOG_OK ]] && rm $xmls
    fi

    local -i i
    # Loop through the list of ROM repositories
    (for (( i=1; i<${#SUPPORTED_CORES}; i+=2 )) ; do
        # Print some calming statistics via dialog gauge widget while downloading
        printf "%s\n" "XXX"
        printf "%i\n" $(( 100.0 / ${#SUPPORTED_CORES} * $i ))
        printf "%s\n\n" "Downloading ROM repository metadata XML files"
        printf "%s\n" "Currently downloading $(((${i}+1)/2)) of $((${#SUPPORTED_CORES}/2)):"
        printf "%s\n" "${SUPPORTED_CORES[$(($i+1))]}"
        printf "%s\n" "XXX"
        select_core ${SUPPORTED_CORES[i]}
        [[ -f ${CORE_FILES_XML} ]] || $CURL $CURL_OPTS -skLO ${CORE_URL}/${CORE_FILES_XML}
        [[ -f ${CORE_META_XML} ]] || $CURL $CURL_OPTS -skLO ${CORE_URL}/${CORE_META_XML}
    done) |\
        $DIALOG --title $TITLE --gauge \
            "Downloading ROM repository metadata XML files (total: $((${#SUPPORTED_CORES}/2)))" \
            16 $(($MAXWIDTH / 2)) 0

    [[ $? -ne $DIALOG_OK ]] && cleanup
}

# Display information for selected ROMs
get_rom_info () {
    local -a tags=($*)
    local rominfo="" totalsize=0 romsize file_name tag dest
    for tag in $tags; do
        romsize=$(get_tag_filesize "$tag")
        # MiSTer Zsh is compiled with only 4-byte integers, so shell
        # arithmetic is unfit to keep count of the total size
        totalsize=$(print "$totalsize + $romsize" | ${BC})
        file_name="$(get_tag_filename "$tag")"
        rominfo+="File name: ${file_name##*/}\n"
        rominfo+="File size: $(humanise $romsize)\n"
        dest="$(get_rom_gamedir "$tag")"
        if [[ $? -ne 0 ]]; then
            rominfo+="\\\Zb\\\ZrSave path\\\Zn: \\\Z4${dest}\\\Zn\n\n"
        else rominfo+="Save path: ${dest}\n\n"
        fi

    done
    rominfo+="\nTotal size: $(humanise $totalsize)\n"
    print $rominfo
}

# Get destination directory path for a given tag
get_rom_gamedir () {
    local tag=$*
    local odir="${CORE_GAMEDIR}/"
    local match mbegin mend # Set by backreference glob (#b)

    # For compressed files, it's always just the core main ROM directory
    [[ -z ${tag##*.7z} || $CORE == "AO486" ]] && { print "$odir" ; return }

    # Strip prefix subdir and file extension
    tag=${${(Q)tag%.chd}##*/}

    # MegaCD and Saturn have additional region specific subdirectories
    if [[ $CORE = "MCD" || $CORE = "SS" ]]; then
        : ${tag/(#b)\((Europe|Japan|USA)\)}
        # If we can't deduce region, well just skip it
        [[ -z $match ]] || odir+="${match}/"
    fi

    # If this isn't a multi-CD game, just use the game base name
    local base="${tag% \(Disc [0-9AB]\)*}"
    (( $#base == $#tag )) && { print "${odir}${base}/" ; return }

    # Search XML for games with same base name
    local filter="$base"
    tmpdata=$($XMLLINT $CORE_FILES_XML --xpath "files/file[sha1][contains(translate(\
        @name, \"${(U)filter}\", \"${(L)filter}\"), \"${(L)filter}\")]/@name")

    local -a ntags=(${${${${${${(@f)tmpdata}#*\"}%\"*}##*/}:#^*.chd}//\&amp\;/&})
    unset tmpdata ; local nbase
    nbase=$(find_basename "$tag" $ntags)
    if [[ $? -eq 0 ]] && { print "${odir}${nbase}/" ; return }

    # Failure
    print $odir ; return 1
}

# Download selected ROMs
download_roms () {
    local -a tags=(${*})
    local tag url ofile
    local rominfo="$(get_rom_info $tags)"
    rominfo+="\nDownload selected game(s)?\n"

    $DIALOG --title "Information for selected ROM(s)" --clear --cr-wrap --colors \
        --yesno "$rominfo" $(( $MAXHEIGHT / 2 )) $MAXWIDTH 2>$DIALOG_TEMPFILE
    local retval=$?
    [[ $retval -eq $DIALOG_CANCEL ]] && return
    [[ $retval -ne $DIALOG_OK ]] && cleanup

    # In case the file exists already, cURL will attempt to continue the download
    local cl=(-C - -kL)

    # Make sure target directory exists or if user wants it to be created
    if [[ ! -d $CORE_GAMEDIR ]]; then
        $DIALOG --title "Warning" --clear --cr-wrap --yesno \
            "Directory \"$CORE_GAMEDIR\" doesn't exist.\n\nCreate it?" \
            10 82 2>$DIALOG_TEMPFILE
        retval=$?
        [[ $retval -eq $DIALOG_CANCEL ]] && return
        [[ $retval -ne $DIALOG_OK ]] && cleanup
        mkdir -p $CORE_GAMEDIR
    fi

    for tag in $tags; do
        # Confirm final destination directory
        local dest=$(get_rom_gamedir $tag)
        [[ -n $dest ]] && { [[ -d $dest ]] || mkdir -p "$dest" }

        # Encoded URL to fetch from
        url="${CORE_URL}/$(urlencode "$(get_tag_filename "$tag")")"
        # Destination file with full path
        ofile="${CACHE_DIR}/${tag##*/}"
        # Download the file
        $CURL $CURL_OPTS $cl "$url" -o "$ofile"

        # Verify file checksum
        local filesum="${${(z):-$($SHA1SUM "$ofile")}[1]}"
        local metasum="$(get_tag_sha1sum "$tag")"
        if [[ $filesum = $metasum ]]; then
            print "Downloaded file checksum verified successfully!"
        else
            print "ERROR: Checksum mismatch!"
            print "Downloaded file checksum:  $filesum"
            print "Metadata claimed checksum: $metasum"
            cleanup
        fi

        # If the file is compressed, extract it, otherwise just move to destination
        print "Extracting/moving '$tag' to $dest"
        if [[ -z ${tag##*.7z} ]]; then
            $SZR e "$ofile" -o"$dest" -y
            rm "$ofile"
        elif [[ -z ${tag##*.zip} ]]; then
            $UNZIP -o -qq -d "$dest" "$ofile"
            rm "$ofile"
        else
            mv "$ofile" "$dest"
        fi
    done

    $DIALOG --title $TITLE --cr-wrap --msgbox "Download complete!\n\nPress OK to return." \
        12 32 2>$DIALOG_TEMPFILE
    [[ $? -ne $DIALOG_OK ]] && cleanup
}

# Organise ROM files in directory $* as we would when downloading
organise_chd_dir () {
    local gamedir="${*%/}"
    local tag base nbase
    [[ -d $gamedir ]] || { print "ERROR: $gamedir is not a directory?" ; return 1 }

    local -a tags=(${gamedir}/*.chd)
    for (( i=1; i <= $#tags; i++ )) ; do
        tag="${${(Q)tags[i]%.chd}##*/}"
        base="${tag% \(Disc [0-9AB]\)*}"
        if (( $#base == $#tag )); then # Not multi-CD game
            print "\e[33m${tags[i]##*/}\e[0m -> \e[34m${base}\e[0m/"
            [[ -d "${gamedir}/${base}" ]] || mkdir "${gamedir}/${base}"
            mv "${tags[i]}" "${gamedir}/${base}"
            continue
        fi

        # Find other files with same basename and send off to neural network quantum AI
        local -a ntags=(${(M)${${(@f)tags%.chd}##*/}:#${base}*})
        nbase=$(find_basename "$tag" $ntags)
        if [[ $? -eq 0 ]]; then
            print "\e[33m${${tags[i]}##*/}\e[0m -> \e[36m${nbase}\e[0m/"
            [[ -d "${gamedir}/${nbase}" ]] || mkdir "${gamedir}/${nbase}"
            mv "${tags[i]}" "${gamedir}/${nbase}"
        else
            print "\e[35m${${tags[i]}##*/}\e[0m -> \e[31mFAILED TO COMPUTE SUITABLE NAME\e[0m"
        fi
    done
}

# Find suitable game directory name when multiple base names are identical
find_basename () {
    local tag=${(Q)1##*/}
    local -a ntags=(${(Q)@[2,-1]##*/})
    local s subdir ntag match mbegin mend
    local base=${tag//(#b) \(Disc [0-9AB]\)(*)/}
    local suff="${match}"

    # All CD based system games should have their own subdirectories, for
    # detecting if CD change warrants a core reset (multi-CD games), and a
    # least for PSX core to automatically create a matching save file (mcd)
    #
    # Because file naming in the repositories isn't quite uniform, it's a bit
    # of a pain in the ass. Some multi-CD titles have multiple versions and
    # each disk additionally has a unique name.
    #
    # For deducing correct directory name for multi-CD games, filename is cut
    # into three parts:
    #
    #   `Example Multi-CD Game (Disc 1) (Ugly hack) (Proto)`
    #    +-------------------+ +------+ +-----------------+
    #            base            disc         suffix

    typeset -A discset=() # discset[base]="disc:suffix\x00disc:suffix\x00"
    for ntag in $ntags; do
        local nbase=${ntag//(#b)( \(Disc [0-9AB]\))(*)/}
        [[ ! $nbase = $base ]] && continue # This should never happen
        [[ -z ${match[2]} ]] && match[2]="0xDEADBEEF" # Placeholder for no suffix
        discset[${base}]+=${:-${match[1]}":"${match[2]}$'\x00'}
    done

    # If there's only one file suffix, use it
    local -a nsuff=(${(u)${(0)discset[$base]}##*:})
    (( $#nsuff == 1 )) && { print "${base}${suff}" ; return }

    # If there's multiple suffixes but only one set of discs, just use base name
    local -a discs=(${${(0)discset[$base]}%%:*})
    (( $#discs == ${#${(@u)discs}} )) && { print "${base}" ; return }

    # If the number of disc sets matches the number of different suffixes,
    # *assume* there's a unique suffix per set
    local dsets=$(( ${#discs} / ${#${(@u)discs}} ))
    (( $dsets == $#nsuff )) && { print "${base}${suff}" ; return }

    # This is as far as I'm willing to go with programmatical heuristics
    print ; return 1
}

game_menu () {
    local -a all_tags selected_tags menu_tags menu_items subdirs submenu
    local -i itemwidth retval i
    local filter tmpdata st rominfo sub match mbegin mend n

    # Full list of all games in current core XML
    tmpdata=$($XMLLINT $CORE_FILES_XML --xpath "files/file[sha1]/@name")
    all_tags=(${${${${${(@f)tmpdata}#*\"}%\"*}:#^*.(7z|zip|chd)}//\&amp\;/&})
    unset tmpdata

    # This *tarded sorting method crashes the whole MiSTer with bigger
    # repositories - reserves *far* too much memory, sigh. Looks cool tho.
    #all_tags=(${${(o)all_tags:t}/(#b)(*)/${(M)all_tags:#*${match}}})

    if [[ -n ${(M)all_tags:#*/*} ]]; then
    # Sorting with an associative array instead.. lame lol
    local -A tt
    for n in $all_tags ; tt[${n:t}]=${n:h}
    all_tags=()
    for n in ${(ok)tt} ; all_tags+=(${tt[$n]}/$n)
    unset tt
    fi
    # First check if repository contains subdirectories and if
    # user wants to only look at a specific one or all of them
    subdirs=(${(u)all_tags//(#b)(*\/)*/$match[1]})
    if (( $#subdirs != $#all_tags )) && (( $#subdirs > 1 )); then
        submenu=("ALL" "[[ All of them ]]")
        for sub in $subdirs; submenu+=($sub $sub)
        $DIALOG --clear --title $TITLE --no-tags --menu \
            "This repository contains subdirectories, please select which one to browse." \
            0 0 0 $submenu 2>$DIALOG_TEMPFILE
        (( $? != $DIALOG_OK )) && return
        sub=$(<$DIALOG_TEMPFILE)
        if [[ ! "$sub" = "ALL" ]] ; then
            all_tags=(${(M)all_tags:#${sub}*})
            sub="subdirectory: ${sub%\/}, "
        else unset sub
        fi
    fi

    # Main loop
    while true; do
        if [[ -z $selected_tags ]]; then
            # Optional filter string for narrowing down the game list
            if [[ -n $filter ]]; then
                menu_tags=(${(M)all_tags:#(#i)*${filter}*})
            else
                menu_tags=($all_tags)
            fi
        fi

        # Due to cdialog bug, checklist doesn't wrap correctly.
        # For display, remove any prefix subdirectories and file extension, then trim length if needed.
        # XXX: ${array[(r)${(l.${#${(O@)array//?/X}[1]}..?.)}]} <- only cut prefix if needed?
        itemwidth=$(( $MAXWIDTH - 14 ))
        menu_items=()
        for (( i=1 ; i<=${#menu_tags}; ++i )) ; do
            # Restore selected items, if any
            (( ${selected_tags[(Ie)${menu_tags[$i]}]} )) && st="On" || st="0"
            $JOY_MODE && unset st
            menu_items+=(${menu_tags[$i]} ${${${menu_tags[$i]##*/}%.(7z|zip|chd)}:0:$itemwidth} $st)
        done

        if [[ -z $menu_items ]]; then
            $DIALOG --msgbox "No games found with filter: $filter\n" 5 42
            # If user does not press ok, bail out instead of reloading default set
            [[ $? -ne $DIALOG_OK ]] && break
            unset filter ; continue
        fi

        ###############
        # Main ROM menu
        if $JOY_MODE; then
            $DIALOG --clear --title $TITLE --extra-button --extra-label "ROM info" \
                --no-tags --cancel-label "Back" --ok-label "Download" --default-item "$selected_tags"\
                --menu "Choose game to download (core: ${CORE}, ${sub}games total: ${#menu_tags})" \
                $MAXHEIGHT $MAXWIDTH $#menu_tags $menu_items 2>$DIALOG_TEMPFILE
        else
            $DIALOG --clear --title $TITLE --separate-output --extra-button --extra-label "ROM info" \
                --no-tags --cancel-label "Back" --help-button --help-tags --help-label "Filter..." \
                --ok-label "Download" --default-item "${selected_tags[1]}" \
                --checklist "Choose game(s) to download (core: ${CORE}, ${sub}games total: $#menu_tags)" \
                $MAXHEIGHT $MAXWIDTH $#menu_tags $menu_items 2>$DIALOG_TEMPFILE
        fi
        retval=$?
        # List of user selected tags
        selected_tags=(${${(f)"$(<$DIALOG_TEMPFILE)"}//&amp\;/&})

        case $retval in
            # Download selected games
            $DIALOG_OK)
                if [[ -z $selected_tags ]]; then
                    $DIALOG --title $TITLE --msgbox "No ROMs selected!" 0 0
                    continue
                fi
                download_roms $selected_tags
                # In simple mode, return navigation to last downloaded item
                $JOY_MODE || unset selected_tags filter
                continue ;;

            # Help button is for filtering the ROM list
            $DIALOG_HELP)
                $DIALOG --title "Game list filter" --clear --no-cancel \
                    --inputbox "Type search keyword (case-insensitive) or clear to reset list:" \
                    0 80 $filter 2>$DIALOG_TEMPFILE
                # ESC was pressed, or something else than Ok button
                [[ $? -ne $DIALOG_OK ]] && cleanup
                filter="$(<$DIALOG_TEMPFILE)"
                unset selected_tags
                continue ;;

            # Show some data for selected ROM(s)
            $DIALOG_EXTRA)
                if [[ -z $selected_tags ]]; then
                    $DIALOG --title $TITLE --msgbox "No ROMs selected!" 0 0
                    continue
                fi
                rominfo="$(get_rom_info $selected_tags)"
                $DIALOG --title "Information for selected ROM(s)" --clear --cr-wrap --colors \
                    --msgbox "$rominfo" $(( $MAXHEIGHT / 2 )) $MAXWIDTH 2>$DIALOG_TEMPFILE
                [[ $? -ne $DIALOG_OK ]] && cleanup
                continue ;;

            $DIALOG_CANCEL) break ;;
            *) cleanup ;;
        esac
    done
}

################################################################################################################
#
# MAIN SCREEN TURN ON
#
main () {
    local -i retval
    local jm t d

    init_static_globals

    # Work directory contains:
    # - Downloaded ROM repository XML metadata files, indicated by $DLDONE file
    # - User configurable settings in $SETTINGS_SH
    # - Cache dir for temporarily storing downloaded ROMs
    [[ -d $WRK_DIR ]] || mkdir -p $WRK_DIR
    [[ -d $CACHE_DIR ]] || mkdir $CACHE_DIR
    pushd $WRK_DIR

    # Cleanup in case of unclean exit
    trap 'cleanup' $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM

    # Fetch user-configurable configuration settings from ${SETTINGS_SH} or create it if it
    # doesn't yet exist, then set defaults for all which weren't explicitly set by the user.
    get_config

    # Login to archive.org if IA_USER/IA_PASS are set and use a cookie for remainder of
    # download operations.
    ia_login

    # Download ROM repository metadata XML files, if they haven't already been downloaded.
    fetch_metadata

    # Secret feature, optional cmdline argument is a directory with .CHD files
    # to sort into their own subdirectories.
    [[ -n $* ]] && { organise_chd_dir $* ; return }

    ###########
    # Main loop
    while true; do
        # Restore menu position, if any
        local default_item=${CORE:-0}

        # Set special title for simple mode
        $JOY_MODE && jm=" (Simple Mode)" || unset jm
        typeset -g TITLE="${ROMWEASEL_VERSION}${jm}"

        # Show main ROM repository menu
        $JOY_MODE && jm="Normal Mode" || jm="Simple Mode"
        $DIALOG --title $TITLE --cancel-label "Quit" --help-button --help-tags --help-status \
            --default-item "$default_item" --extra-button --extra-label "Info" --help-label $jm \
            --menu "Choose target system/repository:" 0 80 0 $SUPPORTED_CORES 2>$DIALOG_TEMPFILE
        retval=$?

        case $retval in
            # Open game list for selected ROM repository
            $DIALOG_OK)
                select_core $(<$DIALOG_TEMPFILE)
                game_menu ;;

            # Repurposed for toggling simplified joystick mode on and off
            $DIALOG_HELP)
                select_core ${(@f)$(<$DIALOG_TEMPFILE)[2]}
                $JOY_MODE && { JOY_MODE=false ; jm='\Z6Disabled!\Zn' } || { JOY_MODE=true ; jm='\Z5Enabled!\Zn' }
                $DIALOG --title $TITLE --cr-wrap --colors --msgbox "Simplified joystick mode:\n\n$jm" \
                    8 0 2>$DIALOG_TEMPFILE
                [[ $? -ne $DIALOG_OK ]] && cleanup
                ;;

            # Show information for currently selected ROM repository
            $DIALOG_EXTRA)
                select_core $(<$DIALOG_TEMPFILE)
                t=$($XMLLINT $CORE_META_XML --xpath "string(metadata/title)")
                d=$($XMLLINT $CORE_META_XML --xpath "string(metadata/addeddate)")
                $DIALOG --title "ROM repository info" --msgbox "\
Core:  $CORE \n\
URL:   $CORE_URL \n\
Title: $t \n\
Added: $d" 10 $MAXWIDTH
                unset t d
                ;;

            *)
                break ;;
            esac
    done

    # Clean up temporary files
    cleanup
}

## For easy debug/test entry point
main $*
