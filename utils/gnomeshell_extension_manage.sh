#!/bin/bash
# --------------------------------------------
# Install extension from Gnome Shell Extensions site
#
# See http://bernaerts.dyndns.org/linux/76-gnome/345-gnome-shell-install-remove-extension-command-line-script
#  for installation instruction
#
# Revision history :
#   13/07/2013 - V1.0 : Creation by N. Bernaerts
#   15/03/2015 - V1.1 : Update thanks to Michele Gazzetti
#   02/10/2015 - V1.2 : Disable wget gzip compression
#   05/07/2016 - V2.0 : Complete rewrite (system path updated thanks to Morgan Read)
#   09/08/2016 - V2.1 : Handle exact or previously available version installation (idea from eddy-geek)
#   09/09/2016 - V2.2 : Switch to gnome-shell to get version [UbuntuGnome 16.04] (thanks to edgard)
#   05/11/2016 - V2.3 : Trim Gnome version and add Fedora compatibility (thanks to Cedric Brandenbourger)
# -------------------------------------------

# check tools availability
command -v unzip >/dev/null 2>&1 || { zenity --error --text="Please install unzip"; exit 1; }
command -v wget >/dev/null 2>&1 || { zenity --error --text="Please install wget"; exit 1; }

# install path (user and system mode)
USER_PATH="$HOME/.local/share/gnome-shell/extensions"
[ -f "/etc/debian_version" ] && SYSTEM_PATH="/usr/share/gnome-shell/extensions" || SYSTEM_PATH="/usr/local/share/gnome-shell/extensions"

# set gnome shell extension site URL
GNOME_SITE="https://extensions.gnome.org"

# get current gnome version (major and minor only)
GNOME_VERSION="$(DISPLAY=":0" gnome-shell --version | tr -cd "0-9." | cut -d'.' -f1,2)"

# default installation path for default mode (user mode, no need of sudo)
INSTALL_MODE="user"
EXTENSION_PATH="${USER_PATH}"
INSTALL_SUDO=""

# help message if no parameter
if [ ${#} -eq 0 ];
then
    echo "Install/remove extension from Gnome Shell Extensions site https://extensions.gnome.org/"
    echo "Extension ID should be retrieved from https://extensions.gnome.org/extension/<ID>/extension-name/"
    echo "Parameters are :"
    echo "  --install               Install extension (default)"
    echo "  --remove                Remove extension"
    echo "  --user                  Installation/remove in user mode (default)"
    echo "  --system                Installation/remove in system mode"
    echo "  --version <version>     Gnome version (system detected by default)"
    echo "  --extension-id <id>     Extension ID in Gnome Shell Extension site (compulsory)"
    exit 1
fi

# iterate thru parameters
while test ${#} -gt 0
do
  case $1 in
    --install) ACTION="install"; shift; ;;
    --remove) ACTION="remove"; shift; ;;
    --user) INSTALL_MODE="user"; shift; ;;
    --system) INSTALL_MODE="system"; shift; ;;
    --version) shift; GNOME_VERSION="$1"; shift; ;;
    --extension-id) shift; EXTENSION_ID="$1"; shift; ;;
    *) echo "Unknown parameter $1"; shift; ;;
  esac
done

# if no extension id, exit
[ "${EXTENSION_ID}" = "" ] && { echo "You must specify an extension ID"; exit; }

# if no action, exit
[ "${ACTION}" = "" ] && { echo "You must specify an action command (--install or --remove)"; exit; }

# if system mode, set system installation path and sudo mode
[ "${INSTALL_MODE}" = "system" ] && { EXTENSION_PATH="${SYSTEM_PATH}"; INSTALL_SUDO="sudo"; }

# create temporary files
TMP_DESC=$(mktemp -t ext-XXXXXXXX.txt)
TMP_ZIP=$(mktemp -t ext-XXXXXXXX.zip)
TMP_VERSION=$(mktemp -t ext-XXXXXXXX.ver)
rm ${TMP_DESC} ${TMP_ZIP}

# get extension description
wget --quiet --header='Accept-Encoding:none' -O "${TMP_DESC}" "${GNOME_SITE}/extension-info/?pk=${EXTENSION_ID}"

# get extension name
EXTENSION_NAME=$(sed 's/^.*name[\": ]*\([^\"]*\).*$/\1/' "${TMP_DESC}")

