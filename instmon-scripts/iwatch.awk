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
# iwatch.awk: Produces a list of files from the output of installwatch.
#

{
    if ($1 == -1) next
}

$2 ~ /^(chmod|chown|creat|lchown|mkdir|mknod|open|truncate|utime)$/ {
    files[$3] = 1
}

$2 ~ /^(link|symlink)$/ {
    files[$4] = 1
}

$2 ~ /^(rmdir|unlink)$/ {
    delete files[$3]
}

$2 ~ /^(rename)$/ {
    delete files[$3]
    files[$4] = 1
}

END {
    for (f in files) print f
}
