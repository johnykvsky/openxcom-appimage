# OpenXcom - Linux AppImage

Based on kanpsu/openxcom-build

## Introduction

This repository contains docker image build to create AppImage package for OpenXcom game, for x86-64 / 64-bit architecture.

## OpenXcom

OpenXcom is an open-source clone of the popular UFO: Enemy Unknown (X-COM: UFO Defense in USA) turn-based strategy game by MicroProse.

For more information about OpenXcom please visit https://openxcom.org/ site.

OpenXcom source code is available on GitHub https://github.com/SupSuper/OpenXcom.

## AppImage

AppImages is a universal Linux package that can be used in any modern Linux distribution.

For more information about AppImage package please visit https://appimage.org/ site.

## Docker

Docker image contains all needed libraries/packages to build OpenXcom and create AppImage package

### Pre-build step

You will be prompted for your transifex token. If you don't have an API token, you can generate one in https://app.transifex.com/user/settings/api/

If you have one, you can copy `.transifexrc.dist` to `.transifexrc` and insert token into newly created file.

### Usage

* Build docker image: `docker build -t "openxcom:appimage" .`
* Run docker image: `docker run  -t -d -i -v $(pwd):/openxcom --device /dev/fuse --privileged "openxcom:appimage"`
* Log into docker image shell: `docker exec -it $(docker container ls --all --filter=ancestor=openxcom:appimage --format "{{.ID}}" --latest) /bin/bash`
* Go to app folder `cd /openxcom`
* Execute build and create AppImage package: `./scripts/build.sh`

Later you can stop the container with command `docker stop $(docker container ls --all --filter=ancestor=openxcom:appimage --format "{{.ID}}" --latest)`

### Additional info

If you need to extract game files from gog installer, please use https://github.com/dscharrer/innoextract
Sample command: `./innoextract -g -m -d ./u1 setup_x-com_ufo_defense_1.2_28046.exe`

If you have vanilla version of the game you might need those patches: https://github.com/OpenXcom/XcomDataPatch

Appimagekit `functions.sh` can be found here: https://github.com/AppImageCommunity/pkg2appimage

