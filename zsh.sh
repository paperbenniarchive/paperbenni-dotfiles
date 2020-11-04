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

autoeditvid() {
    ffmpeg -i "$1" -filter_complex \
 "highpass=f=200[frank]; [frank]lowpass=f=4000[gunter]; [gunter]compand=attacks=0:points=-80/-900|-45/-15|-27/-9|-5/-5|20/20:gain=3" "${2}tmp.mp4"
    auto-editor "${2}tmp.mp4" --frame_margin 3 --video_speed 1.2 --output_file "$2.mp4"
    rm "$1"
}

