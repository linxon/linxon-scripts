####################################################################
## Автор: Yury Martunov (http://www.linxon.ru)
## E-mail: email@linxon.ru
## ICQ: 616015333
## Telegram: https://t.me/linxon
####################################################################

# /etc/skel/.bashrc
#
# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# Put your fun stuff here.

[ "$(/usr/bin/id -u)" != "0" ] || IS_ROOT=1

## Не вставлять повторяющиеся строки (команды) в файл истории
## Смотри bash(1) для конфигурации
HISTCONTROL="&:ls:[bf]g:exit"

## Настройки для записи истории команд HISTSIZE и HISTFILESIZE в bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

## Добавить в конец файла истории ипользуемую команду (не перезаписывая)
shopt -s histappend

## Проверять размер окна после каждой команды (при необходимости) Обновить значения строк и столбцов
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

## Автоматически исправлять отрф. ошибки каталогов
shopt -s cdspell dirspell

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
	xterm-color) color_prompt=yes;;
esac

## ANSI коды цветов
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

## Раскоментировать, для принудительной поддержки цветовой схемы в терминале (если не сработает)
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		# We have color support; assume it's compliant with Ecma-48
		# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
		# a case would tend to support setf rather than setaf.)
		color_prompt=yes
	else
		color_prompt=
	fi
fi

if [ "$color_prompt" = yes ]; then
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	##$HC$FGRN•
	if [ "${USER}" == 'root' ]; then
		PS1="$RS\[\e]0;\u@\h:[ \W ]\a\]$HC$FRED\h$RS$HC$FBLE:$HC$FYEL\w $FRED\\$ $RS"
	else
		if ! [ -z "${SSH_CLIENT}" ]; then
			## Режим сервера
			PS1="$RS\[\e]0;\u@\h:[ \W ]\a\]$HC$FBLE$UL\u$RS$HC$FBLE@$FGRN\h$RS$HC$FBLE: $HC$FYEL\w $FRED\\$ $RS"
		elif [[ "${TERM,,}" == 'xterm' ]]; then
			## Пользовательский режим (xterm) (•­ — обозначает ПР)
			PS1="$RS\[\e]0;\u@\h:[ \W ]\a\]$HC$FBLE$UL\u$RS$HC$FBLE@\h$RS$HC$FBLE:$HC$FYEL\w $FRED\\$ $RS"
		elif [[ "${TERM,,}" == 'linux' ]]; then
			## Пользовательский режим (tty*) (•­ — обозначает ПР)
			PS1="$RS\[\e]0;\u@\h:[ \W ]\a\]$HC­$FBLE$UL\u$RS$HC$FBLE@\h$RS$HC$FBLE:$HC$FYEL\W $FRED\\$ $RS"
		fi
	fi
	PS2="$FMAG>>> $RS"
fi
unset color_prompt force_color_prompt

## Автоматический заупуск оболочки XFCE после авторизации в tty* (Зачем нам нужны всякие slim или lightdm?)
if [ "${TERM}" != dumb ] && [[ -x /usr/bin/startxfce4 && "${IS_ROOT}" != "1" ]]; then
	if [[ $(tty) == "/dev/tty1" && ! ${DISPLAY} ]]; then
		C_COUNT=0
		M_COUNT=3
		CANCEL_STAT=0

		echo -e "\033[32mЗапуск команды: \033[4m/usr/bin/startxfce4 --with-ck-launch\033[0m\033[32m"
		echo -en "\033[32mНажмите Ctrl+C для отмены\033[31m"

		trap 'CANCEL_STAT=1' SIGINT

		while true; do
			[ ${CANCEL_STAT} -eq 1 ] && {
				echo -e "\n"
				break
			}
			if [[ ${C_COUNT} != ${M_COUNT} ]]; then
				sleep 1 && echo -n "."
				C_COUNT=$(($C_COUNT + 1))
			else
				echo -en "\033[0m" && sleep 1
				/usr/bin/startxfce4 --with-ck-launch > /dev/null 2>&1 &

				break
			fi
		done
	fi
fi

if [ "$TERM" != dumb ]; then
	[ -x /usr/bin/dircolors ] && {
		test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
		alias ls='ls --color=auto'
		alias dir='dir --color=auto'
		alias vdir='vdir --color=auto'

		alias grep='grep --color=auto'
		alias fgrep='fgrep --color=auto'
		alias egrep='egrep --color=auto'
	}

	alias cdl='cd "$1" && ls -l'
	alias cdll='cd "$1" && ls -alF'
	alias ..='cd ..'
	alias ...='cd ../..'
	alias ....='cd ../../..'
	alias .....='cd ../../../..'
	alias ......='cd ../../../../..'
	alias .......='cd ../../../../../..'
	alias ........='cd ../../../../../../..'
