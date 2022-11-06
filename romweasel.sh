#!/bin/zsh

setopt localoptions extendedglob

WEASEL_VERSION="MiSTer ROMweasel v0.9.2"

# Required software to run
XMLLINT=$(which xmllint) || { print "ERROR: 'xmllint' not found" ; return 1 }
CURL=$(which curl) || { print "ERROR: 'curl' not found" ; return 1 }
DIALOG=$(which dialog) || { print "ERROR: 'dialog' not found" ; return 1 }
SHA1SUM=$(which sha1sum) || { print "ERROR: 'sha1sum' not found" ; return 1 }
SZR=$(which 7zr) || { print "ERROR: '7zr' not found" ; return 1 }

# Stash all metadata here
WRK_DIR="/media/fat/Scripts/.config/romweasel"
# User configurable settings
SETTINGS_SH="${WRK_DIR}/settings.sh"
# Temporary location for compressed ROMs
CACHE_DIR="${WRK_DIR}/cache"
# If this file exists, skip downloading XML metadata files
DLDONE="${WRK_DIR}/.dl_done"

# Dialog box maximum size, leave a small border in case of overscan
MAXHEIGHT=$(( $LINES - 4 ))
MAXWIDTH=$(( $COLUMNS - 4 ))

# Supported ROM repositories
SUPPORTED_CORES=( \
    "NES"       "Nintendo Entertainment System" \
    "SNES"      "Super Nintendo" \
    "GB"        "Nintendo GameBoy" \
    "GBC"       "Nintendo GameBoy Color" \
    "GBA"       "GameBoy Advance" \
    "TG16"      "NEC TurboGrafx16 / PC-Engine" \
    "TG16CD"    "NEC TurboGrafx16-CD / PC-Engine CD" \
    "SMS"       "SEGA Master System" \
    "GG"        "SEGA Game Gear" \
    "MD"        "SEGA Mega Drive" \
    "MCD"       "SEGA MegaCD / SegaCD" \
    "PSXUS"     "Sony PlayStation USA" \
    "PSXEU"     "Sony PlayStation Europe" \
    "PSXJP"     "Sony PlayStation Japan" \
    "PSXJP2"    "Sony PlayStation Japan #2" \
    "PSXMISC"   "Sony PlayStation Miscellaneous" \
)

# The prefix "NAME_" must match the core name in above list
NES_URL="https://archive.org/download/nointro.nes"
NES_FILES_XML="nointro.nes_files.xml"
NES_META_XML="nointro.nes_meta.xml"
SNES_URL="https://archive.org/download/nointro.snes"
SNES_FILES_XML="nointro.snes_files.xml"
SNES_META_XML="nointro.snes_meta.xml"
GB_URL="https://archive.org/download/nointro.gb"
GB_FILES_XML="nointro.gb_files.xml"
GB_META_XML="nointro.gb_meta.xml"
GBC_URL="https://archive.org/download/nointro.gbc"
GBC_FILES_XML="nointro.gbc_files.xml"
GBC_META_XML="nointro.gbc_meta.xml"
GBA_URL="https://archive.org/download/nointro.gba"
GBA_FILES_XML="nointro.gba_files.xml"
GBA_META_XML="nointro.gba_meta.xml"
TG16_URL="https://archive.org/download/nointro.tg-16"
TG16_FILES_XML="nointro.tg-16_files.xml"
TG16_META_XML="nointro.tg-16_meta.xml"
TG16CD_URL="https://archive.org/download/chd_pcecd"
TG16CD_FILES_XML="chd_pcecd_files.xml"
TG16CD_META_XML="chd_pcecd_meta.xml"
SMS_URL="https://archive.org/download/nointro.ms-mkiii"
SMS_FILES_XML="nointro.ms-mkiii_files.xml"
SMS_META_XML="nointro.ms-mkiii_meta.xml"
GG_URL="https://archive.org/download/nointro.gg"
GG_FILES_XML="nointro.gg_files.xml"
GG_META_XML="nointro.gg_meta.xml"
MD_URL="https://archive.org/download/nointro.md"
MD_FILES_XML="nointro.md_files.xml"
MD_META_XML="nointro.md_meta.xml"
MCD_URL="https://archive.org/download/chd_segacd"
MCD_FILES_XML="chd_segacd_files.xml"
MCD_META_XML="chd_segacd_meta.xml"
PSXUS_URL="https://archive.org/download/chd_psx"
PSXUS_FILES_XML="chd_psx_files.xml"
PSXUS_META_XML="chd_psx_meta.xml"
PSXEU_URL="https://archive.org/download/chd_psx_eur"
PSXEU_FILES_XML="chd_psx_eur_files.xml"
PSXEU_META_XML="chd_psx_eur_meta.xml"
PSXJP_URL="https://archive.org/download/chd_psx_jap"
PSXJP_FILES_XML="chd_psx_jap_files.xml"
PSXJP_META_XML="chd_psx_jap_meta.xml"
PSXJP2_URL="https://archive.org/download/chd_psx_jap_p2"
PSXJP2_FILES_XML="chd_psx_jap_p2_files.xml"
PSXJP2_META_XML="chd_psx_jap_p2_meta.xml"
PSXMISC_URL="https://archive.org/download/chd_psx_misc"
PSXMISC_FILES_XML="chd_psx_misc_files.xml"
PSXMISC_META_XML="chd_psx_misc_meta.xml"

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_HELP=2
DIALOG_EXTRA=3
DIALOG_ITEM_HELP=4
DIALOG_ESC=255

