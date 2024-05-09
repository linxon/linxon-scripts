export PATH="${PATH}:/usr/local/bin:/usr/local/sbin"

if [ "$TERM" != dumb ]; then
        RS="\[\033[0m\]"    # reset
        HC="\[\033[1m\]"    # hicolor
        UL="\[\033[4m\]"    # underline
        INV="\[\033[7m\]"   # inverse background and foreground
        FBLK="\[\033[30m\]" # foreground black
        FRED="\[\033[31m\]" # foreground red
        FGRN="\[\033[32m\]" # foreground green
        FYEL="\[\033[33m\]" # foreground yellow
        FBLE="\[\033[34m\]" # foreground blue
        FMAG="\[\033[35m\]" # foreground magenta
        FCYN="\[\033[36m\]" # foreground cyan
        FWHT="\[\033[37m\]" # foreground white
        BBLK="\[\033[40m\]" # background black
        BRED="\[\033[41m\]" # background red
        BGRN="\[\033[42m\]" # background green
        BYEL="\[\033[43m\]" # background yellow
        BBLE="\[\033[44m\]" # background blue
        BMAG="\[\033[45m\]" # background magenta
        BCYN="\[\033[46m\]" # background cyan
        BWHT="\[\033[47m\]" # background white
fi

PS1="$RS\[\e]0;\u@\h:[ \W ]\a\]$HC$FRED\h$RS$HC$FBLE $HC$FYEL\w $FRED\\$ $RS"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias ........='cd ../../../../../../..'
alias l='ls -CF'
alias ll='ls -lh'
alias lll='ls -alFh'
alias llll='ls -aliFh'
alias la='ls -A'
alias lt='ls -lth'
alias lu='ls -luh'
alias li='ls -lih'
alias llr='ls -lhR'
alias hh='history'
alias c='clear'
alias p='pwd'
alias ct='cat'
alias ca='cat'
alias top='htop'
alias oldtop='/usr/bin/top'
alias rc-service='service'
alias see_last_updates='gzip -dc /var/system-updater/system-updater-*.log.gz | less'

myip() {
        echo $(curl -s ifconfig.co)
}
