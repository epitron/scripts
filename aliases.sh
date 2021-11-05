#
# magic cross-platform "open" command
#
# if [ "$OSTYPE" == "cygwin" ]; then
#   alias open='cygstart'
# elif [ -f /usr/bin/xdg-open ]; then
#   alias open='xdg-open "$@" 2>/dev/null'
# elif [ -f /usr/bin/exo-open ]; then
#   alias open='exo-open "$@" 2>/dev/null'
# elif [ -f /usr/bin/gnome-open ]; then
#   alias open='gnome-open "$@" 2>/dev/null'
# fi

# alias open='xdg-open "$@" 2>/dev/null'

function we_have() {
  which "$@" > /dev/null 2>&1
}

function alias_all_as_sudo() {
  for var in "$@"
  do
    alias $var="sudoifnotroot $var"
  done
}

## if CLICOLOR doesn't work, this can hard-wire color-ls
if [ "$TERM" != "dumb" ]; then
  #export LS_OPTIONS='--color=auto'
  if we_have dircolors
  then
    eval `dircolors -b`
  fi
  alias ls="ls --color=auto"
fi

## aliases

alias ll='l'
alias la='l -a'
alias lt='d -lt'
alias lh='ls -lh'
alias lts='d -ls'
alias da='d -a'

if we_have exa
then
  alias l='exa -ag --long --header'
  alias ls='exa'

  function t() {
    exa --long --header --tree --color=always "$@" | less -SRXFi
  }
else
  alias l='ls -al'
  function t() {
    tree -Ca $* | less -SRXFi
  }
fi

# function fd() {
#  query="$@"
#  $(which fd) --color=always "$query" | less -RS "+/$query"
#}

#if which fd > /dev/null; then
#  alias f='fd -IH'
#fi

# cd
alias up='cd ..'
alias back='cd "$OLDPWD"'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
# alias +='pushd .'
# alias -- -='popd'

mkcd() {
  if [ ! -d "$@" ]; then
    mkdir -p "$@"
  fi
  cd "$@"
}

pushpath() {
  if [ "$1" == "" ]; then
    dir="$PWD"
  else
    dir="`readlink -m "$1"`"
  fi

  export PATH="$dir":$PATH
  echo "'$dir' added to path."
}

# filesystem
alias mv="mv -v"
alias mv-backup='mv --backup=numbered'
alias cp="cp -v"
alias rm='trsh'
alias r='ren'
alias rehash='hash -r'
alias cx='chmod +x'
alias c-x='chmod -x'
alias cls='clear'

# text
if ! we_have nano && we_have pico; then
  alias nano="pico -w"
else
  alias nano="nano -w"
fi

alias n=nano
alias s.='s .'
alias c.='c .'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias rcat='tac'

rgrep() {
  expression=$1
  shift

  rcat "$@" | grep -Ei $expression
}

pager='less -RSFXi'
if we_have rg
then
  rg() {
    `which rg` --pretty "$@" | $pager
  }
  #alias ag="rg"
fi

if we_have ag
then
  alias ag="ag --smart-case --pager '$pager'"
else
  alias ag="ack --pager '$pager'"
fi

alias less='less -X -F -i'
alias diff='diff -u --color'

if we_have scc; then
  alias cloc='scc'
fi

# media
alias o="open"
alias o.="open ."
alias a="audacious"
alias ae="a -e"
alias a2="a"
alias ch="chromium"
#alias mp="ncmpcpp"
alias yd='youtube-dl --xattrs --no-mtime'

if we_have ueberzug; then
  alias ytf='ytfzf -t --detach'
else
  alias ytf='ytfzf --detach'
fi

# net
alias_all_as_sudo iptables netctl ufw dhcpcd nethogs
alias ssh='ssh -2'
alias scpfast='scp -c arcfour128'
alias sshfast='ssh -c arcfour128'
alias mosh='msh'
alias whois='whois -H'
alias geoip='geoiplookup'
alias geoip6='geoiplookup6'
alias iptraf='sudoifnotroot iptraf-ng'
alias ip6='ip -6'

# disks
alias_all_as_sudo fdisk blkid
alias fatrace="sudoifnotroot fatrace | grep -v xfce4-terminal"
alias md='mdadm'

alias df='df -h'
alias df.='df .'
alias screen='screen -U'

alias e.='e .'

if we_have dcfldd; then
  alias dd='dcfldd'
elif we_have ddrescue; then
  alias dd='ddrescue'
fi

alias um='unmount'

alias lsmnt='findmnt'
alias lsblk='lsblk -o MODEL,SIZE,TYPE,NAME,MOUNTPOINT,LABEL,FSTYPE'
alias disks='lsblk'

# system
alias_all_as_sudo sysdig swapped perf
alias dmesg='dmesg -T --color=always|less -S -R +\>'
alias dmesg-tail='\dmesg -T --color -w'
alias dstat-wide='dstat -tcyifd'
#alias off='sudoifnotroot shutdown -h now || sudoifnotroot systemctl poweroff'
#alias reboot='sudoifnotroot shutdown -r now || sudoifnotroot systemctl reboot'
#alias reboot='sudoifnotroot systemctl reboot'
alias sus='ssu'

