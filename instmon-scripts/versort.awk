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
# versort.awk: Takes a bunch of version numbers from standard input and
# sorts them the UNIX way.
#

function vercmp(verstr1, verstr2)
{
    ncomp1 = split(verstr1, verarr1, "\\.")
    ncomp2 = split(verstr2, verarr2, "\\.")
    if (ncomp1 > ncomp2) ncomp = ncomp1
    else ncomp = ncomp2
    for (j = 1; j <= ncomp; j++) {
	result = verarr2[j] - verarr1[j]
	if (result) return result
	if (verarr2[j] > verarr1[j]) return +1
	if (verarr2[j] < verarr1[j]) return -1
    }
    return 0
}

BEGIN {
    max = 1
}

{
    lines[NR] = $0
    if (vercmp(lines[NR], lines[max]) < 0) max = NR
}

END {
    for (i = 1; i <= NR; i++) {
	min = max
	for (x in lines)
	  if (vercmp(lines[x], lines[min]) > 0) min = x
	print lines[min]
	delete lines[min]
    }
}
