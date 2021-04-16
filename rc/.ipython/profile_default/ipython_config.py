c = get_config()

# `prompt_toolkit` completer choices: ('column', 'multicolumn', 'readlinelike')
c.TerminalInteractiveShell.display_completions = 'readlinelike'

# shortcuts.py:85 binds tab to `display_completions_like_readline`

c.TerminalInteractiveShell.pdb=True
c.IPCompleter.use_jedi=False