SIG_NONE=0
SIG_HUP=1
SIG_INT=2
SIG_QUIT=3
SIG_KILL=9
SIG_TERM=15

# Fixes ncurses output with many terminals (eg. PuTTY)
export NCURSES_NO_UTF8_ACS=1

# dialog(1) writes results to a tempfile via stderr
DIALOG_TEMPFILE=$(mktemp 2>/dev/null) || DIALOG_TEMPFILE=/tmp/test$$

# Helper functions, fetch metadata from XML based on tag name (always same as full path filename)
get_tag_filename () {
    tag="${1}"
    # This should always just return same as input was
    print $(${XMLLINT} ${FILES_XML} --xpath "string(files/file[@name=\""$tag"\"]/@name)")
}
get_tag_filesize () {
    tag="${1}"
    human_readable=${2:-false}
    res=$(${XMLLINT} ${FILES_XML} --xpath "string(files/file[@name=\""$tag"\"]/size)")
    $human_readable && print $(humanise $res) || print $res
}
get_tag_sha1sum () {
    tag="${1}"
    print $(${XMLLINT} ${FILES_XML} --xpath "string(files/file[@name=\""$tag"\"]/sha1)")
}

# Convert input bytes into more human-readable form
humanise () { print $(numfmt --to=iec-i --suffix=B --format="%9.2f" ${1}) }

