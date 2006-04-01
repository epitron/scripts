#!/usr/bin/awk -f
#
# instmon - INSTall MONitor - an installation monitoring tool
# Copyright (C) 1998-1999 Vasilis Vasaitis (vvas@hal.csd.auth.gr)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# strace.awk: Produces a list of files from the output of strace.
#

function abspath(path)
{
    if (path ~ /^\//) return path
    else return dirs[$1] "/" path
}

BEGIN {
    FS="[(),=\" \t]+"
    result["creat"]    = 5
    result["link"]     = 5
    result["symlink"]  = 5
    result["mkdir"]    = 5
    result["chmod"]    = 5
    result["chown"]    = 6
    result["truncate"] = 5
    result["utime"]    = 5
    fname["creat"]     = 3
    fname["link"]      = 4
    fname["symlink"]   = 4
    fname["mkdir"]     = 3
    fname["chmod"]     = 3
    fname["chown"]     = 3
    fname["truncate"]  = 3
    fname["utime"]     = 3
    origdir = ARGV[1]
    delete ARGV[1]
}

{
    if (!($1 in dirs)) dirs[$1] = origdir
}

$2 == "chdir" {
    if ($4 == -1) next
    dirs[$1] = abspath($3)
}

$2 == "fork" {
    if ($3 <= 0) next
    dirs[$3] = dirs[$1]
}

$2 == "open" {
    if ($4 ~ /O_CREAT/) res = 6
    else res = 5
    if ($res == -1) next
    if ($4 ~ /O_RDONLY|O_RDWR/) next
    files[abspath($3)] = 1
}

$2 == "mknod" {
    if ($4 ~ /S_IFCHR|S_IFBLK/) res = 8
    else res = 5
    if ($res == -1) next
    files[abspath($3)] = 1
}

$2 ~ /^(creat|link|symlink|mkdir|chmod|chown|truncate|utime)$/ {
    if ($result[$2] == -1) next
    files[abspath($fname[$2])] = 1
}

$2 == "unlink" || $2 == "rmdir" {
    if ($4 == -1) next
    delete files[abspath($3)]
}

$2 == "rename" {
    if ($5 == -1) next
    delete files[abspath($3)]
    files[abspath($4)] = 1
}

END {
    for (f in files) print f
}
