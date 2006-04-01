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
# listlogs.awk: Takes ls -lg and transforms it to a nice package listing.
#

BEGIN {
    printf "%-20s%-20s%-20s%s\n", "Name", "Version", "Date", "User"
    printf "%-20s%-20s%-20s%s\n", "----", "-------", "----", "----"
}

{
    if (NR == 1) next
    sub(/^instlog\./, "", $9)
    sub(/-[0-9]/, " &", $9)
    split($9, pkg, " -")
    printf "%-19s %-19s %-4s%3s%7s      %s\n", pkg[1], pkg[2], $6, $7, $8, $3
}
