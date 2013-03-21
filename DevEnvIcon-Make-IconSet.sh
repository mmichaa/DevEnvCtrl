#!/bin/bash

SRC=$1 # DevEnvIcon-White-1024x1024px.png
DST=$2 # DevEnvIcon-White.iconset

rm $DST/*
cp $SRC $DST/icon_512x512@2x.png
convert $DST/icon_512x512@2x.png -resize 50% $DST/icon_512x512.png
cp $DST/icon_512x512.png $DST/icon_256x256@2x.png
convert $DST/icon_256x256@2x.png -resize 50% $DST/icon_256x256.png
cp $DST/icon_256x256.png $DST/icon_128x128@2x.png
convert $DST/icon_128x128@2x.png -resize 50% $DST/icon_128x128.png

convert $DST/icon_128x128.png -resize 50% $DST/icon_32x32@2x.png
convert $DST/icon_32x32@2x.png -resize 50% $DST/icon_32x32.png
cp $DST/icon_32x32.png $DST/icon_16x16@2x.png
convert $DST/icon_16x16@2x.png -resize 50% $DST/icon_16x16.png

iconutil -c icns $DST