# URL encode a string, including parenthesis although it's not strictly required
urlencode () {
        setopt localoptions extendedglob
        input=(${(s::)1})
        print ${(j::)input/(#b)([^A-Za-z0-9_.!~*\-\/])/%${(l:2::0:)$(([##16]#match))}}
}

cleanup () {
    [[ -f $DIALOG_TEMPFILE ]] && rm $DIALOG_TEMPFILE
    [[ $(ls -A ${CACHE_DIR}) ]] && print "Warning: cache dir $CACHE_DIR not empty"
    exit 0
}

get_config () {
    # Default settings
    : ${NES_GAMEDIR=/media/fat/games/NES}
    : ${SNES_GAMEDIR=/media/fat/games/SNES}
    : ${GB_GAMEDIR=/media/fat/games/GAMEBOY}
    : ${GBC_GAMEDIR=/media/fat/games/GAMEBOY}
    : ${GBA_GAMEDIR=/media/fat/games/GBA}
    : ${TG16_GAMEDIR=/media/fat/games/TGFX16}
    : ${TG16CD_GAMEDIR=/media/fat/games/TGFX16-CD}
    : ${SMS_GAMEDIR=/media/fat/games/SMS}
    : ${GG_GAMEDIR=/media/fat/games/SMS}
    : ${MD_GAMEDIR=/media/fat/games/Genesis}
    : ${MCD_GAMEDIR=/media/fat/games/MegaCD}
    : ${PSXUS_GAMEDIR=/media/fat/games/PSX}
    : ${PSXEU_GAMEDIR=/media/fat/games/PSX}
    : ${PSXJP_GAMEDIR=/media/fat/games/PSX}
    : ${PSXJP2_GAMEDIR=/media/fat/games/PSX}
    : ${PSXMISC_GAMEDIR=/media/fat/games/PSX}

    # Simplified mode for use without a keyboard
    : ${JOY_MODE=true}

    if [[ -f ${SETTINGS_SH} ]]; then
        # Load user configuration file
        . ${SETTINGS_SH}
    else
        # If configuration file doesn't exist, create one from scratch
        tmpl=("# Automatically generated romweasel configuration template\n")
        tmpl+="# Root directories per core / ROM repository"
        for (( i=1; i<${#SUPPORTED_CORES}; i+=2 )) ; do
            tmpl+="#${SUPPORTED_CORES[i]}_GAMEDIR=\"${(P)${:-${SUPPORTED_CORES[i]}_GAMEDIR}}\""
        done
        tmpl+="\n# Simplified mode for use without a keyboard (true/false)"
        tmpl+="#JOY_MODE=${JOY_MODE}"
        print -l $tmpl > ${SETTINGS_SH}
    fi
}

# Download XML files containing all ROM metadata
fetch_metadata () {
    # Once the files are downloaded, they are never automatically updated. This would be trivial to achieve
    # using curl -z <file> option, but going through them all is quite slow and very rarely required.
    # Instead, user needs to manually remove the $DLDONE file.
    [[ -f $DLDONE ]] && return 0

    rm ${WRK_DIR}/*.xml
    curl_opts=(--connect-timeout 5 --retry 3 --retry-delay 5 -skLO)

    # Loop through the list of ROM repositories
    (for (( i=1; i<${#SUPPORTED_CORES}; i+=2 )) ; do
        # Print some calming statistics via dialog gauge widget while downloading
        printf "%s\n" "XXX"
        printf "%i\n" $(( 100.0 / ${#SUPPORTED_CORES} * $i ))
        printf "%s\n\n" "Downloading ROM repository metadata XML files (this is only done once)"
        printf "%s\n" "Currently downloading $(((${i}+1)/2)) of $((${#SUPPORTED_CORES}/2)):"
        printf "%s\n" "${SUPPORTED_CORES[$(($i+1))]}"
        printf "%s\n" "XXX"
        CORE_URL=${(P)${:-${SUPPORTED_CORES[i]}_URL}}
        CORE_FILES_XML=${(P)${:-${SUPPORTED_CORES[i]}_FILES_XML}}
        CORE_META_XML=${(P)${:-${SUPPORTED_CORES[i]}_META_XML}}

        # Download via curl
        ${CURL} ${curl_opts} ${CORE_URL}/${CORE_FILES_XML}
        ${CURL} ${curl_opts} ${CORE_URL}/${CORE_META_XML}
    done) |\
        ${DIALOG} --title ${TITLE} \
            --gauge "Downloading ROM repository metadata XML files (total: $((${#SUPPORTED_CORES}/2)))" \
            16 $(($MAXWIDTH / 2)) 0

    [[ $? -ne $DIALOG_OK ]] && cleanup
    touch $DLDONE
}

# Dynamically set environment variables to point to currently selected repository
select_core () {
    CORE=${1}
    CORE_URL=${(P)${:-${CORE}_URL}}
    CORE_GAMEDIR=${(P)${:-${CORE}_GAMEDIR}}
    FILES_XML=${(P)${:-${CORE}_FILES_XML}}
    META_XML=${(P)${:-${CORE}_META_XML}}
}

# Display information for selected ROMs
get_rom_info () {
    tags=(${*})
    rominfo="" ; totalsize=0
    for tag in $tags; do
        romsize=$(get_tag_filesize "$tag")
        # MiSTer Zsh is compiled with only 4-byte integers, so shell
        # arithmetic is unfit to keep count of total size
        totalsize=$(print "$totalsize + $romsize" | bc)
        file_name="$(get_tag_filename "$tag")"
        rominfo+="File name: ${file_name##*/}\n"
        rominfo+="File URL:  ${CORE_URL}/$(urlencode ${file_name})\n"
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
    tag=$*
    # For compressed files, it's always just the core main ROM directory
    [[ -z ${tag##*.7z} ]] && { print "${CORE_GAMEDIR}/" ; return }

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

    # Strip prefix subdir and file extension
    tag=${${(Q)tag%.chd}##*/}
    # MegaCD has additional region specific subdirectories
    if [[ $CORE = "MCD" ]]; then
        : ${tag/(#b)\((Europe|Japan|USA)\)}
        print -n "${CORE_GAMEDIR}/${match}/"
    else print -n "${CORE_GAMEDIR}/"
    fi
    # If this isn't a multi-CD game, just use the game base name
    base=${tag//(#b)( \(Disc [0-9AB]\))(*)/}
    (( $#match < 2 )) && { print "${base}/" ; return }

    # Search XML again for rest of the discs matching same game basename
    suff="${match[2]}"
    typeset -A discset=() # discset[base]="disc:suffix\x00disc:suffix\x00"
    filter="$base"
    tmpdata=$(${XMLLINT} ${FILES_XML} --xpath "files/file[sha1][contains(translate(\
        @name, \"${(U)filter}\", \"${(L)filter}\"), \"${(L)filter}\")]/@name")

    tags=(${${${${${(@f)tmpdata}#*\"}%\"*}:#^*.chd}/\&amp\;/&})
    for tag in $tags; do
        tag=${${(Q)tag%.chd}##*/}
        nbase=${tag//(#b)( \(Disc [0-9AB]\))(*)/}
        (( $#match < 2 )) || [[ ! $nbase = $base ]] && continue
        discset[${base}]+=${:-${match[1]}":"${match[2]}$'\x00'}
    done

    # If there's only one file suffix, use it
    nsuff=(${(u)${(0)discset[$base]}##*:})
    (( ${#nsuff} == 1 )) && { print "${base}${nsuff}/" ; return }

    # If there's multiple suffixes but only one set of discs, just use base name
    discs=(${${(0)discset[$base]}%%:*})
    (( ${#discs} == ${#${(@u)discs}} )) && { print "${base}/" ; return }

    # If the number of disc sets matches the number of different suffixes,
    # *assume* there's a unique suffix per set
    dsets=$(( ${#discs} / ${#${(@u)discs}} ))
    (( $dsets == ${#nsuff} )) && { print "${base}${suff}/" ; return }

    # This is as far as I'm willing to go with programmatical heuristics
    print ; return 1
}

# Download selected ROMs
download_roms () {
    tags=(${*})
    rominfo="$(get_rom_info $tags)"
    rominfo+="\nDownload selected game(s)?\n"

    ${DIALOG} --title "Information for selected ROM(s)" --clear --cr-wrap --colors \
        --yesno "$rominfo" $(( $MAXHEIGHT / 2 )) $MAXWIDTH 2>${DIALOG_TEMPFILE}
    retval=$?
    [[ $retval -eq $DIALOG_CANCEL ]] && return
    [[ $retval -ne $DIALOG_OK ]] && cleanup

    # In case the file exists already, cURL will attempt to continue the download
    curl_opts=(--connect-timeout 5 --retry 3 --retry-delay 5 -C - -kL)

    # Make sure target directory exists or if user wants it to be created
    if [[ ! -d $CORE_GAMEDIR ]]; then
        ${DIALOG} --title "Warning" --clear --cr-wrap --yesno \
            "Directory \"${CORE_GAMEDIR}\" doesn't exist.\n\nCreate it?" \
            10 82 2>${DIALOG_TEMPFILE}
        retval=$?
        [[ $retval -eq $DIALOG_CANCEL ]] && return
        [[ $retval -ne $DIALOG_OK ]] && cleanup
        mkdir -p $CORE_GAMEDIR
    fi

    for tag in $tags; do
        # Confirm final destination directory
        dest=$(get_rom_gamedir $tag)
        [[ -n $dest ]] && { [[ -d $dest ]] || mkdir -p "$dest" }

        # Encoded URL to fetch from
        url="${CORE_URL}/$(urlencode "$(get_tag_filename "$tag")")"
        # Destination file with full path
        ofile="${CACHE_DIR}/${tag##*/}"
        # Download the file
        ${CURL} ${curl_opts} "$url" -o "$ofile"

        # Verify file checksum
        filesum="${${(z):-$(${SHA1SUM} "${ofile}")}[1]}"
        metasum="$(get_tag_sha1sum "$tag")"
        if [[ $filesum = $metasum ]]; then
            print "Downloaded file checksum verified successfully!"
        else
            print "ERROR: Checksum mismatch!"
            print "Downloaded file checksum:  $filesum"
            print "Metadata claimed checksum: $metasum"
            cleanup
        fi

        # If the file is compressed, extract it, otherwise just move to destination
        if [[ -z ${tag##*.7z} ]]; then
            $JOY_MODE && clobber="-y" || unset clobber
            ${SZR} e "$ofile" -o"$dest" $clobber
            rm "$ofile"
        else
            mv "$ofile" "$dest"
        fi
    done

    ${DIALOG} --title ${WEASEL_VERSION} --cr-wrap --msgbox "Download complete!\n\nPress OK to return." \
        12 32 2>${DIALOG_TEMPFILE}
    [[ $? -ne $DIALOG_OK ]] && cleanup
}

game_menu () {
    : ${selected_tags=0} ; unset filter
    while true; do
        # Optional filter string for narrowing down the game list
        if [[ -n $filter ]]; then
            # xmllint (via libxml2) only supports XPath 1.0, which has no regexp matching
            # or case-insensitive search, so translate() is used instead to temporarily
            # change both searched string and data to all lowercase.  This may or may not
            # survive outside ASCII.
            tmpdata=$(${XMLLINT} ${FILES_XML} --xpath "files/file[sha1][contains(translate(\
                @name, \"${(U)filter}\", \"${(L)filter}\"), \"${(L)filter}\")]/@name")
        else
            tmpdata=$(${XMLLINT} ${FILES_XML} --xpath "files/file[sha1]/@name")
        fi

        # Construct list of games to display.
        #
        # Input data is a string, with values separated
        # by newlines and each line is in form:
        #  name="Remote Filename.ext"
        # - All files not ending in .7z or .chd are stripped
        # - Restore &amp; encoded ampersand to '&'
        menu_tags=(${${${${${(@f)tmpdata}#*\"}%\"*}:#^*.(7z|chd)}/\&amp\;/&})
        menu_items=()

        # Due to cdialog bug, checklist doesn't wrap correctly.
        # For display, remove any prefix subdirectories and file extension, then trim length if needed.
        itemwidth=$(( $MAXWIDTH - 14 ))
        for (( i=1 ; i<=${#menu_tags}; ++i )) ; do
            # Restore selected items, if any
            (( ${selected_tags[(Ie)${menu_tags[$i]}]} )) && st="On" || st="0"
            $JOY_MODE && unset st
            menu_items+=(${menu_tags[$i]} ${${${menu_tags[$i]##*/}%.(7z|chd)}:0:$itemwidth} $st)
        done

        if [[ -z ${menu_items} ]]; then
            ${DIALOG} --msgbox "No games found with filter: $filter\n" 5 42
            # If user does not press ok, bail out instead of reloading default set
            [[ $? -ne $DIALOG_OK ]] && break
            unset filter ; continue
        fi

        ###############
        # Main ROM menu
        if $JOY_MODE; then
            ${DIALOG} --clear --title ${TITLE} --extra-button --extra-label "ROM info" \
                --no-tags --cancel-label "Back" --ok-label "Download" --default-item "${selected_tags}"\
                --menu "Choose game to download (core: ${CORE}, games total: ${#menu_tags})" \
                $MAXHEIGHT $MAXWIDTH ${#menu_tags} ${menu_items} 2>${DIALOG_TEMPFILE}
        else
            ${DIALOG} --clear --title ${TITLE} --separate-output --extra-button --extra-label "ROM info" \
                --no-tags --cancel-label "Back" --help-button --help-tags --help-label "Filter..." \
                --ok-label "Download" --default-item "${selected_tags[1]}" \
                --checklist "Choose game(s) to download (core: ${CORE}, games total: ${#menu_tags})" \
                $MAXHEIGHT $MAXWIDTH ${#menu_tags} ${menu_items} 2>${DIALOG_TEMPFILE}
        fi
        retval=$?
        # List of user selected tags
        selected_tags=(${${(f)"$(<${DIALOG_TEMPFILE})"}/&amp\;/&})

        case $retval in
            # Download selected games
            $DIALOG_OK)
                download_roms ${selected_tags}
                $JOY_MODE || unset selected_tags filter
                continue ;;

            # Help button is for filtering the ROM list
            $DIALOG_HELP)
                ${DIALOG} --title "Game list filter" --clear --no-cancel \
                    --inputbox "Type search keyword (case-insensitive) or clear to reset list:" \
                    0 80 $filter 2>${DIALOG_TEMPFILE}
                # ESC was pressed, or something else than Ok button
                [[ $? -ne $DIALOG_OK ]] && cleanup
                filter="$(<${DIALOG_TEMPFILE})"
                unset selected_tags
                continue ;;

            # Show some data for selected ROM(s)
            $DIALOG_EXTRA)
                rominfo="$(get_rom_info $selected_tags)"
                ${DIALOG} --title "Information for selected ROM(s)" --clear --cr-wrap --colors \
                    --msgbox "$rominfo" $(( $MAXHEIGHT / 2 )) $MAXWIDTH 2>${DIALOG_TEMPFILE}
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

# Work directory contains:
# - Downloaded ROM repository XML metadata files, indicated by $DLDONE file
# - User configurable settings in $SETTINGS_SH
# - Cache dir for temporarily storing downloaded ROMs
[[ -d ${WRK_DIR} ]] || mkdir -p ${WRK_DIR}
[[ -d ${CACHE_DIR} ]] || mkdir ${CACHE_DIR}
pushd ${WRK_DIR}

# Cleanup in case of unclean exit
trap 'cleanup' $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM

# Fetch user-configurable configuration settings from ${SETTINGS_SH} or create it if it doesn't yet exist,
# then set defaults for all which weren't explicitly set by the user.
get_config

# Download ROM repository metadata XML files, if they haven't already been downloaded.
fetch_metadata

###########
# Main loop
while true; do
    # Restore menu position, if any
    default_item=${CORE:-0}

    # Set special title for simple mode
    $JOY_MODE && jm=" (Simple Mode)" || unset jm
    TITLE="${WEASEL_VERSION}${jm}"

    # Show main ROM repository menu
    $JOY_MODE && jm="Normal Mode" || jm="Simple Mode"
    ${DIALOG} --title ${TITLE} --cancel-label "Quit" --help-button --help-tags --help-status \
        --default-item "$default_item" --extra-button --extra-label "Info" --help-label $jm \
        --menu "Choose target system/repository:" 0 80 0 ${SUPPORTED_CORES} 2>${DIALOG_TEMPFILE}
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
            ${DIALOG} --title ${TITLE} --cr-wrap --colors --msgbox "Simplified joystick mode:\n\n$jm" \
                8 0 2>${DIALOG_TEMPFILE}
            [[ $? -ne $DIALOG_OK ]] && cleanup
            ;;

        # Show information for currently selected ROM repository
        $DIALOG_EXTRA)
            select_core $(<${DIALOG_TEMPFILE})
            t=$(${XMLLINT} ${META_XML} --xpath "string(metadata/title)")
            d=$(${XMLLINT} ${META_XML} --xpath "string(metadata/addeddate)")
            ${DIALOG} --title "ROM repository info" --msgbox "\
Core:  ${CORE} \n\
URL:   ${CORE_URL}} \n\
Title: ${t} \n\
Added: ${d}" 10 $MAXWIDTH
            ;;

        *)
            break ;;
    esac
done

# Clean up temporary files
cleanup
