#!/usr/bin/zsh

# use development version of instantSHELL
source ~/workspace/instantSHELL/zshrc

pullmusic() {
    mkdir ~/Music
    rclone sync -P music:Music/ ~/Music
}

musicback() {
    rclone sync -P ~/Music/ music:Music/
}

musiccode() {
    cd ~/Music
    if ! [ -e ~/musiccode/ ]; then
        echo "creating musiccode"
        mkdir ~/musiccode
    fi

    for i in ./*; do
        if ! ffprobe "$i"; then
            continue
        fi
        echo "processing $i"

        NAME="${i%.*}"
        if ! [ -e ~/musiccode/"$NAME".mp3 ]; then
            ffmpeg -i "$i" ~/musiccode/"$NAME".mp3
        fi
    done

}

preprocessvideo() {
    [ -n "$1" ] || return 1
    if [ -n "$2" ]; then
        OUTFILE="$2"
    else
        OUTFILE="${1}tmp.mp4"
    fi
    ffmpeg -i "$1" -vcodec libx264 -movflags +faststart -analyzeduration 2147483647 -probesize 2147483647 -max_muxing_queue_size 9999 "$OUTFILE" || return 1
}

mergeall() {
    MKVCOMMAND="mkvmerge -o \"$1\""
    for i in ./*; do
        if ! ffprobe "$i" &>/dev/null; then
            echo "$i is not a video"
            continue
        fi
        4
        MKVCOMMAND="$MKVCOMMAND \"$i\" \+"
    done
    MKVCOMMAND="$(sed 's/..$//g' <<<"$MKVCOMMAND")"
    echo "running $MKVCOMMAND"
    eval "$MKVCOMMAND"
}

autoeditvid() {

    if command -v pacman &>/dev/null; then
        instantinstall mkvtoolnix-cli || exit 1
        instantinstall ffmpeg || exit 1
    fi

    if ! command -v auto-editor &>/dev/null; then
        echo "installing auto-editor"
        command -v pip || exit 1
        sudo pip3 install auto-editor
    fi

    [ -z "$2" ] && return 1

    if [ "$1" = youtube ]; then
        if ! [ -e "$2" ]; then
            echo 'dafuq, that doesnt exist'
            return 1
        fi
        counter=1
        while read video; do
            echo "downloading video $counter"
            youtube-dl --output "${counter}video" "$video"
            counter="$((counter + 1))"
        done <"$2"
        autoeditvid "mp4" "${3:-youtube}"
        return
    fi

    if [ "$1" = "copysound" ]; then
        echo "not editing sound"
        export COPYSOUND="true"
        shift 1
    fi

    if [ "$1" = "mp4" ]; then

        # check if videos are all same resolution, if not mkvmerge cannot be used
        for i in ./*; do
            if ! ffprobe "$i" &>/dev/null; then
                echo "$i is not a video"
                continue
            fi
            CURRES="$(ffprobe "$i" 2>&1 | grep -i video | grep -o ',.*' | grep -o '[0-9][0-9]*x[0-9]*[0-9]')"
            if [ -z "$CURRES" ]; then
                echo "$i is corrupted"
                return 1
            fi
            if [ -n "$LASTRES" ]; then
                if ! [ "$CURRES" = "$LASTRES" ]; then
                    export USEMELT=true
                    echo "using melt"
                    sleep 5
                    break
                fi
            fi
            LASTRES="$CURRES"
            echo "LASTRES $LASTRES"
        done

        mkdir tmprenders
        echo "converting videos to correct codec"
        for i in ./*; do
            if ! ffprobe "$i" &>/dev/null; then
                echo "$i is not a video"
                continue
            fi
            preprocessvideo "$i" "tmprender.mp4" || return 1
            mv tmprender.mp4 tmprenders/"$i"tmp.mp4
        done
        echo 'concatenating videos'
        cd tmprenders

        if [ -z "$USEMELT" ]; then
            mergeall "${2}.mp4"
        else
            echo "using melt"
            melt *.mp4 -consumer avformat:"${2}tmp2.mp4" acodec=libmp3lame vcodec=libx264 vb=8000k
        fi

        mv "${2}tmp2.mp4" ../ || exit 1
        cd ../ || exit 1
        echo "applying audio compression"
    else
        preprocessvideo "$1" "${2}tmp2.mp4"
    fi

    if [ -n "$COPYSOUND" ]; then
        mv "${2}tmp2.mp4" "${2}tmp.mp4"
    else
        ffmpeg -i "${2}tmp2.mp4" -filter_complex "highpass=f=200[frank]; [frank]lowpass=f=4000[gunter]; [gunter]compand=attacks=0:points=-80/-900|-45/-15|-27/-9|-5/-5|20/20:gain=3" "${2}tmp.mp4"
    fi

    # split if file is large
    FILEDURATION="$(
        ffprobe -i "${2}tmp.mp4" -show_entries format=duration -v quiet -of csv="p=0" | grep -o '^[^.]*'
    )"

    if ! [ "$FILEDURATION" -eq "$FILEDURATION" ]; then
        echo 'tmpfile is corrupt'
        exit 1
    fi

    if [ "$FILEDURATION" -gt 3600 ]; then
        echo 'file is longer than an hour, splitting'
        mkdir splittmp
        mv "${2}large.mp4" splittmp/
        cd splittmp || exit 1
        mkvmerge --split duration:00:30:00.000 -o tmpsplit "${2}large.mp4"
        mv "${2}large.mp4" ../"${2}large_old.mp4" 

        for i in ./*; do
            echo 'renaming files'
            mv "$i" "$i.mp4"
            auto-editor "${i}.mp4" --frame_margin 3 --output_file "${i}edited.mp4" || exit 1
            rm "$i"
        done

        mergeall "${2}large.mp4"
        mv "${2}large.mp4" ../
        cd ../ || exit 1

    else
        auto-editor "${2}tmp.mp4" --frame_margin 3 --output_file "${2}large.mp4" || exit 1
    fi

    ffmpeg -i "${2}large.mp4" -filter_complex "[0:v]setpts=1/1.3*PTS[v];[0:a]atempo=1.3[a]" -map "[v]" -map "[a]" "$2.mp4" &&
        rm "$VINPUT" &&
        rm "${2}large.mp4"
}

alias t=task
alias tw=timew
alias tc="task status:comlpeted"
alias ta="task add"
alias a=yatext

inkexport() {
    [ -e ./final ] || mkdir final
    inkscape --without-gui --file="$1" --export-text-to-path --export-plain-svg="final/$1"
}

compdef _task yatext
