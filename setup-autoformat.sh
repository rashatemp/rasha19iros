#!/bin/bash

pushd "$(dirname $0)" >/dev/null

bold=""
red=""
green=""
normal=""

if test -t 1; then
  ncolors=$(tput colors)
  if test -n "$ncolors" && test $ncolors -ge 8; then
    bold="$(tput bold)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    normal="$(tput sgr0)"
  fi
fi

if [ ! -e .git-formatter.pl ]; then
  echo "${bold}${red}.git-formatter.pl not found, tex formatter was not installed correctly.${normal}" >&2
  popd >/dev/null
  exit -1
fi

git diff --quiet --exit-code
changed=$?
git diff --quiet --cached --exit-code
staged=$?

if [ $changed != 0 -o $staged != 0 ]; then
    echo "${bold}${red}You have uncommitted changes. Please commit them first before running this script.${normal}" >&2
    popd >/dev/null
    exit -2
fi

cat <<END

This script installs a filter that re-formats your TEX files according to
your preferences automatically every time you check in or check out a file.

END

perl -e 'use Text::Reflow;' 2>/dev/null
reflow=$?
OPTION_SENTENCE="Format one sentence per line"
OPTION_PARAGRAPH="Format one paragraph per line"
OPTION_SERVER="Use same format as the GIT server does"
OPTION_WRAP="Wrap lines after fixed number of columns"
OPTION_UNINSTALL="Uninstall the filter, do not do anything"
if [ $reflow != 0 ]; then
    echo "Optional feature not available:"
    echo "    Line wrapping after a fixed number of clumns is not available on your machine."
    echo "    To enable it, install the Perl module Text::Reflow and run this script again."
    case "$OSTYPE" in
    linux-gnu) echo "    sudo apt-get install libtext-reflow-perl";;
    darwin*)   echo "    cpan -i Text::Reflow";;
    esac
    echo
    options=("$OPTION_SENTENCE" "$OPTION_PARAGRAPH" "$OPTION_SERVER" "$OPTION_UNINSTALL")
else
    options=("$OPTION_SENTENCE" "$OPTION_PARAGRAPH" "$OPTION_WRAP" "$OPTION_SERVER" "$OPTION_UNINSTALL")
fi

echo "Please select your favorite format:"

SMUDGE=""
PS3=$'\n'"${bold}Please enter your choice: ${normal}"
select opt in "${options[@]}"
do
    case "$opt" in
        "${OPTION_SENTENCE}")
            SMUDGE="sentence"
            break
            ;;
        "${OPTION_PARAGRAPH}")
            SMUDGE="paragraph"
            break
            ;;
        "${OPTION_WRAP}")
            SMUDGE="wrap"
            break
            ;;
        "${OPTION_SERVER}")
            SMUDGE="unchanged"
            break
            ;;
        "${OPTION_UNINSTALL}")
            git config --unset-all filter.texformatter.smudge
            git config --unset-all filter.texformatter.clean
            echo "Uninstalled filter."
            popd >/dev/null
	    exit 0
            ;;
        *) echo "Invalid option, choose again or press Ctrl+C to abort.";;
    esac
done

if [ "${SMUDGE}" = "wrap" ]; then
	read -p "${bold}Number of columns: ${normal}" COLS
	SMUDGE="${SMUDGE} ${COLS}"
fi

git config --local filter.texformatter.clean  "$(pwd)/.git-formatter.pl clean sentence"
if [ "${SMUDGE}" = "unchanged" ]; then
    git config --local filter.texformatter.smudge "cat"
else
    git config --local filter.texformatter.smudge "$(pwd)/.git-formatter.pl smudge ${SMUDGE}"
fi

echo
if ! grep -q "filter=texformatter" .gitattributes 2>/dev/null; then
    echo "*.tex text=auto filter=texformatter diff=tex" >> .gitattributes
    git add .gitattributes
    git commit -m "Changed .gitattributes to install tex filter"
    echo "Installed tex filter for all *.tex files. Edit the .gitattributes file to limit filter to specific files."
fi

# don't need stashing as we make sure that there are no uncommitted changes
git checkout HEAD -- $(pwd)

echo "${bold}${green}Successfully installed filter.${normal}"
popd >/dev/null
exit 0
