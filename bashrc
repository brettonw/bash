# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# Use case-insensitive filename globbing
shopt -s nocaseglob;

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
shopt -s cdspell;

set -a

PS1="\! (\h) \W : ";
HISTCONTROL=ignoredups;
unset HISTFILE;

LC_CTYPE=en_US.UTF-8;
LC_ALL=en_US.UTF-8;

BRETTONW="/Users/brettonw";

#EDITOR="/usr/local/bin/bbedit --separate-windows --create-unix --clean --wait --resume";
EDITOR="/usr/local/bin/mate -w";
SVN_EDITOR=$EDITOR;
GIT_EDITOR=$EDITOR;

JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk/Contents/Home/";
source ~/perl5/perlbrew/etc/bashrc

PATH=.:$BRETTONW/bin:$BRETTONW/bin/apache-ant/bin:$BRETTONW/bin/apache-maven/bin:$BRETTONW/bin/build.pl/bin:$PATH;
source $BRETTONW/bin/build.pl/bin/build-complete.sh;

PATH=$PATH:~/Work/BatonDeBerger/jav-index/organize;

GPG_TTY=$(tty);

set +a

alias xcode="open -a /Applications/Xcode.app";

function ec {
    #/usr/local/bin/bbedit --separate-windows --create-unix --clean $*;
    /usr/local/bin/mate $*;
}

# this function prints the paths of the open finder windows using the window index below
# the shell window, (1) is right below the shell, (2) is the second window below, etc.
function ff {
	osascript 														\
	-e 'tell application "Finder"'									\
	-e "if (${1-1} <= (count Finder windows)) then"					\
	-e "get POSIX path of (target of window ${1-1} as alias)"		\
	-e 'else' 														\
	-e 'get POSIX path of (desktop as alias)'						\
	-e 'end if' 													\
	-e 'end tell';
};

# this function executes cd into the path of the finder window below the shell
function cdff { cd "`ff $*`"; };

# git functions used frequently
source ~/bin/git-completion.bash;
source ~/bin/git-functions.sh