# get extension description
EXTENSION_DESCR=$(sed 's/^.*description[\": ]*\([^\"]*\).*$/\1/' "${TMP_DESC}")

# get extension UUID
EXTENSION_UUID=$(sed 's/^.*uuid[\": ]*\([^\"]*\).*$/\1/' "${TMP_DESC}")

# if ID not known
if [ ! -s "${TMP_DESC}" ];
then
  echo "Extension with ID ${EXTENSION_ID} is not available from Gnome Shell Extension site."

# else, if installation mode
elif [ "${ACTION}" = "install" ];
then

  # extract all available versions
  sed "s/\([0-9]*\.[0-9]*[0-9\.]*\)/\n\1/g" "${TMP_DESC}" | grep "pk" | grep "version" | sed "s/^\([0-9\.]*\).*$/\1/" > "${TMP_VERSION}"

  # check if current version is available
  VERSION_AVAILABLE=$(grep "^${GNOME_VERSION}$" "${TMP_VERSION}")

  # if version is not available, get the next one available
  if [ "${VERSION_AVAILABLE}" = "" ]
  then
    echo "${GNOME_VERSION}" >> "${TMP_VERSION}"
    VERSION_AVAILABLE=$(cat "${TMP_VERSION}" | sort -V | sed "1,/${GNOME_VERSION}/d" | head -n 1)
  fi

  # if still no version is available, error message
  if [ "${VERSION_AVAILABLE}" = "" ]
  then
    echo "Gnome Shell version is ${GNOME_VERSION}."
    echo "Extension ${EXTENSION_NAME} is not available for this version."
    echo "Available versions are :"
    sed "s/\([0-9]*\.[0-9]*[0-9\.]*\)/\n\1/g" "${TMP_DESC}" | grep "pk" | grep "version" | sed "s/^\([0-9\.]*\).*$/\1/" | sort -V | xargs

  # else, install extension
  else
    # get extension description
    wget --quiet --header='Accept-Encoding:none' -O "${TMP_DESC}" "${GNOME_SITE}/extension-info/?pk=${EXTENSION_ID}&shell_version=${VERSION_AVAILABLE}"

    # get extension download URL
    EXTENSION_URL=$(sed 's/^.*download_url[\": ]*\([^\"]*\).*$/\1/' "${TMP_DESC}")

    # download extension archive
    wget --quiet --header='Accept-Encoding:none' -O "${TMP_ZIP}" "${GNOME_SITE}${EXTENSION_URL}"

    # unzip extension to installation folder
    ${INSTALL_SUDO} mkdir -p ${EXTENSION_PATH}/${EXTENSION_UUID}
    ${INSTALL_SUDO} unzip -oq "${TMP_ZIP}" -d ${EXTENSION_PATH}/${EXTENSION_UUID}
    ${INSTALL_SUDO} chmod +r ${EXTENSION_PATH}/${EXTENSION_UUID}/*

    # list enabled extensions
    EXTENSION_LIST=$(gsettings get org.gnome.shell enabled-extensions | sed 's/^.\(.*\).$/\1/')

    # if extension not already enabled, declare it
    EXTENSION_ENABLED=$(echo ${EXTENSION_LIST} | grep ${EXTENSION_UUID})
    [ "$EXTENSION_ENABLED" = "" ] && gsettings set org.gnome.shell enabled-extensions "[${EXTENSION_LIST},'${EXTENSION_UUID}']"

    # success message
    echo "Gnome Shell version is ${GNOME_VERSION}."
    echo "Extension ${EXTENSION_NAME} version ${VERSION_AVAILABLE} has been installed in ${INSTALL_MODE} mode (Id ${EXTENSION_ID}, Uuid ${EXTENSION_UUID})"
    echo "Restart Gnome Shell to take effect."

  fi

# else, it is remove mode
else

    # remove extension folder
    ${INSTALL_SUDO} rm -f -r "${EXTENSION_PATH}/${EXTENSION_UUID}"

    # success message
    echo "Extension ${EXTENSION_NAME} has been removed in ${INSTALL_MODE} mode (Id ${EXTENSION_ID}, Uuid ${EXTENSION_UUID})"
    echo "Restart Gnome Shell to take effect."

fi

# remove temporary files
rm -f ${TMP_DESC} ${TMP_ZIP} ${TMP_VERSION}
