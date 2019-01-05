#!/bin/bash

gen_glyphs() {
    local -a names=()
    local -a widths=()
    local -a filenames=()
    local output=$1
    local sizemod=$2
    shift 2

    while [[ ! -z "$1" ]] ; do
        local fontname="$1"
        local pointsize="$2"
        local kerning="$3"
        local widthscale="$4"
        local glyphs="$5"

        for glyph in $glyphs ; do
            convert -background black -fill white -font "$fontname" -kerning $kerning -pointsize ${pointsize} label:$glyph -resize "${widthscale}%x100%" "glyph-$glyph-${pointsize}pt.png"
            names+=($glyph)
            widths+=($(identify -format '%[width]' "glyph-$glyph-${pointsize}pt.png"))
            filenames+=("glyph-$glyph-${pointsize}pt.png")
        done

        shift 5
    done

    convert "${filenames[@]}" -gravity center +append "$output.png"
    rm "${filenames[@]}"

    for (( i=0; i<${#names[@]}; i++ )) ; do
        echo "${names[$i]} => ${widths[$i]}"
    done

    local width=$(identify -format '%[width]' "$output.png")
    local height=$(identify -format '%[height]' "$output.png")
    echo "Width = ${width}"
    echo "Height = ${height}"

    convert "$output.png" -crop $(printf "%dx%d%+d%+d" ${width} $((${height} + ${sizemod})) 0 $(( (0 - ${sizemod}) / 2 ))) -depth 8 -define png:color-type=4 "crop-$output.png"

    width=$(identify -format '%[width]' "crop-$output.png")
    height=$(identify -format '%[height]' "crop-$output.png")
    convert -size ${width}x1 xc:black "crop-${output}_width.png"

    local curr=0
    for pixel in ${widths[@]} ; do
        curr=$(($curr + $pixel))
        convert "crop-${output}_width.png" -fill white -draw "point $(($curr-1)),0" -depth 8 -define png:color-type=4 "crop-${output}_width.png"
    done

    convert "crop-${output}_width.png" "crop-$output.png"  -gravity center -append "${output}.png"
    rm "crop-${output}_width.png" "crop-$output.png"
}

gen_glyphs glyphs-big -30 \
    "NotoSans-ExtraCondensedBold.ttf" 46 0 75 "0 1 2 3 4 5 6 7 8 9 . V A"

gen_glyphs glyphs-small -14 \
    "NotoSans-ExtraCondensedBold.ttf" 20 0 75 "0 1 2 3 4 5 6 7 8 9 . V A"

gen_glyphs icons -5 \
    "NotoSans-ExtraCondensedBold.ttf" 20 -1 75 "CV CC" \
    "Font Awesome 5 Free-Solid-900.otf" 16 0 100 "$(printf "\uF011 \uF1EB \uF023 \uF2C9")"
