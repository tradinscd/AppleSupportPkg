#!/bin/bash

BUILDDIR=$(dirname "$0")
pushd "$BUILDDIR" >/dev/null
BUILDDIR=$(pwd)
popd >/dev/null

NASMVER="2.13.03"

cd "$BUILDDIR"

prompt() {
  echo "$1"
  if [ "$FORCE_INSTALL" != "1" ]; then
    read -p "Enter [Y]es to continue: " v
    if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
      exit 1
    fi
  fi
}

updaterepo() {
  if [ ! -d "$2" ]; then
    git clone "$1" -b "$3" --depth=1 "$2" || exit 1
  fi
  pushd "$2" >/dev/null
  git pull
  popd >/dev/null
}

package() {
  if [ ! -d "$1" ]; then
    echo "Missing package directory"
    exit 1
  fi

  local ver=$(cat Include/AppleSupportPkgVersion.h | grep APPLE_SUPPORT_VERSION | cut -f4 -d' ' | cut -f2 -d'"' | grep -E '^[0-9.]+$')
  if [ "$ver" = "" ]; then
    echo "Invalid version $ver"
  fi

  pushd "$1" || exit 1
  rm -rf tmp || exit 1
  mkdir -p tmp/Drivers || exit 1
  mkdir -p tmp/Tools || exit 1
  cp ApfsDriverLoader.efi tmp/Drivers/ || exit 1
  # FIXME: return this back once we fix UEFI Secure Boot compatible Apple image loading.
  # cp AppleImageLoader.efi tmp/Drivers/ || exit 1
  cp AppleUiSupport.efi tmp/Drivers/   || exit 1
  cp UsbKbDxe.efi tmp/Drivers/         || exit 1
  pushd tmp || exit 1
  zip -qry ../"AppleSupport-v${ver}-${2}.zip" * || exit 1
  popd || exit 1
  rm -rf tmp || exit 1
  popd || exit 1
}

if [ "$BUILDDIR" != "$(printf "%s\n" $BUILDDIR)" ]; then
  echo "EDK2 build system may still fail to support directories with spaces!"
  exit 1
fi

if [ "$(which clang)" = "" ] || [ "$(which git)" = "" ] || [ "$(clang -v 2>&1 | grep "no developer")" != "" ] || [ "$(git -v 2>&1 | grep "no developer")" != "" ]; then
  echo "Missing Xcode tools, please install them!"
  exit 1
fi

if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
  echo "Missing or incompatible nasm!"
  echo "Download the latest nasm from http://www.nasm.us/pub/nasm/releasebuilds/"
  prompt "Last tested with nasm $NASMVER. Install it automatically?"
  pushd /tmp >/dev/null
  rm -rf "nasm-${NASMVER}-macosx.zip" "nasm-${NASMVER}"
  curl -OL "http://www.nasm.us/pub/nasm/releasebuilds/${NASMVER}/macosx/nasm-${NASMVER}-macosx.zip" || exit 1
  unzip -q "nasm-${NASMVER}-macosx.zip" "nasm-${NASMVER}/nasm" "nasm-${NASMVER}/ndisasm" || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo mv "nasm-${NASMVER}/nasm" /usr/local/bin/ || exit 1
  sudo mv "nasm-${NASMVER}/ndisasm" /usr/local/bin/ || exit 1
  rm -rf "nasm-${NASMVER}-macosx.zip" "nasm-${NASMVER}"
  popd >/dev/null
fi

if [ "$(which mtoc.NEW)" == "" ] || [ "$(which mtoc)" == "" ]; then
  echo "Missing mtoc or mtoc.NEW!"
  echo "To build mtoc follow: https://github.com/tianocore/tianocore.github.io/wiki/Xcode#mac-os-x-xcode"
  prompt "Install prebuilt mtoc and mtoc.NEW automatically?"
  rm -f mtoc mtoc.NEW
  unzip -q external/mtoc-mac64.zip mtoc.NEW || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo cp mtoc.NEW /usr/local/bin/mtoc || exit 1
  sudo mv mtoc.NEW /usr/local/bin/ || exit 1
fi

if [ ! -d "Binaries" ]; then
  mkdir Binaries || exit 1
  cd Binaries || exit 1
  ln -s ../UDK/Build/AppleSupportPkg/RELEASE_XCODE5/X64 RELEASE || exit 1
  ln -s ../UDK/Build/AppleSupportPkg/DEBUG_XCODE5/X64 DEBUG || exit 1
  ln -s ../UDK/Build/AppleSupportPkg/NOOPT_XCODE5/X64 NOOPT || exit 1
  cd .. || exit 1
fi

while true; do
  if [ "$1" == "--skip-tests" ]; then
    SKIP_TESTS=1
    shift
  elif [ "$1" == "--skip-build" ]; then
    SKIP_BUILD=1
    shift
  elif [ "$1" == "--skip-package" ]; then
    SKIP_PACKAGE=1
    shift
  else
    break
  fi
done

if [ "$1" != "" ]; then
  MODE="$1"
  shift
fi

if [ ! -f UDK/UDK.ready ]; then
  rm -rf UDK
fi

updaterepo "https://github.com/tianocore/edk2" UDK UDK2018 || exit 1
cd UDK
updaterepo "https://github.com/acidanthera/EfiPkg" EfiPkg master || exit 1
updaterepo "https://github.com/acidanthera/OcSupportPkg" OcSupportPkg master || exit 1

if [ ! -d AppleSupportPkg ]; then
  ln -s .. AppleSupportPkg || exit 1
fi

source edksetup.sh || exit 1

if [ "$SKIP_TESTS" != "1" ]; then
  make -C BaseTools || exit 1
  touch UDK.ready
fi

if [ "$SKIP_BUILD" != "1" ]; then
  if [ "$MODE" = "" ] || [ "$MODE" = "DEBUG" ]; then
    build -a X64 -b DEBUG -t XCODE5 -p AppleSupportPkg/AppleSupportPkg.dsc || exit 1
  fi

  if [ "$MODE" = "" ] || [ "$MODE" = "DEBUG" ]; then
    build -a X64 -b NOOPT -t XCODE5 -p AppleSupportPkg/AppleSupportPkg.dsc || exit 1
  fi

  if [ "$MODE" = "" ] || [ "$MODE" = "RELEASE" ]; then
    build -a X64 -b RELEASE -t XCODE5 -p AppleSupportPkg/AppleSupportPkg.dsc || exit 1
  fi
fi

cd .. || exit 1

if [ "$SKIP_PACKAGE" != "1" ]; then
  if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "DEBUG" ]; then
    package "Binaries/DEBUG" "DEBUG" || exit 1
  fi

  if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "RELEASE" ]; then
    package "Binaries/RELEASE" "RELEASE" || exit 1
  fi
fi
