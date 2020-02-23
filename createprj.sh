#!/usr/bin/env bash
# See https://dev.to/thiht/shell-scripts-matter for additional details
#
# Please, always check your scripts with "shellcheck"
#

set -euo pipefail
IFS=$'\n\t'

#/ Description:
#/   Create a Python project using a template useful to support Conda environment,
#/   setuptools and publication on PyPi platform
#/
#/ Usage:
#/   createprj.sh [options] destination_dir
#/ Options:
#/   -n|--prjname: new project name
#/   -a|--authorname: author name
#/   -e|--authoremail: author email
#/   -s|--shortdescription: prject short description
#/   -u|--url: url where to find info or source
#/   -d|--downloadurl: url where to download project
#/   destination_dir: directory where to create the project
#/       (shall exist and will be overwritten)
#/   -v|--verbose: print verbose information during execution
#/   --help: Display this help message
#/
#/ Examples:
#/   createprj.sh -n new_project_name /tmp/prjdir
#/   createprj.sh -n new_project_name -a "Rod McBan" -e "rodmcban@example.org" \
#/       -s "A simple python project" -u "https://github.com/fpiantini/pyprjtemplate" \
#/       -d "https://github.com/fpiantini/jpyprjtemplate/archive/v1.0.0.tar.gz" /tmp/prjdir
#/
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

readonly LOG_FILE="/tmp/$(basename "$0").log"
info()    { echo "[INFO]    $*" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "[WARNING] $*" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "[ERROR]   $*" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "[FATAL]   $*" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }
debug()   { if [ "$_verboselevel" -gt 0 ]; then echo "[DEBUG]   $*" | tee -a "$LOG_FILE" >&2 ; fi }
xdebug()   { if [ "$_verboselevel" -gt 1 ]; then echo "[XDEBUG]  $*" | tee -a "$LOG_FILE" >&2 ; fi }
#cleanup() {
#  info "cleanup called"
#  # Remove temporary files
#  # Restart services
#  # ...
#}

# ------------------------------------------------------------------------
init_environment() {

  _verboselevel=0
  _override=0

  # uncomment if you need them
  _myabspathname=$(realpath "$0")
  #_myname=$(basename "$0")
  _mydir=$(dirname "$_myabspathname")

  _prjname="my_python_project"
  _authorname=""
  _authoremail=""
  _shortdesc="My python project"
  _prjurl=""
  _downloadurl=""
  _askproceed=1

  _destination_dir=""
}

