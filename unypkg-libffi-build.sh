#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2086,SC2016

set -xv
######################################################################################################################
### Setup Build System and GitHub

wget -qO- uny.nu/pkg | bash -s buildsys
mkdir /uny/tmp

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/uny/build/github_conf
source /uny/uny/build/download_functions
source /uny/git/unypkg/fn

######################################################################################################################
### Timestamp & Download

uny_build_date_seconds_now="$(date +%s)"
uny_build_date_now="$(date -d @"$uny_build_date_seconds_now" +"%Y-%m-%dT%H.%M.%SZ")"

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="libffi"
pkggit="https://github.com/libffi/libffi.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "v[0-9.]*$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "v[0-9.]*" | sed "s|v||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

check_for_repo_and_create
git_clone_source_repo

cd libffi || exit
./autogen.sh
cd /uny/sources || exit

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
unyc <<"UNYEOF"
set -xv
source /uny/build/functions

pkgname="libffi"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths_temp

####################################################
### Start of individual build script

unset LD_RUN_PATH

./configure --prefix=/uny/pkg/"$pkgname"/"$pkgver" \
    --disable-static \
    --with-gcc-arch=native

make -j"$(nproc)"
make -j"$(nproc)" check
make install

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
