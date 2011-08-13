#!/bin/bash
if [ "$TERM" == "xterm" -a "$COLORTERM" != "gnome-terminal" ]; then
   export PROMPT_COMMAND='echo -ne "\033]30;[`basename "$PWD"`]\007"'
fi

export PS1="\\[\e[30m\e[1m\\][\\[\e[0m\e[37m\\]\\@\\[\e[0m\e[30m\e[1m\\]] \\[\e[0m\e[31m\\]\\u\\[\e[0m\e[30m\e[1m\\]@\\[\e[0m\e[31m\e[1m\\]\\h \\[\e[0m\e[30m\e[1m\\]:: \\[\e[0m\e[37m\e[1m\\]\\w \\[\e[0m\e[37m\\]$ \\[\e[0m\\]"