# ------------------------------------------------------------------------
parse_command_line() {

  while [[ $# -gt 1 ]]
  do
    key="$1"

    case $key in
      # examples...
      -n|--prjname)
        _prjname="$2"
        shift # past argument
        ;;
      -a|--authorname)
        _authorname="$2"
        shift # past argument
        ;;
      -e|--authoremail)
        _authoremail="$2"
        shift # past argument
        ;;
      -s|--shortdescription)
        _shortdesc="$2"
        shift # past argument
        ;;
      -u|--url)
        _prjurl="$2"
        shift # past argument
        ;;
      -d|--downloadurl)
        _downloadurl="$2"
        shift # past argument
        ;;
      -y|--assume-yes)
        _askproceed=0
        ;;
      -o|--override)
        _override=1
        ;;
      -v|--verbose)
        _verboselevel=$((_verboselevel + 1))
        ;;
      *)
        warning "Ignoring unknown option $key"
        # unknown option
        ;;
    esac

    shift # past argument or value
  done

  # final mandatory args
  if [[ $# -gt 0 ]]; then
    _destination_dir=$1
  else
    fatal "Please specify a destination directory (use --help for usage information)"
  fi

}

# ------------------------------------------------------------------------
check_environment() {

  if [ ! -d "$_destination_dir" ]; then
    fatal "Directory $_destination_dir does not exist, please create it and initialize if necessary"
  fi

  info "new project name   = $_prjname"
  info "destination dir    = $_destination_dir"
  info "author name        = $_authorname"
  info "author email       = $_authoremail"
  info "project short desc = $_shortdesc"
  info "project URL        = $_prjurl"
  info "project dwload URL = $_downloadurl"
  if [ "$_override" -ne 0 ]; then
    warning "*** OVERRIDING existing files ***"
  else
    info "Do not override existing files"
  fi

  if [ "$_askproceed" -ne 0 ]; then
    _proceed="n"
    read -rp "Proceed [yN]? : " _proceed
    if [ -z "$_proceed" ] || [ "${_proceed,,}" != "y" ]; then
      info "Aborting procedure..."
      exit 0
    fi
  fi

}

# ------------------------------------------------------------------------
do_everything() {

  _readmetemplate="$_mydir"/README_template.md
  _setupcfgtemplate="$_mydir"/setup.cfg
  _setuppytemplate="$_mydir"/setup.py
  _envfiletemplate="$_mydir"/environment.yml
  _prjmainsrctemplate="$_mydir"/project_name/project_name.py

  _destdir=$(realpath "$_destination_dir")
  _readmedest="$_destdir"/README.md
  _setupcfgdest="$_destdir"/setup.cfg
  _setuppydest="$_destdir"/setup.py
  _envfiledest="$_destdir"/environment.yml
  _destsrcdir="$_destdir"/"$_prjname"
  _prjmainsrcdest="$_destsrcdir"/"$_prjname".py

  xdebug "_readmetemplate     = $_readmetemplate"
  xdebug "_setupcfgtemplate   = $_setupcfgtemplate"
  xdebug "_setuppytemplate    = $_setuppytemplate"
  xdebug "_envfiletemplate    = $_envfiletemplate"
  xdebug "_prjmainsrctemplate = $_prjmainsrctemplate"

  xdebug "_readmedest         = $_readmedest"
  xdebug "_setupcfgdest       = $_setupcfgdest"
  xdebug "_setuppydest        = $_setuppydest"
  xdebug "_envfiledest        = $_envfiledest"
  xdebug "_prjmainsrcdest     = $_prjmainsrcdest"

  prepare_destination_dir

  fill_destination_dir

}

# ------------------------------------------------------------------------
prepare_destination_dir() {

  if [ -e "$_readmedest" ] && [ "$_override" -ne 0 ]; then
    info "Overriding: $_readmedest"
    rm -f "$_readmedest"
  fi

  if [ -e "$_setupcfgdest" ] && [ "$_override" -ne 0 ]; then
    info "Overriding: $_setupcfgdest"
    rm -f "$_setupcfgdest"
  fi

  if [ -e "$_setuppydest" ] && [ "$_override" -ne 0 ]; then
    info "Overriding: $_setuppydest"
    rm -f "$_setuppydest"
  fi

  if [ -e "$_envfiledest" ] && [ "$_override" -ne 0 ]; then
    info "Overriding: $_envfiledest"
    rm -f "$_envfiledest"
  fi

  if [ ! -d "$_destsrcdir" ]; then
    if [ -e "$_destsrcdir" ]; then
      # destination src dir pathname exists already and it is not a directory.
      # Cannot proceed without the risk to broke something
      if [ "$_override" -eq 0 ]; then
        error "Pathname for destination source directory exists but it is not a directory,"
        error "and override is not specified. Cannot proceed."
        exit 1
      else
        info "Overriding: $_destsrcdir"
        rm -f "$_destsrcdir"
      fi
    fi
    # create sources directory
    mkdir -p "$_destsrcdir"

  else
    # destination source directory "exists"...
    # check for main file existence
    if [ -e "$_prjmainsrcdest" ] && [ "$_override" -ne 0 ]; then
      info "Overriding: $_prjmainsrcdest"
      rm -f "$_prjmainsrcdest"
    fi
  fi
}

# ------------------------------------------------------------------------
fill_destination_dir() {

  if [ ! -e "$_setupcfgdest" ]; then
    cp -a "$_setupcfgtemplate" "$_setupcfgdest"
  else 
    info "Preserving existing $_setupcfgdest"
  fi

  if [ ! -e "$_readmedest" ]; then
    sed "s#<project_name>#$_prjname#g" "$_readmetemplate" \
      | sed "s#<project_short_description>#$_shortdesc#g" > "$_readmedest"
  else
    info "Preserving existing $_readmedest"
  fi

  if [ ! -e "$_envfiledest" ]; then
    sed "s#<project_name>#$_prjname#g" "$_envfiletemplate" > "$_envfiledest"
  else
    info "Preserving existing $_envfiledest"
  fi

  if [ ! -e "$_setuppydest" ]; then
    sed "s#<project_name>#$_prjname#g" "$_setuppytemplate" \
      | sed "s#<author_name>#$_authorname#g" \
      | sed "s#<author_email>#$_authoremail#g" \
      | sed "s#<project_short_description>#$_shortdesc#g" \
      | sed "s#<project_url>#$_prjurl#g" \
      | sed "s#<download_url>#$_downloadurl#g" > "$_setuppydest"
  else
    info "Preserving existing $_setuppydest"
  fi

  if [ ! -e "$_prjmainsrcdest" ]; then
    cp -a "$_prjmainsrctemplate" "$_prjmainsrcdest"
  else
    info "Preserving existing source template $_prjmainsrcdest"
  fi
}

# ------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------
main() {
  # --- initializations --------------
  init_environment
  parse_command_line "$@"
  check_environment

  # Do the real job of this script...
  do_everything

  # ----------------------------------
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  ###trap cleanup EXIT
  # Script goes here
  # ...
  main "$@"
  exit 0
fi

