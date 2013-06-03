# Matthew Wang's Bash Profile for general Linux/Unix with a little Y! flavor
#
# Suggestion: ln -sf .bashrc .bash_profile
#

# Source global definitions
[[ ! -f /etc/profile ]] || . /etc/profile
[[ ! -f /etc/bashrc ]] || . /etc/bashrc
[[ ! -f ~/DIRS ]] || . ~/DIRS

# https://raw.github.com/git/git/master/contrib/completion/git-completion.bash
[[ ! -f ~/.git-completion.bash ]] || . ~/.git-completion.bash

# Customized PATH
#
function pathmunge() {
    local x
    for x in "$@"; do
        [[ :$PATH: == *:$x:* ]] || PATH=$x:$PATH
    done
}
pathmunge /bin /usr/bin /sbin /usr/sbin /usr/local/bin /usr/local/sbin ~/bin
[[ ! -d /opt/local/bin ]] || pathmunge /opt/local/bin
[[ ! -d /home/y/bin64 ]] || pathmunge /home/y/bin64
[[ ! -d /home/y/bin ]] || pathmunge /home/y/bin
unset pathmunge
export PATH

function __git_status_color() {
    git symbolic-ref HEAD >& /dev/null || return 0
    if [[ -n $(git status -s 2>/dev/null) ]]; then
        echo -e "\033[1;35m"        # magenta status
    else
        echo -e "\033[1;32m"        # green status
    fi
}

function __git_active_branch() {
    local branch=$(git symbolic-ref HEAD 2>/dev/null)
    [[ -z $branch ]] || echo " (${branch##refs/heads/})"
}

# Tip: start a global ssh-agent for yourself, for example, add this in
# /etc/rc.d/rc.local (RHEL):
#   U=wangyl
#   rm -f /home/$U/.ssh-agent.sock
#   /bin/su -m $U -c "/usr/bin/ssh-agent -s -a /home/$U/.ssh-agent.sock \
#      | sed '/^echo/d' > /home/$U/.ssh-agent.rc"
# You will need to ssh-add your identity manually once
#
_LR="\[\e[1;31m\]"      # light red
_LG="\[\e[1;32m\]"      # light green
_LY="\[\e[1;33m\]"      # light yellow
_LB="\[\e[1;34m\]"      # light blue
_LM="\[\e[1;35m\]"      # light magenta
_LC="\[\e[1;36m\]"      # light cyan
_RR="\[\e[7;31m\]"      # reverse red
_NC="\[\e[0m\]"         # no color

# Fancy PS1, prompt current time, exit status of last command, hostname, yroot,
# time, cwd, git status and branch, also prompt the '$' in red when we have
# background jobs, '\[' and '\]' is to mark ansi colors to allow shell to
# calculate prompt string length correctly
#
PS1="${_LC}\t "
PS1="${PS1}\$([[ \$? == 0 ]] && echo '${_LG}✔' || echo '${_LR}✘') "

if [[ -f ~/.ssh-agent.rc ]]; then
    # I am on my own machine, try load ssh-agent related environments
    PS1="${PS1}${_LB}"                              # blue hostname
    . ~/.ssh-agent.rc
    if ps -p ${SSH_AGENT_PID:-0} >& /dev/null; then
        if ! ssh-add -L | grep -q ^ssh-; then
            echo -e "\033[1;31mWarning: No key is being held by ssh-agent," \
                    "try 'ssh-add <your-ssh-private-key>'\x1b[0m" >&2
        fi
    else
        echo -e "\033[1;31mWarning: No global ssh-agent process alive" >&2
    fi
else
    # Otherwise assume I am on other's box, highlight hostname in red
    PS1="${PS1}${_LR}"                              # red hostname
fi

PS1="${PS1}${HOSTNAME%.yahoo.*}"
PS1="${PS1}${_LG}"                                  # then green {yroot}
PS1="${PS1}"'$([[ -z $YROOT_NAME ]] || echo "{$YROOT_NAME}")'
PS1="${PS1} ${_LY}\w"                               # yellow cwd
PS1="${PS1}\[\$(__git_status_color)\]"              # git status indicator
PS1="${PS1}\$(__git_active_branch)"                 # git branch name
PS1="${PS1}${_LC} ⤾${_NC}\n"                        # cyan wrap char, NL
PS1="${PS1}\$([[ -z \$(jobs) ]] || echo '$_RR')"    # reverse bg job indicator
PS1="${PS1}\\\$${_NC} "                             # $
unset _LR _LG _LY _LB _LM _LC _RR _NC

export PS1
export EDITOR=vim
export TERM=linux
export GREP_OPTIONS="--color=auto"

# Locale matters for ls and sort
# www.gnu.org/software/coreutils/faq/#Sort-does-not-sort-in-normal-order_0021
export LC_COLLATE=C
export LC_CTYPE=C

# Shortcuts (Aliases, function, auto completion etc.)
#
case $(uname -s) in
    Linux)
        alias ls='/bin/ls -F --color=auto'
        alias l='/bin/ls -lF --color=auto'
        alias lsps='ps -ef f | grep -vw grep | grep -i'
        ;;
    Darwin)
        alias ls='/bin/ls -F'
        alias l='/bin/ls -lF'
        alias lsps='ps -ax -o user,pid,ppid,stime,tty,time,command | grep -vw grep | grep -i'
        ;;
    *)
        alias ls='/bin/ls -F'
        alias l='/bin/ls -lF'
        alias lsps='ps -auf | grep -vw grep | grep -i'
        ;;
esac

# Find a file which name matches given pattern (ERE)
function f() {
    local pat=${1?'Usage: f ERE-pattern [path...]'}
    shift
    find ${@:-.} \( -path '*/.svn' -o -path '*/.git' -o -path '*/.idea' \) -prune \
        -prune -o -print | grep -i "$pat"
}

# Load file list generated by function f() above in vim, you can type 'gf' to
# jump to the file
#
function vif() {
    local tmpf=$(mktemp)
    f "$@" > $tmpf && vi -c "/$1" $tmpf && rm -f $tmpf
}

# Grep a pattern (ERE) in files that match given file glob in cwd
function g() {
    local string_pat=${1:?"Usage: g ERE-pattern [file-glob] [grep options]"}
    local file_glob=${2:-"*"}
    shift; [[ -z $1 ]] || shift
    find . \( -path '*/.svn' -o -path '*/.git' -o -path '*/.idea' \) -prune \
        -o -type f -name "$file_glob" -print0 \
        | xargs -0 -n1 -P64 grep -EH "$string_pat" "$@"
}

# Auto complete hostnames for hostname related commands, note 'complete -A
# hostname' also works but it does not recognize new $HOSTFILE
#
function _host_complete()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    local hosts=$( (sed -ne 's/[, ].*//p' ~/.ssh/known_hosts*;
                    awk '!/^#/{print $1}' ~/HOSTS) 2>/dev/null | sort -u)
    COMPREPLY=($(compgen -W "$hosts" -- $cur))
}
complete -F _host_complete ssh scp host nc ping telnet

# Auto complete unset from exported variables
complete -A export unset

# Yroot name auto completion
function _yroot_complete ()
{
    local cur=${COMP_WORDS[COMP_CWORD]};
    local -a yroots=(
        $(cd /home/y/var/yroots && /bin/ls *.conf | sed 's/\.conf$//g')
    )
    COMPREPLY=($(compgen -W '${yroots[@]}' -- $cur ))
}
complete -F _yroot_complete yroot

# Don't tab-expand hidden files
bind 'set match-hidden-files off' >& /dev/null

# vim:set et sts=4 sw=4 ft=sh:
