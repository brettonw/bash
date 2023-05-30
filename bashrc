# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# Use case-insensitive filename globbing
shopt -s nocaseglob;

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
shopt -s cdspell;

set -a

# shut up the stupid Mac warning about using zsh
BASH_SILENCE_DEPRECATION_WARNING=1

PS1="\! (\h) \W : ";
HISTCONTROL=ignoredups;
unset HISTFILE;

LC_CTYPE=en_US.UTF-8;
LC_ALL=en_US.UTF-8;

BRETTONW="/Users/brettonw";

EDITOR="/usr/local/bin/bbedit --separate-windows --create-unix --clean --wait --resume";
SVN_EDITOR=$EDITOR;
GIT_EDITOR=$EDITOR;

# Set PATH, MANPATH, etc., for homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)";

# java...
JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk/libexec/openjdk.jdk/Contents/Home/";
#PATH="$JAVA_HOME/bin:$PATH";

# I prefer the gnu version of grep and etc.
PATH="${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin:$PATH";

# my path additions...
PATH=.:$BRETTONW/bin:$BRETTONW/bin/build.pl/bin:$PATH;

GPG_TTY=$(tty);

# don't let AWS page output
AWS_PAGER=""

set +a

alias xcode="open -a /Applications/Xcode.app";

function ec {
    /usr/local/bin/bbedit --separate-windows --create-unix --clean $*;
    #/usr/local/bin/mate $*;
}

# this function prints the paths of the open finder windows using the window index below
# the shell window, (1) is right below the shell, (2) is the second window below, etc.
function ff {
    osascript                                                   \
    -e 'tell application "Finder"'                              \
    -e "if (${1-1} <= (count Finder windows)) then"             \
    -e "get POSIX path of (target of window ${1-1} as alias)"   \
    -e 'else'                                                   \
    -e 'get POSIX path of (desktop as alias)'                   \
    -e 'end if'                                                 \
    -e 'end tell';
};

# this function executes cd into the path of the finder window below the shell
function cdff { cd "`ff $*`"; };

# git functions used frequently
source ~/bin/git-functions.sh

# add homebrew completions (these cause a problem if they are inside the export block)
source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh";
source $BRETTONW/bin/build.pl/bin/build-complete.sh;

# perl5 tools to avoid using sudo on cpan, after running
# sudo cpan local::lib
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

