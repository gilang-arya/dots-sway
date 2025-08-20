#!/bin/bash

# Direktori penyimpanan screenshot
DIR="$HOME/Pictures/Screenshots"

# Membuat direktori jika belum ada
mkdir -p "$DIR"

# Nama file screenshot dengan timestamp
FILENAME="$(date +'%s_grim.png')"
FULLPATH="$DIR/$FILENAME"

# Ambil screenshot
grim "$FULLPATH"

# Cek apakah berhasil, lalu beri notifikasi
if [ $? -eq 0 ]; then
    dunstify -i "$FULLPATH" "Screenshot berhasil" "Disimpan di $FULLPATH"
else
    dunstify "Screenshot gagal" "Terjadi kesalahan saat mengambil screenshot."
fi
