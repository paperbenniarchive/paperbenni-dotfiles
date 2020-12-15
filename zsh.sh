#!/usr/bin/zsh

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
    ffmpeg -i "$1" -filter_complex \
        "highpass=f=200[frank]; [frank]lowpass=f=4000[gunter]; [gunter]compand=attacks=0:points=-80/-900|-45/-15|-27/-9|-5/-5|20/20:gain=3" "$OUTFILE"
}

autoeditvid() {

    [ -z "$2" ] && return 1

    if [ "$1" = "mp4" ]
    then
        mkdir tmprenders
        for i in ./*.mp4
        do
            preprocessvideo "$i" "tmprender.mp4"
            mv tmprender.mp4 tmprenders/"$i"tmp.mp4
        done
        melt *.mp4 -consumer avformat:"${2}tmp.mp4" acodec=libmp3lame vcodec=libx264 vb=8000k
    else
        preprocessvideo "$1" "${2}tmp.mp4"
    fi

    auto-editor "${2}tmp.mp4" --frame_margin 3 --output_file "${2}large.mp4" && \
        ffmpeg -i "${2}large.mp4" -filter_complex "[0:v]setpts=1/1.3*PTS[v];[0:a]atempo=1.3[a]" -map "[v]" -map "[a]" "$2.mp4" && \
        rm "$VINPUT" && \
        rm "${2}large.mp4"
}


