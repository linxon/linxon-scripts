## Команда - exit (можно использовать соч. клавиш Ctrl+D)
# в gentoo есть q-applets
[ -x /usr/bin/q ] || alias q='exit' && alias quit='exit'
[ -x /usr/bin/percol ] && alias pcol='/usr/bin/percol'

## Запускаем xfce с поддержкой polkit
# [ -x /usr/bin/startxfce4 ] && {
# 	alias startx='/usr/bin/startxfce4 --with-ck-launch'
# 	alias startxfce4='/usr/bin/startxfce4 --with-ck-launch'
# }

## Команда — clear
alias c='clear'
alias p='pwd'
alias pc='pcopy'
alias pwdc='pcopy'
alias wdu='watch -n 1 du -sh'
alias wfree='watch -n 1 free'
alias wdf='watch -n 1 "df -h"'
alias lsusb='watch -n 1 lsusb'
alias cal='cal -Ym'
alias man_sections='LC_ALL=C man -P "less -g +/^[A-Z].*"'
alias ifind_here="find ./ -type f -iname"
alias clfile='cat /dev/null >'
alias mapscii='telnet mapscii.me'
alias myip='myip4'
alias cpuz='watch -n1 "cat /proc/cpuinfo | grep -e \"core id\" -e \"cpu MHz\""'
[ -x /usr/bin/ccat ] && alias cat='ccat'
[ -x /usr/bin/vim ] && alias vimlast='vim $(ls -t | head -1)'
[ -x /usr/bin/pwndbg ] && alias pwndbg='pwndbg -ex init-pwndbg'
[ -x /usr/bin/tailf ] || alias tailf="tail -f"
[ -x /usr/bin/euses ] && alias euses='/usr/bin/euses -cv'
[ -x /usr/bin/wget ] && alias wget='wget -c'
[ -x /usr/bin/ncdu ] && alias ncdu='ncdu --color=dark'
[ -x /opt/bin/yandex-disk ] && alias wyadisk='watch -n1 yandex-disk status'
[ -x /usr/bin/sensors ] && alias sensors='watch -n 1 sensors'
[ -x /usr/bin/youtube-dl ] && {
	alias youtF="youtube-dl -F"
	alias youtf="youtube-dl -f"
}
[ -x /usr/bin/htop ] && {
	alias oldtop='/usr/bin/top'
	alias top='htop'
}

[[ -x /usr/bin/docker && ! $(type -t d) =~ ^(alias|file) ]] && alias d='docker'
[[ -x /usr/bin/kubectl && ! $(type -t k) =~ ^(alias|file) ]] && alias k='kubectl'
[[ -x /usr/bin/minikube && ! $(type -t m) =~ ^(alias|file) ]] && alias m='minikube'
[[ -x /usr/bin/podman && ! $(type -t pod) =~ ^(alias|file) ]] && alias pod='podman'

[ -x /usr/bin/git ] && {
	alias gst='git status'
	alias gdf='git diff'
	alias glp='git log -p'
	alias glg='git log --graph --pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
}

[ -d "/mnt/cache/${USER}" ] && alias cdC='cd /mnt/cache/${USER}'
[ -d "/run/media/${USER}" ] && alias cdm='cd /run/media/${USER}'
[ -d '/etc/portage' ] && alias cdp='cd /etc/portage'
[ -d '/tmp/linxon-tmp-files' ] && alias cdW='cd /tmp/linxon-tmp-files'
[ -d "${HOME}/GitClones" ] && alias cdG='cd -P ~/GitClones'
[ -d "${HOME}/Cloud" ] && alias cdCloud='cd -P ~/Cloud'
[ -d "${XDG_DOCUMENTS_DIR}" ] && alias cdDoc='cd -P ${XDG_DOCUMENTS_DIR}'
[ -d "${XDG_DOWNLOAD_DIR}" ] && alias cdDw='cd -P ${XDG_DOWNLOAD_DIR}'
[ -d "${XDG_MUSIC_DIR}" ] && alias cdM='cd -P ${XDG_MUSIC_DIR}'
[ -d "${XDG_PICTURES_DIR}" ] && alias cdPic='cd -P ${XDG_PICTURES_DIR}'
[ -d "${XDG_VIDEOS_DIR}" ] && alias cdVid='cd -P ${XDG_VIDEOS_DIR}'
if [ -x /usr/bin/gio ] || [ -d /run/user/${UID}/gvfs ]; then
	alias cdgvfs='cd /run/user/${UID}/gvfs'
fi

[ -x /usr/bin/prettyping ] && alias pping='prettyping'

[ -d "${ESP_IDF_PATH}" ] && alias esp_idf_enable='source ${ESP_IDF_PATH}/export.sh'
