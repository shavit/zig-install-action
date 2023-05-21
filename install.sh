#!/bin/bash

COLOR_ERROR='\033[0;31m'
COLOR_SUCCESS='\033[0:32m'
COLOR_WARN='\033[0;33m'
COLOR_CLEAR=$(tput sgr0)

print_progress_success () {
    echo -e "\r${COLOR_SUCCESS} ✔ ${1} ${COLOR_CLEAR}"
}

print_progress_warn () {
    echo -en "\r${COLOR_WARN} • ${1} ${COLOR_CLEAR}"
}

print_progress_failure () {
    echo -e "\r${COLOR_ERROR} ✕ ${1} ${COLOR_CLEAR}"
}

VERSIONS="master 0.9.1 0.9.0 0.8.1 0.8.0 0.7.1 0.7.0 0.6.0 0.5.0 0.4.0 0.3.0 0.2.0 0.10.1 0.10.0 0.1.1"
FLAVOURS="src bootstrap x86_64-macos aarch64-macos x86_64-linux aarch64-linux riscv64-linux powerpc64le-linux powerpc-linux x86-linux x86_64-windows aarch64-windows x86-windows"

print_usage () {
    echo -e "\nUsage: install.sh [version] [flavour]"
    echo -e "\nVersion:\n"
    echo -e "${VERSIONS}" | tr " " "\n"
    echo -e "\nFlavour:\n"
    echo -e "${FLAVOURS}" | tr " " "\n"
    echo ""
}

has_item () {
    items=$1
    item=$2
    for x in $items; do
        if [ "${x}" = "${item}" ]; then
            return 0;
        fi
    done

    return 1; # error
}

download_flavour () {
    version="${1}"
    flavour="${2}"
    curl -sL https://ziglang.org/download/index.json \
        | jq -cr --arg verion "${version}" --arg flavour "${flavour}" \
        '."'"${version}"'"."'"${flavour}"'"'
}


if [ $# -lt 2 ];
then
   print_usage
   echo "Error: Missing arguments"
   exit 1
fi

version=$1
flavour=$2
    
if ! has_item "${VERSIONS}" "${version}"; then
    print_usage
    print_progress_failure "Error: Invalid version argument provided"
    exit 1;
fi

if ! has_item "${FLAVOURS}" "${flavour}"; then
    print_usage
    print_progress_failure "Error: Invalid flavour argument provided"
    exit 1;
fi
    
print_progress_warn "Getting ${flavour} URL"
res=$(download_flavour "${version}" "${flavour}")
print_progress_success "Getting ${flavour} URL"
tarball=$(echo "${res}" | jq -cr '.tarball')
shasum=$(echo "${res}" | jq -cr '.shasum')
filename="${tarball##*/}"

print_progress_warn "Downloading tarball ${filename}"
curl -OLs "${tarball}"
print_progress_success "Downloading tarball ${filename}"

print_progress_warn "Verifying checksum"
file_checksum=$(sha256sum "${filename}" | cut -d ' ' -f1)
if [ "${shasum}" != "${file_checksum}" ]; then
    print_progress_failure "Error: Unmatched checksum"
    exit 1;
fi
print_progress_success "Verifying Checksum"

print_progress_warn "Installing ${filename}"
tar -xf "${filename}"
filedir=$(basename "${filename}" .tar.xz)
mkdir -p "${PWD}/bin"
ln -rs "${filedir}/zig" "${PWD}/bin/zig"
print_progress_success "Installing ${filename}"

print_progress_warn "Configuring zig executable"
export PATH="${PATH}:${PWD}/bin"
echo "${PWD}/bin" >> "${GITHUB_PATH}"
print_progress_success "Configuring zig executable"

print_progress_success "Done"
