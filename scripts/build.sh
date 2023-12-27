#!/bin/bash
set -e

/usr/sbin/update-ccache-symlinks
echo "Symlinks for ccache updated"

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "${SCRIPT}")
WORKDIR="${PWD}"

# Load helper functions
source "${SCRIPTDIR}/appimagekit/functions.sh"

# Define build variables
APP="OpenXcom"
LOWERAPP="openxcom"
DATE=$(date -u +'%Y%m%d')

case "$(uname -i)" in
  x86_64|amd64)
    SYSTEM_ARCH="x86_64"
    SYSTEM_PLATFORM="x86-64";;
  *)
    echo "Unsupported system architecture"
    exit 1;;
esac
echo "System architecture: ${SYSTEM_PLATFORM}"

case "${ARCH:-$(uname -i)}" in
  x86_64|amd64)
    TARGET_ARCH="x86_64"
    PLATFORM="x86-64";;
  *)
    echo "Unsupported target architecture"
    exit 1;;
esac
echo "Target architecture: ${PLATFORM}"

# Display CMake version
cmake --version

# Enable ccache
export PATH="/usr/lib/ccache:${PATH}"
export CCACHE_DIR="${WORKDIR}/cache/ccache"

# Build OpenXcom binaries
if [ -d openxcom ]; then
  cd openxcom
  git clean -xdf
  git checkout master
  git pull
else
  git clone https://github.com/SupSuper/OpenXcom.git openxcom
  cd openxcom
fi

COMMIT_HASH=$(git log -n 1 --pretty=format:'%h')
COMMIT_TIMESTAMP=$(git log -n 1 --pretty=format:'%cd' --date=format:'%Y-%m-%d %H:%M')

echo "Standard build"
# For standard builds use current date and commit hash as package version number
VERSION="${DATE}_${COMMIT_HASH}"
INTERNAL_VERSION_SUFFIX=".${COMMIT_HASH} (${COMMIT_TIMESTAMP})"

# Build OpenXcom
cd "${WORKDIR}/openxcom"
cmake \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="/usr" \
  -DBUILD_PACKAGE=OFF \
  -DOPENXCOM_VERSION_STRING="${INTERNAL_VERSION_SUFFIX}" \
  .
make
ccache -s

# Download translations
if [[ ! -f ~/.transifexrc && -f "${WORKDIR}/.transifexrc" ]]; then
  cp "${WORKDIR}/.transifexrc" ~/
  echo "tx: transifexrc copied"
fi

cd "${WORKDIR}/openxcom"

if [ -f ~/.transifexrc ]; then
  echo "tx: transifexrc found"
  tx --root-config ~/.transifexrc pull -a
  echo "tx: transifexrc used"
else
  tx pull -a
fi

# Prepare AppImage working directory
cd "${WORKDIR}"
mkdir -p "appimage"
cd "appimage"
download_appimagetool

# Initialize AppDir
rm -rf "AppDir"
mkdir "AppDir"
mkdir -p "AppDir/usr/bin"
mkdir -p "AppDir/usr/lib"
mkdir -p "AppDir/usr/share/openxcom"
APPDIR="${PWD}/AppDir"

# Copy binaries
cp -p "${WORKDIR}/openxcom/bin/openxcom" "${APPDIR}/usr/bin/"

# Copy libraries
cd "${APPDIR}"
copy_deps
delete_blacklisted
cd "${OLDPWD}"
# Fix: Remove NVIDIA GLX libraries
rm -rf "${APPDIR}/usr/lib/nvidia-"*
# Fix: Do not store libraries in subdirectories (potential LD_LIBRARY_PATH problem)
find "${APPDIR}/usr/lib/" -type f -print0 | xargs -0 mv -t "${APPDIR}/usr/lib/"
find "${APPDIR}/usr/lib/" -mindepth 1 -type d -print0 | xargs -0 rm -rf

# Copy assets
cp -r "${WORKDIR}/openxcom/bin/"* "${APPDIR}/usr/share/openxcom/"
rm -f "${APPDIR}/usr/share/openxcom/openxcom"

# Copy translations
cp -r "${WORKDIR}/openxcom/translations/openxcom/common/Language/"* "${APPDIR}/usr/share/openxcom/common/Language/"
#cp -r "${WORKDIR}/translations/openxcom/install/win/Language/"* "${APPDIR}/usr/share/openxcom/install/win/Language/"
cp -r "${WORKDIR}/openxcom/translations/openxcom/standard/xcom1/Language/"* "${APPDIR}/usr/share/openxcom/standard/xcom1/Language/"
cp -r "${WORKDIR}/openxcom/translations/openxcom/standard/xcom2/Language/"* "${APPDIR}/usr/share/openxcom/standard/xcom2/Language/"
cp -r "${WORKDIR}/openxcom/translations/openxcom-extended/common/Language/"* "${APPDIR}/usr/share/openxcom/common/Language/"
cp -r "${WORKDIR}/openxcom/translations/openxcom-extended/standard/xcom1/Language/"* "${APPDIR}/usr/share/openxcom/standard/xcom1/Language/"
cp -r "${WORKDIR}/openxcom/translations/openxcom-extended/standard/xcom2/Language/"* "${APPDIR}/usr/share/openxcom/standard/xcom2/Language/"

# Setup desktop integration (launcher, icon, menu entry)
cp "${WORKDIR}/openxcom/res/linux/openxcom.desktop" "${APPDIR}/${LOWERAPP}.desktop"
cp "${WORKDIR}/openxcom/res/linux/icons/openxcom_128x128.png" "${APPDIR}/${LOWERAPP}.png"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/48x48/apps"
cp "${WORKDIR}/openxcom/res/linux/icons/openxcom_48x48.png" "${APPDIR}/usr/share/icons/hicolor/48x48/apps/${LOWERAPP}.png"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/128x128/apps"
cp "${WORKDIR}/openxcom/res/linux/icons/openxcom_128x128.png" "${APPDIR}/usr/share/icons/hicolor/128x128/apps/${LOWERAPP}.png"
cd "${APPDIR}"
get_apprun
cd "${OLDPWD}"

# Create AppImage bundle
if [[ "${VERSION}" =~ ^v[0-9]+\.[0-9]+ ]]; then
  VERSION=${VERSION:1}
fi
APPIMAGE_FILE_NAME="OpenXcom_${VERSION}_${PLATFORM}.AppImage"
cd "${WORKDIR}/appimage"
./appimagetool -n "${APPDIR}"
mv *.AppImage "${WORKDIR}/${APPIMAGE_FILE_NAME}"

cd "${WORKDIR}"
sha1sum *.AppImage