# systemd
# alias_all_as_sudo systemctl journalctl
alias jc='journalctl'
alias jt='journalctl -f'
alias sys='systemctl'
alias j='journalctl'
alias iu='i --user'
alias suspend='systemctl suspend -i'

# misc
alias dict='dictless'
alias wh="$(which w 2> /dev/null)"
alias w='wict'
alias chrome='google-chrome'
alias dmenu="dmenu -l 50"
alias resett="tput reset"
alias xmem='xrestop'
alias flash='crutziplayer'
alias rdp='xfreerdp'
alias gource='gource --user-image-dir ~/.cache/gravatars'
alias psx='pcsxr'
alias detach='bg; disown'
alias dpkg='sudoifnotroot dpkg'
alias record-desktop="simplescreenrecorder"
alias b='chromium'
alias columns='cols'

# archives
alias ax="aunpack"
alias ac="apack"
alias al="als"

# git
alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias glu="gl -u"
alias gch="git checkout"
# alias g[[="git stash"
# alias g]]="git stash pop"
# alias g[]="git stash list; git stash show"
alias g+="git add"
alias gr="git remote -v"
alias gf="git fetch --all -v --prune"
alias fetch="gf"
alias whose-line-is-it-anyway="git blame"

# functions
functions() {
  declare -f | less
}

# alias gc="git clone"
gc() {
  # Cloning into 'reponame'...
  if $(which gc) "$@"; then
    cd "$(\ls -tr | tail -n1)"
  else
    echo "clone failed"
  fi
}

aur() {
  if [ ! -d ~/aur ]; then mkdir ~/aur; fi
  cd ~/aur
  if [ -d "$@" ]; then
    echo "* $@ already downloaded. updating..."
    cd "$@"
    git pull
  else
    aur-get "$@"
    if [ -d "$@" ]; then
      cd "$@"
      c PKGBUILD
    else
      echo "something went wrong?"
    fi
  fi
}

kill-bg-jobs() {
  jobs=`jobs -ps`
  if [ "$jobs" == "" ]; then
    echo "Couldn't find any running background jobs"
  else
    echo "killing jobs: $jobs"
    kill -9 $jobs
  fi
}
alias gcs="gc --depth=1"

# scripting languagey things
alias be="bundle exec"
alias rock='luarocks'
alias gi='gem install'

alias pip='python -m pip'
alias pi='pip install --user'

#alias pi2='pip2 install --user'
#alias pi3='pip3 install --user'

alias piu='pip uninstall'
alias py=python
alias ipy=ipython
alias ipy3=ipython3
alias ipy2=ipython2
alias ni='npm install'


gem-cd() {
  local gem_dir

  if gem_dir="`gem-dir $@`"; then
    cd "$gem_dir"
  fi
}

pip-cd() {
  for dir in `\ls -1rd ~/.local/lib/python*/site-packages/` `\ls -1rd /usr/lib/python*/site-packages/`; do
    if [ -d $dir/$1 ]; then
      cd $dir/$1
      break
    fi
  done
}
alias pycd=pip-cd

# # 64/32bit specific aliases
# case `uname -m` in
#   x86_64)
#     ;;
#   *)
#     ;;
# esac

# Things with literal arguments!
#alias math='noglob math'
#alias gfv='noglob gfv'

# upm
alias u=upm
alias uu='upm update'
alias up='upm upgrade'
alias ui='upm install'
alias ur='upm remove'
alias uf='upm files'
alias ul='upm list'
alias us='upm search'


# arch
alias pacman='sudoifnotroot /usr/bin/pacman'
# alias pacs='\pacman -Ss'   # search for package
alias pacf='\pacman -Ql|grep' # which package contains this file?
alias pacq='\pacman -Q|grep'  # find a package
alias pacg='\pacman -Qg'   # show groups
alias pacu='pacman -Syu'  # update packages
alias pacd='pacman -Syuw' # only download updates (no install)
alias pacr='pacman -Rs --'   # remove package (and unneeded dependencies)
alias pacrf='pacman -Rc'  # remove package (and force removal of dependencies)
alias pacpurge='pacman -Rns' # purge a package and all config files
alias pacuproot='pacman -Rsc' # remove package, dependencies, and dependants
alias abs='sudoifnotroot abs'
# alias pkgfile='sudoifnotroot pkgfile -r'

if we_have yaourt; then
  alias y='yaourt'
else
  alias y='aurs'
fi

# npm
# alias ni="sudoifnotroot npm install -g"
# alias nl="npm list -g --color=always |& less -S"

#
# Usage:
#   faketty <command> <args>
#
# (Almost works... There's just a newline issue)
#
#function faketty { script -qfc "$(printf "%q " "$@")"; }
shiftpath() { [ -d "$1" ] && PATH="${PATH}${PATH:+:}${1}"; }
alias psh=pwsh
