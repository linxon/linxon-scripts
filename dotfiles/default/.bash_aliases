## Команда - exit (можно использовать соч. клавиш Ctrl+D)
# в gentoo есть q-applets
[ -x /usr/bin/q ] || alias q='exit' && alias quit='exit'
[ -x /usr/bin/percol ] && alias pcol='/usr/bin/percol'

## Запускаем xfce с поддержкой polkit
[ -x /usr/bin/startxfce4 ] && { 
	alias startx='/usr/bin/startxfce4 --with-ck-launch'
	alias startxfce4='/usr/bin/startxfce4 --with-ck-launch' 
}

## Команда — clear
alias c='clear'

## Команда — pw
alias p='pwd'

# Команда к хелперу pcopy()
alias pc='pcopy'
alias pwdc='pcopy'

## Команда — cat
[ -x /usr/bin/ccat ] && alias cat='ccat'

## Упрощение основных программ мониторинга
alias wdu='watch -n 1 du -sh'
alias wfree='watch -n 1 free'
alias wdf='watch -n 1 "df -h"'
[ -x /opt/bin/yandex-disk ] && alias wyadisk='watch -n1 yandex-disk status'
[ -x /usr/bin/sensors ] && alias sensors='watch -n 1 sensors'
[ -x /usr/bin/youtube-dl ] && {
	alias youtF="youtube-dl -F"
	alias youtf="youtube-dl -f"
}

alias w="w -i"
alias lsusb='watch -n 1 lsusb'
alias cal='cal -Y'
alias ifind_here="find ./ -type f -iname"
alias pbin='nc pastebin.linxon.ru 9999 | xclip -selection "clipboard" && notify-send --urgency=low -i "$([ $? = 0 ] && echo text-x-script)" "Сервер: pastebin.linxon.ru" "Ссылка была скопирована в буфер обмена..."'
alias clfile='cat /dev/null >'
alias mapscii='telnet mapscii.me'
[ -x /usr/bin/vim ] && alias vimlast='vim $(ls -t | head -1)'

alias cdw='cd -P /tmp/linxon-tmp-files'
alias cdg='cd -P ~/GitClones'
alias cdcloud='cd -P /media/Xlam/Cloud/'
alias cpuz='watch -n1 "cat /proc/cpuinfo | grep -e \"core id\" -e \"cpu MHz\""'
[ -d "/run/media/${USER}" ] && alias cdm='cd /run/media/${USER}'
[ -d "/etc/portage" ] && alias cdp='cd /etc/portage'
[ -x /usr/bin/ebuildtester ] && alias ebuildtester='ebuildtester \
	--threads $(($(nproc)+1)) \
	--portage-dir $(portageq get_repo_path / gentoo) \
	--ccache-dir $(portageq envvar CCACHE_DIR) \
	--shell-env "USE=$(portageq envvar USE)" \
	--shell-env "CFLAGS=$(portageq envvar CFLAGS)" \
	--shell-env "CXXFLAGS=$(portageq envvar CXXFLAGS)" \
	--shell-env "CPU_FLAGS_X86=$(portageq envvar CPU_FLAGS_X86)" \
	--shell-env "LLVM_TARGETS=$(portageq envvar LLVM_TARGETS)" \
	--shell-env "VIDEO_CARDS=nouveau"'

