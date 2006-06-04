----------------------------------------------------------------
                                           What is this stuff?
================================================================

Lots of cool scripts!


=[ Debian Scripts ]=============================================

acs           | apt show (display package info)
agd           | apt download (downloads all new packages but doesn't install them)
agdu          | apt dist-upgrade (install new packages)
agi           | apt install (download + install a package)
agr           | apt remove (uninstall a package)
ags           | apt search (search package names and descriptions)
agu           | apt update (get updated list of packages from package repositories)
agud          | apt update + apt download (get new package list + download new packages)
apt-build     | apt build a source package
dl            | dpkg list (display installed debian packages)
ds            | dpkg search (search list of installed packages)
purge-configs | delete the config files from all uninstalled debian packages


=[ InstallWatch Package Tools  ]================================

(Note: If you want these scripts to run really fast, make sure
       that 'installwatch' or 'checkinstall' are installed on your
       system.)

inst          | runs "make install" (or "python setup.py install" or "ruby setup.rb install") in the current directory and monitors all the files that get installed, then records all the installed files in a file in /usr/share/instmon. the package is named after the current directory.
instbackup    | compresses all this package's files into a tarball and removes the package
instfind      | search the list of installed packages
instl         | list installed packages
instlist      | list the files in an installed package
instmon       | puts you into a shell that monitors any changes you make to the filesystem. when you type "exit", it saves the changes to the package list.
instremove    | remove an installed package


=[ Useful UNIX Time-Savers ]====================================

ks            | kill-search (Usage: ks [kill SIGNAL] [grep pattern]) -> prompts you to kill all processes that match the supplied search pattern (using the optional signal)
psfind        | Usage: psfind [grep pattern] -> search all running processes
f             | Usage: find [search pattern] [paths to search] -> recursively find all files in the specified directories, or the current directory if unspecified
ddu           | directory disk-usage (same as du --max-depth=1 -m)
i             | init.d daemon controller (runs /etc/init.d/[param] [command]) eg: "i apache2" runs /etc/init.d/apache2 restart, "i gdm stop" kills gdm, etc.
arf           | Archive Retrieval Fiend (extract any kind of archive (tarball, zip, rar) from the filesystem or from an URL)
build         | run "./configure ; make" in the current directory, optionally using the "buildconfig" file in the current directory to pass parameters to configure and make. (See the parameters that the script displays when you run it if you want to know what you can set.)
tounix        | convert a text file (or directory of text files) with DOS line endings to Unix (optionally, replace tabs with a specified number of spaces)
cu            | run "cvs (or svn) update" on the current directory
log           | display the logfile for some program, piped to colorize and less.
count         | display the number of lines of each file in a directory tree (shows both total lines and non-blank lines)

=[ Other Things ]===============================================

j             | loads a file in an already-open jedit editor
n             | open a file in nedit (using the same nedit process as all other instances)
bashrc.leet   | my custom bashrc file
underscorize  | convert all spaces in filenames to underscores
timesync      | synch the system's hardware clock with time.nist.gov
rsync-dirs    | rsync two locations (using size and CRC to determine the differences)
blockip       | create an iptables rule to block the passed ip
dictless      | dict piped to a less command that only scrolls if the output is more than a screen
green         | a pretty green bash prompt
imageshuffle  | runs gthumb on a random selection of images in a directory tree
kb            | kernel build (make dep && make bzImage && make modules && make modules_install)
makepatch     | diff two files and output a mailinglist-submittable diff file
mountiso      | mount an iso to a directory
printcode     | fancy options to printing your code using trueprint
prompt        | nice prompt
purple        | purple bash prompt
rmzeros       | remove all 0-byte files in a directory
rubyxterm     | runs a ruby script in an xterm with a nice font
runrxvt       | spawns an rxvt with a nice font
runxterm      | spawns an xterm with a nice font
unscramble    | given a word, find all permutations of it (good for cheating at scrabble)
urldecode     | convert a string with URL escape codes (eg %20) to a regular string
wi            | do a "whois" lookup on a domain without all the spam, piped to less
asf2mp3       | convert an asf to an mp3 via lame
asfrecorder   | 
ed2k_hash     | generate an edonkey-2k hash of a file
charmap       | displays the ascii table
compyle       | runs "python -c" on all files in a directory tree
