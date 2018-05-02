## FISH

function blah
  echo $argv
end


begin; [COMMANDS...] end


if CONDITION
   COMMANDS_TRUE...
[else
  COMMANDS_FALSE...]
end

if CONDITION; COMMANDS_TRUE...; [else; COMMANDS_FALSE...;] end


while CONDITION; COMMANDS...; end

for VARNAME in [VALUES...]; COMMANDS...; end

switch VALUE; [case [WILDCARD...]; [COMMANDS...]; ...] end

Description

