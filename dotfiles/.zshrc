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
    if ! [ -e ~/musiccode/ ]
    then
        echo "creating musiccode"
        mkdir ~/musiccode
    fi

    for i in ./*
    do
        if ! ffprobe "$i"
        then
            continue
        fi
        echo "processing $i"

        NAME="${i%.*}"
        if ! [ -e ~/musiccode/"$NAME".mp3 ]
        then
            ffmpeg -i "$i" ~/musiccode/"$NAME".mp3
        fi
    done

}

preprocessvideo() {
    [ -n "$1" ] || return 1
    if [ -n "$2" ]
    then
        OUTFILE="$2"
    else
        OUTFILE="${1}tmp.mp4"
    fi
    ffmpeg -i "$1" -vcodec libx264 -movflags +faststart -analyzeduration 2147483647 -probesize 2147483647 -max_muxing_queue_size 9999 "$OUTFILE" || return 1
}

autoeditvid() {

    if command -v pacman &> /dev/null
    then
        instantinstall mkvtoolnix-cli || exit 1
        instantinstall ffmpeg || exit 1
    fi

    if ! command -v auto-editor &> /dev/null
    then
        echo "installing auto-editor"
        command -v pip || exit 1
        sudo pip3 install auto-editor
    fi

    [ -z "$2" ] && return 1

    if [ "$1" = "mp4" ]
    then
        mkdir tmprenders
        echo "converting video to correct codec"
        for i in ./*.mp4
        do
            preprocessvideo "$i" "tmprender.mp4" || return 1
            mv tmprender.mp4 tmprenders/"$i"tmp.mp4
        done
        echo 'concatenating videos'

        MKVCOMMAND="mkvmerge -o \"${2}tmp2.mp4\""
        for i in ./*.mp4
        do
            MKVCOMMAND="$MKVCOMMAND \"$i\" \+"
        done
        MKVCOMMAND="$(sed 's/..$//g' <<< "$MKVCOMMAND")"
        echo "running $MKVCOMMAND"
        eval "$MKVCOMMAND"

        echo "applying audio compression"
    else
        preprocessvideo "$1" "${2}tmp2.mp4"
    fi
    ffmpeg -i "${2}tmp2.mp4" -filter_complex "highpass=f=200[frank]; [frank]lowpass=f=4000[gunter]; [gunter]compand=attacks=0:points=-80/-900|-45/-15|-27/-9|-5/-5|20/20:gain=3" "${2}tmp.mp4"

    auto-editor "${2}tmp.mp4" --frame_margin 3 --output_file "${2}large.mp4" && \
        ffmpeg -i "${2}large.mp4" -filter_complex "[0:v]setpts=1/1.3*PTS[v];[0:a]atempo=1.3[a]" -map "[v]" -map "[a]" "$2.mp4" && \
        rm "$VINPUT" && \
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
