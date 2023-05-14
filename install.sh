#!/bin/bash

echo "Downloading from master";

tarball=$(curl -sL https://ziglang.org/download/index.json \
    | jq -cr '.master."x86_64-linux".tarball')
curl -OL "${tarball}"
filename="${tarball##*/}"
shasum=$(curl -sL https://ziglang.org/download/index.json \
    | jq -cr '.master."x86_64-linux".shasum')
file_checksum=$(sha256sum "${filename}" | cut -d ' ' -f1)

if [ "${shasum}" != "${file_checksum}" ]; then
    echo "Error: Unmatched checksum"
    exit 1;
fi

echo "Installing ${filename}"
tar -xf "${filename}"
filedir=$(basename "${filename}" .tar.xz)
mkdir "$PWD/bin"
ln -rs "${filedir}/zig" "${PWD}/bin/zig"
export PATH="${PATH}:${PWD}/bin"
echo "${PWD}/bin" >> "${GITHUB_PATH}"
echo "Done"