#	alias .........='cd ../../../../../../../..'

	alias l='ls -CF'
	alias ll='ls -lh'
	alias lss='ls -lZ'
	alias lll='ls -alFh'
	alias llll='ls -aliFh'
	alias la='ls -A'
	alias lt='ls -lth'
	alias lu='ls -luh'
	alias li='ls -lih'
	alias llr='ls -lhR'
	alias hh='history'

	[ -x /usr/bin/equery ] && {
		alias eqf='/usr/bin/equery f'
		alias equ='/usr/bin/equery u'
		alias eqh='/usr/bin/equery h'
		alias eqa='/usr/bin/equery a'
		alias eqb='/usr/bin/equery b'
		alias eql='/usr/bin/equery l'
		alias eqd='/usr/bin/equery d'
		alias eqg='/usr/bin/equery g'
		alias eqc='/usr/bin/equery c'
		alias eqk='/usr/bin/equery k'
		alias eqm='/usr/bin/equery m'
		alias eqy='/usr/bin/equery y'
		alias eqs='/usr/bin/equery s'
		alias eqw='/usr/bin/equery w'
	}

	## Цветова схема для системных утилит (требуется пакет - grc последней версии)
	[ -x /usr/bin/grc ] && {
		alias cl='/usr/bin/grc -es --colour=auto'

#		alias configure='cl ./configure'
		alias ps='cl ps'
		alias ping='cl ping'

		[ -x /usr/bin/diff ] && alias diff='cl diff'
#		[ -x /usr/bin/make ] && alias make='cl make'
		[ -x /usr/bin/gcc ] && alias gcc='cl gcc'
		[ -x /usr/bin/g++ ] && alias g++='cl g++'
		[ -x /usr/bin/as ] && alias as='cl as'
		[ -x /usr/bin/dig ] && alias dig='cl dig'
		[ -x /bin/ifconfig ] && alias ifconfig='cl ifconfig'
		[ -x /usr/bin/gas ] && alias gas='cl gas'
		[ -x /usr/bin/ld ] && alias ld='cl ld'
		[ -x /bin/netstat ] && alias netstat='cl netstat'
		[ -x /usr/bin/traceroute ] && alias traceroute='cl traceroute'
		[ -x /usr/bin/last ] && alias last='cl last'
		[ -x /bin/mount ] && alias mount='cl mount'
		[ -x /usr/bin/nmap ] && alias nmap='cl nmap'
		[ -x /usr/bin/stat ] && alias stat='cl stat'
		[ -x /bin/findmnt ] && alias findmnt='cl findmnt'
		[ -x /bin/df ] && alias df='cl df -h'
		[ -x /usr/bin/du ] && alias du='cl du -sh'
		[ -x /bin/ip ] && alias ip='cl ip'
		[ -x /bin/lsblk ] && alias lsblk='cl lsblk'
		[ -x /usr/bin/lsof ] && alias lsof='cl lsof'
		[ -x /usr/bin/id ] && alias id='cl id'
		[ -x /bin/lsmod ] && alias lsmod='cl lsmod'
		[ -x /usr/bin/vmstat ] && alias vmstat='cl vmstat'
		[ -x /usr/bin/uptime ] && alias uptime='cl uptime'
		[ -x /usr/sbin/lspci ] && alias lspci='cl lspci'
		[ -x /sbin/ss ] && alias ss='cl ss'
		[ -x /usr/bin/free ] && alias free='cl free -h'
	}

	[ -x /usr/bin/tailf ] || alias tailf="tail -f"
	[ -x /usr/bin/euses ] && alias euses='/usr/bin/euses -cv'
	[ -x /usr/bin/wget ] && alias wget='wget -c'
	[ -x /usr/bin/htop ] && {
		alias oldtop='/usr/bin/top'
		alias top='htop'
	}
	[ -x /usr/bin/gio ] && alias cdgvfs='cd /run/user/${UID}/gvfs'
	[ -x /usr/bin/ncdu ] && alias ncdu='ncdu --color=dark'
fi

## Упрощаем работу с tripwire (требуется привелегии root)
if [[  "$TERM" != dumb && -x /usr/sbin/tripwire && -d /var/lib/tripwire/report && ${IS_ROOT} ]]; then
	alias last.tw.report='echo $(ls -t /var/lib/tripwire/report/* | head -1)'
	alias tw.report='twprint  --print-report -r `last.tw.report`'
	alias tw.update='tripwire --update -r `last.tw.report`'
fi

## Подключаем пользовательские скрипты, команды
if [ "$TERM" != dumb ] && [ -f ~/.bash_helpers ]; then
	source ~/.bash_helpers
fi

## Подключение остальных пользовательских алиасов
if [ "$TERM" != dumb ] && [ -f ~/.bash_aliases ]; then
	source ~/.bash_aliases
fi

## Включить программируемое атозаполнение
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		source /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		source /etc/bash_completion
	fi
fi

###########################
## Прочее...
###########################
## PHPBREW Requirement
#[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

## distcc - рабочий каталог (необходим для компиляции пользователем)
if [ -x /usr/bin/distccd ]; then
	[ -d /var/tmp/portage/.distcc ] && export DISTCC_DIR="/var/tmp/portage/.distcc/"
fi

## Локальные файлы пользователи для запуска
LOC_BIN_PATH="${HOME}/.local/bin"
if [ -d ${LOC_BIN_PATH} ]; then
	export PATH="${LOC_BIN_PATH}:${PATH}"
else
	mkdir -p ${LOC_BIN_PATH} && export PATH="${LOC_BIN_PATH}:${PATH}"
fi

## Локальные страницы помощи
# MANDIR_PATH="${HOME}/.local/share/man"
# if [ -d "${MANDIR_PATH}" ]; then
# 	export MANPATH="${MANPATH}:${MANDIR_PATH}"
# else
# 	mkdir -p "${MANDIR_PATH}" && export MANPATH="${MANPATH}:${MANDIR_PATH}"
# fi

## Поддержка переключения сторонних языков (напр. Японский)
#if [ -x /usr/bin/ibus ] && [ "${TERM,,}" == 'xterm' ]; then 
#	export GTK_IM_MODULE=ibus
#	export XMODIFIERS=@im=ibus
#	export QT_IM_MODULES=ibus
#fi

if [ -n "$DISPLAY" ]; then
  xset b off # disable pc-speaker
  xset s off && xset -dpms # disable turnoff screen
fi

if [ -f /usr/libexec/mc/mc.sh ]; then
	source /usr/libexec/mc/mc.sh
fi

# Устанавливаем лимит на вывод для eix -p ...
if [ -x /usr/bin/eix ]; then
	export EIX_LIMIT=0
fi

