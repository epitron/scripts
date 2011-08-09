#!/usr/bin/perl

##############################################################################
#			           TRSH 3.x                                  #
##############################################################################

##############################################################################
# Copyright 2008-2010 Amithash Prasad                                        *
#									     *
# this file is part of trsh.						     *
#                                                                            *
# trsh is free software: you can redistribute it and/or modify               *
# it under the terms of the GNU General Public License as published by       *
# the Free Software Foundation, either version 3 of the License, or          *
# (at your option) any later version.                                        *
#                                                                            *
# This program is distributed in the hope that it will be useful,            *
# but WITHOUT ANY WARRANTY; without even the implied warranty of             *
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
# GNU General Public License for more details.                               *
#                                                                            *
# You should have received a copy of the GNU General Public License          *
# along with this program.  If not, see <http://www.gnu.org/licenses/>.      *
##############################################################################

##############################################################################
#			     Notes On Style                                  #
# 1. Global variables and function - FirstLetterCaps                         #
# 2. Local variables               - all_low_case_with_undercore             #
# 3. Parameters                    - OptionOptionName                        #
#                                                                            #
# 4. All Functions must be typed and declared.                               #
##############################################################################
use strict;
use warnings;
use File::Basename;
use File::Spec;
use Cwd 'abs_path'; 
use Getopt::Long;
use Fcntl;
use Term::ANSIColor;
use Term::ReadKey;

my $VERSION = "3.13-3";

##############################################################################
#			   Function Declarations                             #
##############################################################################

sub SetEnvirnment();
sub InHome($);
sub InDevice($);
sub GetDeviceList();
sub AbsolutePath($);
sub GetTrashDir($);
sub ListTrashContents();
sub GetTrashinfoPath($);
sub PrintTrashinfo($);
sub Usage();
sub Version();
sub DeleteFile($);
sub EmptyTrash();
sub RemoveFromTrash($);
sub UndoLatestFiles();
sub UndoFile($);
sub GetUserPermission($);
sub FileTypeColor($);
sub SysMove($$);
sub SysMkdir($);
sub SysDelete($$);
sub RemoveFromTrashRegex($);
sub DeleteRegex($);
sub UndoRegex($);
sub HumanReadableSize($);
sub DirSize($);
sub FileSize($);
sub EntrySize($);
sub PrintTrashSize();
sub ListRegexTrashContents($);
sub Crop($$);
sub PrintTrashSizeLine($$);
sub PrintColored($$);
sub HumanReadableDate($);
sub SplitDate($);
sub SetWidths($);
sub GetTrashSize($);
sub MakeTrashDir($);
sub UpdateSizeMetadata($);
sub GetSizeMetadata($);
sub GetLatestMatchingFile($);
sub GetRegexMatchingFiles($);
sub GetLatestDeleted();
sub GetTrashContents();
sub GetSpecificTrashContents($);
sub ListArrayContents($);
sub SizeColor($);
sub GetTrashinfo($);
sub PutTrashinfo($);
sub GetInfoName($$);
sub RemoveTrashinfo($);
sub UndoTrashinfo($);
sub GetDeviceTrash($);
sub PrintColored($$);
sub InitFileTypeColors();
sub FileTypeString($);
sub PrepareRegex($);
sub DiffDate($$);
sub Date2Days($);
sub Year2Days($);
sub Df();
sub DebugDump();
# sub Glob(...); Takes infinite arguments;

##############################################################################
#				Global Variables                             #
##############################################################################

# Parameters
my $OptionEmpty		= 0;
my $OptionList		= 0;
my $OptionForce		= 0;
my $OptionUndo		= 0;
my $OptionSize		= 0;
my $OptionHelp		= 0;
my $OptionInteractive	= 0;
my $OptionVerbose	= 0;
my $OptionRecursive	= 0;
my $OptionColor		= 1;
my $OptionDate		= 1;
my $OptionHumanReadable = 0;
my $OptionRegex		= 0;
my $OptionVersion	= 0;
my $OptionPermanent	= 0;
my $OptionRelativeDate	= 1;
my $OptionDebug         = 0;

# Session information
my %Session = (
	'UserName'	=>	"",
	'UserID'	=>	"",
	'HomePath'	=>	"",
	'HomeTrash'	=>	"",
	'CurrentDate'	=>	"",
	'ListNameWidth'	=>	0,
	'ListDateWidth'	=>	0,
	'ListSizeWidth'	=>	0,
	'ListPathWidth'	=>	0,
	'SSizeWidth'	=>	0,
	'SDevWidth'	=>	0,
	'TypeColors'	=>	{},
	'AttrColors'	=>	{},
);

my $ListNameWidth;
my $ListDateWidth;
my $ListSizeWidth;
my $ListPathWidth;
my $SSizeWidth;
my $SDevWidth;
my %TypeColors;
my %AttrColors;
my %SystemDevices;

# Constants 
my $ListNameWidthPerc = 25;
my $ListDateWidthPerc = 25;
my $ListSizeWidthPerc = 10;
my $ListPathWidthPerc = 40;
my $SSizeWidthPerc    = 20;
my $SDevWidthPerc     = 80;

##############################################################################
#				   MAIN		                             #
##############################################################################

SetEnvirnment();

if($OptionHelp > 0) {
	Usage();
}

if($OptionVersion > 0) {
	Version();
}

if($OptionDebug > 0) {
	DebugDump()
}

# List specific files
if($OptionList > 0 and $OptionRegex > 0 and scalar(@ARGV) > 0) {
	foreach my $reg (@ARGV) {
		ListRegexTrashContents($reg);
	}
	exit;
}

if($OptionList > 0) {
	ListTrashContents();
	exit;
}

# Empty trash
if($OptionEmpty > 0 and scalar(@ARGV) == 0) {
	EmptyTrash();
	exit;
}

# Remove specific files from trash
if($OptionEmpty > 0) {
	foreach my $file (@ARGV) {
		if($OptionRegex == 1) {
			RemoveFromTrashRegex($file);
			next;
		}
		RemoveFromTrash($file);
	}
	exit;
}

# Undo Latest file.
if($OptionUndo > 0 and scalar(@ARGV) == 0) {
	UndoLatestFiles();
	exit;
}

# Undo specific files
if($OptionUndo > 0) {
	foreach my $file (@ARGV) {
		if($OptionRegex == 1) {
			UndoRegex($file);
			next;
		}
		UndoFile($file);
	}
	exit;
}

# Trash size
if($OptionSize > 0) {
	PrintTrashSize();
	exit;
}

# Error Condition: no arguments
if(scalar(@ARGV) == 0) {
	print "$0 (Aliased to rm): missing operand\n";
	print "Try `$0 (Or rm) --help' for more information.\n";
	exit;
}

# Delete files
foreach my $file (@ARGV) {
	if($OptionRegex == 1) {
		DeleteRegex($file);
		next;
	}
	DeleteFile($file);
}

##############################################################################
#		             Trash Functions                                 #
##############################################################################

##############################################################################
#		                Undo delete                                  #
##############################################################################

sub UndoLatestFiles()
{
	my @list = GetLatestDeleted();

	foreach my $entry (@list) {
		UndoTrashinfo($entry);
	}
}

sub UndoFile($)
{
	my $file	=	shift;
	my $entry = GetLatestMatchingFile($file);

	if(not defined($entry)) {
		print "$file does not exist in the Trash\n";
		return;
	}
	UndoTrashinfo($entry);
}

sub UndoRegex($)
{
	my $reg		=	shift;
	my @list = GetRegexMatchingFiles($reg);
	if(scalar @list == 0) {
		print "No files matching /$reg/ found\n";
		exit;
	}
	foreach my $p (@list) {
		print "Restoring $p->{PATH}\n" if($OptionVerbose > 0);
		UndoTrashinfo($p);
	}
}

##############################################################################
#		         Removing from trash                                 #
##############################################################################

sub EmptyTrash()
{
	if($OptionForce == 0 and GetUserPermission("Completely empty the trash?") == 0) {
		exit;
	}

	# Set Force to 1 so that The rest of subs do not nag the user.
	$OptionForce = 1;

	# Empty Home Trash
	my @dev_list = keys %SystemDevices;
	push @dev_list, $Session{HomePath};

	# Empty Devices Trash
	foreach my $dev (@dev_list) {
		next if($dev eq $Session{HomeDev});
		my $trsh = GetDeviceTrash($dev);
		next unless(-d $trsh);

		print "Removing all files in trash : $dev\n" if($OptionVerbose > 0);

		if(-e "$trsh/metadata") {
			SysDelete("$trsh/metadata", "-f");
			system("touch", "$trsh/metadata");
		}

		my @list = GetSpecificTrashContents($trsh);
		foreach my $p (@list) {
			RemoveTrashinfo($p);
		}
	}
}

sub RemoveFromTrash($)
{
	my $file	=	shift;

	my $entry = GetLatestMatchingFile($file);

	if(not defined($entry)) {
		print "$file does not exist in the Trash\n";
		return;
	}
	RemoveTrashinfo($entry);
}

sub RemoveFromTrashRegex($)
{
	my $reg		=	shift;
	my @list = GetRegexMatchingFiles($reg);
	foreach my $p (@list) {
		RemoveTrashinfo($p);
	}
}

##############################################################################
#		                  Deleting                                   #
##############################################################################

sub DeleteFile($)
{
	my $path	=	shift;

	$path       = AbsolutePath($path);
	my $trsh    = GetTrashDir($path);
	my $name    = basename($path);
	my $dirname = dirname($path);

	if(not(-l $path) and not(-e $path)){
		print "Cowardly refused to delete non-existant file $path\n";
		return;
	}

	if($path =~ /$trsh.*/) {
		print "Cannot delete $path in the trash. Please use -e to remove the file\n";
		return;
	}

	# Error on directories without -r flag.
	if(-d $path and not(-l $path) and $OptionRecursive == 0) {
		print "trsh: cannot remove `$path': Is a directory\n";
		return;
	}

	if($OptionInteractive > 0 and GetUserPermission("Delete $path? ") == 0) {
		return;
	}

	# Always ask for permission for write-protected files
	unless(-w $path) {
		my $what_file = FileTypeString($path);
		if($OptionForce == 0 and GetUserPermission("trsh: delete write-protected $what_file `$path'?") == 0) {
			return;
		}
	}

	# If dirname is not writable, you cannot delete this file.
	unless(-w $dirname) {
		print "trsh: cannot delete `$path': Permission denied\n";
		return;
	}


	# if force is on pass to rm.
	if($OptionPermanent > 0) {
		my $flag = "";
		$flag = $flag . "-r " if($OptionRecursive > 0);
		$flag = $flag . "-f " if($OptionForce > 0);
		SysDelete($path,$flag);
		print "Permanently removed: `$path'\n" if($OptionVerbose > 0);
		return;
	}

	PutTrashinfo({
			PATH=>$path, 
			DATE=>$Session{CurrentDate}, 
			NAME=>$name, 
			TRASH=>$trsh });

	print "Deleted: `$path'\n" if($OptionVerbose > 0);
}

sub DeleteRegex($)
{
	my $reg		=	shift;
	my $dir = dirname($reg);
	if($dir eq ""){
		$dir = cwd();
	}
	$reg = PrepareRegex(basename($reg));
	foreach my $file (Glob("$dir/*", "$dir/.*")) {
		if($file =~ $reg) {
			DeleteFile($file);
		}
	}
}


##############################################################################
#		                  Listing                                    #
##############################################################################

sub ListTrashContents()
{
	my @list = GetTrashContents();
	ListArrayContents(\@list);
}

sub ListRegexTrashContents($)
{
	my $reg		=	shift;
	my @list = GetRegexMatchingFiles($reg);
	ListArrayContents(\@list);
}

sub ListArrayContents($)
{
	my $ref		=	shift;
	my @list = @{$ref};

	if(scalar(@list) == 0) {
		return;
	}
	my %dates;

	SetWidths(\@list);

	foreach my $p (@list) {
		if(defined($dates{$p->{DATE}})) {
			push @{$dates{$p->{DATE}}}, $p;
		} else {
			$dates{$p->{DATE}} = [$p];
		}
	}

	printf("%-${ListNameWidth}s| ", "Trash Entry");
	printf("%-${ListDateWidth}s| ", "Deletion Date") if($OptionDate > 0);
	printf("%-${ListSizeWidth}s| ", "Size") if($OptionSize > 0);
	printf("%s\n", "Restore Path");
	printf("%-${ListNameWidth}s| ", "-----------");
	printf("%-${ListDateWidth}s| ", "-------------") if($OptionDate > 0);
	printf("%-${ListSizeWidth}s| ", "----") if($OptionSize > 0);
	printf("%s\n", "------------");

	foreach my $date (sort {$b cmp $a} keys %dates) {
		foreach my $p (@{$dates{$date}}) {
			PrintTrashinfo($p);
		}
	}
}

##############################################################################
#		                    Trash Size                               #
##############################################################################

sub PrintTrashSize()
{
	my $sz  = GetTrashSize($Session{HomeTrash});

	PrintTrashSizeLine("Home Trash", $sz);

	foreach my $dev (keys %SystemDevices) {
		next if($dev eq $Session{HomeDev});
		$sz = GetTrashSize(GetDeviceTrash($dev));
		PrintTrashSizeLine("$dev Trash", $sz);
	}
}

sub PrintTrashSizeLine($$)
{
	my $dev		=	shift;
	my $sz		=	shift;

	my $sz_color = SizeColor($sz);

	$dev = Crop(sprintf("%-${SDevWidth}s", $dev), $SDevWidth);
	$sz  = Crop(sprintf("%-${SSizeWidth}s",$sz), $SSizeWidth);

	PrintColored("$sz", $sz_color);
	PrintColored("| ", "reset");
	PrintColored("$dev\n", "reset");
}

sub SizeColor($)
{
	my $sz		=	shift;
	if($OptionHumanReadable == 0) {
		$sz = HumanReadableSize($sz);
	}
	if($sz =~ /P/) {
		return "Red";
	} elsif($sz =~ /T/) {
		return "Red";
	} elsif($sz =~ /G/) {
		return "Red";
	} elsif($sz =~ /M/) {
		return "Blue";
	} elsif($sz =~ /k/) {
		return "Cyan";
	} else {
		return "Green";
	}
	return "reset";
}

sub GetTrashSize($)
{
	my $trash_path	=	shift;
	
	my $calculate_trash = 0;

	my $sz = "";

	unless (-d $trash_path) {
		$sz = 0;
		$sz = HumanReadableSize($sz) if($OptionHumanReadable > 0);
		return $sz;
	}

	my $info_mtime = (stat("$trash_path/info"))[9];
	my $metadata_mtime = (stat("$trash_path/metadata"))[9];

	# If info was modified after metadata
	if(! -e "$trash_path/metadata" or $info_mtime > $metadata_mtime) {
		$sz = UpdateSizeMetadata($trash_path);
	} else {
		$sz = GetSizeMetadata($trash_path);
		if($sz eq "BAD") {
			print "WARNING BAD metadata file. Fixing it\n";
			SysDelete("$trash_path/metadata","-f");
			return GetTrashSize($trash_path);
		}
	}

	$sz = HumanReadableSize($sz) if($OptionHumanReadable > 0);

	return $sz;
}

sub UpdateSizeMetadata($)
{
	my $trash	=	shift;
	my $sz = DirSize($trash);
	open OUT, "+>$trash/metadata" or die "Could not open $trash/metadata for write\n";
	print OUT "[Cached]\n";
	print OUT "Size=$sz\n";
	close(OUT);
	return $sz;
}

sub GetSizeMetadata($)
{
	my $trash	=	shift;
	my $sz = "";
	my $valid = 0;

	open IN, "$trash/metadata" or die "Could not open $trash/metadata for read\n";
	while(my $line = <IN>) {
		chomp($line);
		if($line =~ /^Size=(\d+)$/) {
			$sz = $1;
			$valid = 1;
			last;
		}
	}

	close(IN);

	if($valid == 1) {
		return $sz;
	} else {
		return "BAD";
	}
}

##############################################################################
#		          Relating to files in trash                         #
##############################################################################

sub GetLatestMatchingFile($)
{
	my $file	=	shift;

	my @list = GetTrashContents();
	my @dates;
	my $search_path = 0;

	if($file =~ /\//) {
		$search_path = 1;
	}

	my @remove_list = ();

	foreach my $p (@list) {
		if($search_path == 1) {
			if($p->{PATH} eq $file) {
				push @remove_list, $p;
				push @dates, $p->{DATE};
			}
		} else {
			if($p->{NAME} eq $file) {
				push @remove_list, $p;
				push @dates, $p->{DATE};
			}
		}
	}

	@dates = sort @dates;
	my $date_to_remove = $dates[$#dates];
	my $return;
	foreach my $remove (@remove_list) {
		next if($remove->{DATE} ne $date_to_remove);
		$return  = $remove;
	}
	return $return;
}

sub GetRegexMatchingFiles($)
{
	my $reg		=	shift;
	$reg = PrepareRegex($reg);
	my @list = GetTrashContents();
	my @matched = ();
	foreach my $p (@list) {
		if($p->{PATH} =~ $reg) {
			push @matched, $p;
		}
	}
	return @matched;
}

sub GetTrashContents()
{
	my @list = ();
	push @list, GetSpecificTrashContents($Session{HomeTrash});

	foreach my $dev (keys %SystemDevices) {
		next if($dev eq $Session{HomeDev});
		push @list, GetSpecificTrashContents(GetDeviceTrash($dev));
	}
	return @list;
}

sub GetSpecificTrashContents($)
{
	my $trash_dir	=	shift;

	# Return an empty list if the trash dir does not exist.
	unless(-d $trash_dir) {
		return ();
	}

	if($OptionList > 0 and $OptionSize > 0) {
		# Dummy call to update metadata.
		my $size = GetTrashSize($trash_dir);
	}

	my @list = Glob("$trash_dir/info/*.trashinfo", "$trash_dir/info/.*.trashinfo");
	my @trash_list = ();
	foreach my $info (@list) {
		my $name = basename($info);
		if($name =~ /^(.+).trashinfo$/) {
			$name = $1;
		} else {
			# This should never happen
			print "REGEX ERROR! LINE: " . __LINE__ . "\n";
			return ();
		}
		my $p = GetTrashinfo($info);
		$p->{TRASH} = $trash_dir;
		$p->{IN_TRASH_NAME} = $name;
		$p->{INFO_PATH} = "$trash_dir/info/$name.trashinfo";
		$p->{IN_TRASH_PATH} = "$trash_dir/files/$name";
		if($trash_dir eq $Session{HomeTrash}) {
			$p->{DEV} = "HOME";
		} else {
			$p->{DEV} = InDevice($trash_dir);
			$p->{PATH} = $p->{DEV} . "/" . $p->{PATH};
		}
		$p->{NAME} = basename($p->{PATH});
		if($OptionSize > 0) {
			$p->{SIZE} = EntrySize($p->{IN_TRASH_PATH});
			$p->{SIZE} = HumanReadableSize($p->{SIZE}) if($OptionHumanReadable > 0);
		} else {
			$p->{SIZE} = 0;
		}
		push @trash_list, $p;
	}

	return @trash_list;
}

sub GetLatestDeleted()
{
	my @list  = GetTrashContents();
	my @dates = ();

	foreach my $p (@list) {
		push @dates, $p->{DATE};
	}

	if(scalar(@dates) == 0) {
		return ();
	}

	@dates = sort @dates;
	my $latest = $dates[$#dates];
	my @latest_info;
	foreach my $p (@list) {
		if($p->{DATE} eq $latest) {
			push @latest_info, $p;
		}
	}
	return @latest_info;
}

##############################################################################
#		            Trash info files                                 #
##############################################################################

sub GetTrashinfo($)
{
	my $trashinfo	=	shift;
	open IN, "$trashinfo" or return "ERROR: Could not open $trashinfo, LINE: " . __LINE__ . "\n";
	my %ret;
	while(my $line = <IN>) {
		chomp($line);
		if($line =~ /^Path=(.+)$/) {
			my $path = $1;
			if(not defined($ret{PATH})) {
				$ret{PATH} = $path;
			}
		}
		if($line =~ /^DeletionDate=(.+)$/) {
			my $date = $1;
			if(not defined($ret{DATE})) {
				$ret{DATE} = $date;		
			}
		}
	}
	return \%ret;
}

sub PutTrashinfo($)
{
	my $entry	=	shift;
	my $success = 0;
	my $infoname;

	MakeTrashDir($entry->{TRASH});

	my $infodir = "$entry->{TRASH}/info";
	my $filesdir = "$entry->{TRASH}/files";

	while($success == 0) {
		$infoname = GetInfoName($infodir, $entry->{NAME});
		$success = sysopen INFO, "$infodir/$infoname",  O_RDWR|O_EXCL|O_CREAT;
	}
	print INFO "[Trash Info]\n";
	my $infile_path = $entry->{PATH};
	if($entry->{TRASH} ne $Session{HomeTrash}) {
		my $dev = InDevice($entry->{PATH});
		if($entry->{PATH} =~ /^$dev\/(.+)$/) {
			$infile_path = $1;
		}
	}
	print INFO "Path=$infile_path\n";
	print INFO "DeletionDate=$Session{CurrentDate}\n";

	close(INFO);

	my $in_trash_name;
	if($infoname =~ /^(.+)\.trashinfo$/) {
		$in_trash_name = $1;
	} else {
		# THIS SHOULD NEVER HAPPEN!
		print "REGEX FAILED! LINE: " . __LINE__ . "\n";
	}
	$success = SysMove($entry->{PATH}, "$filesdir/$in_trash_name");
	if($success != 0) {
		print "Recovering from failed delete\n";
		SysDelete("$infodir/$infoname","-f");
	}
}

sub GetInfoName($$)
{
	my $info	=	shift;
	my $name	=	shift;

	my $postfix = "";
	my $infoname = $name . $postfix . ".trashinfo";
	my $info_path = "$info/$infoname";
	my $ind = 0;
	while(-e $info_path) {
		$ind++;
		$postfix = "-$ind";
		$infoname = $name . $postfix . ".trashinfo";
		$info_path = "$info/$infoname";
	}
	return $infoname;
}

sub PrintTrashinfo($)
{
	my $p		=	shift;

	# Check for invalid calls.
	if(not defined($p->{PATH})) {
		return;
	}
	my $name = Crop(sprintf("%-${ListNameWidth}s", $p->{NAME}), $ListNameWidth);
	my $date = Crop(sprintf("%-${ListDateWidth}s", HumanReadableDate($p->{DATE})), $ListDateWidth);
	my $path = Crop(sprintf("%-${ListPathWidth}s", $p->{PATH}), $ListPathWidth);
	my $sz   = Crop(sprintf("%-${ListSizeWidth}s", $p->{SIZE}), $ListSizeWidth);

	PrintColored("$name", FileTypeColor($p->{IN_TRASH_PATH}));
	PrintColored(" |", "reset");
	if($OptionDate > 0) {
		PrintColored(" $date", "Yellow");
		PrintColored(" |", "reset");
	}
	if($OptionSize > 0) {
		my $sz_color = SizeColor($p->{SIZE});
		PrintColored(" $sz", SizeColor($p->{SIZE}));
		PrintColored(" |", "reset");
	}
	PrintColored(" $path\n", "reset");
}

sub RemoveTrashinfo($)
{
	my $entry	=	shift;

	if($OptionForce == 0 and GetUserPermission("Remove $entry->{NAME} for trash?") == 0) {
		return;
	}
	print "Removing from trash: `$entry->{PATH}'\n" if($OptionVerbose > 0);
	SysDelete($entry->{IN_TRASH_PATH}, "-rf");
	SysDelete($entry->{INFO_PATH}, "-rf");
}

sub UndoTrashinfo($)
{
	my $entry	=	shift;

	my $from_path = $entry->{IN_TRASH_PATH};
	my $to_path   = $entry->{PATH};
	my $info_path = $entry->{INFO_PATH};

	if($OptionInteractive > 0 and GetUserPermission("Restore $to_path?") == 0) {
		return;
	}

	if(-e $to_path) {
		if($OptionForce == 0 and GetUserPermission("Overwrite file $to_path?") == 0) {
			return;
		}
		SysDelete($to_path, "-r -f");
	}

	SysMkdir(dirname($to_path)) unless(-d dirname($to_path));

	my $success = SysMove($from_path, $to_path);
	if($success == 0) {
		SysDelete($info_path,"-f");
	} else {
		print "Error restoring $to_path\n";
		return;
	}
	print "Restored: $to_path\n" if($OptionVerbose > 0);
}



##############################################################################
#		        Trash directory location                             #
##############################################################################

sub GetDeviceTrash($)
{
	my $dev		=	shift;
	if($dev eq $Session{HomeDev}) {
		return $Session{HomeTrash};
	}
	return GetTrashDir("$dev/DUMMY");
}

sub GetTrashDir($)
{
	my $path	=	shift;
	my $dev = InDevice($path);

	if($dev eq $Session{HomeDev}) {
		return $Session{HomeTrash};
	}

	my $trash = "$dev/.Trash";

	# Tests defined by freeDesktop.org's trash specification.
	if(-d $trash and -k $trash and !-l $trash and -w $trash) {
		$trash = "$trash/$Session{UserID}";
		return $trash;
	}

	# If not defined...
	$trash = "$dev/.Trash-$Session{UserID}";
	return $trash;
}

sub MakeTrashDir($)
{
	my $root	=	shift;
	unless(-d "$root") {
		system("mkdir", "-p", "$root");
		mkdir "$root/files";
		mkdir "$root/info";
		system("touch", "$root/metadata");
	}
}


##############################################################################
#		        Mounted Device Handling                              #
##############################################################################

sub InDevice($)
{
	my $path	=	shift;

	my $dev = InDir(AbsolutePath($path), [keys %SystemDevices]);

	if($dev eq "/") {
		$dev = $Session{HomeDev};
	}
	return $dev;
}

sub InDir($$)
{
	my $path	=	shift;
	my $ref_list	=	shift;

	my $matched = $path;
	while($matched ne "/" ) {
		last if(grep $_ eq $matched, @{$ref_list});
		$matched = dirname($matched);
	}
	return $matched;
}

sub GetDeviceList()
{
	my $df = Df();
	
	foreach my $e (keys %{$df}) {
		my $mnt = $df->{$e}->{'Mount'};
		# Do not count mounts which are not writable.
		unless(-w $mnt) {
			next;
		}
		$SystemDevices{$mnt} = 1;
	}
}

##############################################################################
#		             Environment                                     #
##############################################################################

sub SetEnvirnment()
{
	$Session{UserName} = `id -un`;
	chomp($Session{UserName});
	$Session{UserID}   = int(`id -u`);
	$Session{HomePath} = $ENV{HOME};
	$Session{HomeTrash} = "$Session{HomePath}/.local/share/Trash";
	GetDeviceList();
	$Session{HomeDev}   = InDir($Session{HomePath},[keys %SystemDevices]);

	# Specification states that the Home trash must be created.
	MakeTrashDir($Session{HomeTrash});

	# Get current date/time
	my $x = `date --rfc-3339=seconds`;
	chomp($x);
	my @tmp = split(/ /, $x);
	my $date = $tmp[0];
	my $time = $tmp[1];
	@tmp = split(/-/,$time);
	$time = "$tmp[0]";
	$Session{CurrentDate} = "${date}T$time";


	chomp($Session{CurrentDate});

	Getopt::Long::Configure('bundling');

	GetOptions( 
			'e|empty'	  => \$OptionEmpty,
			'l|list'	  => \$OptionList,
			'f|force+'	  => \$OptionForce,
			'r|recursive'	  => \$OptionRecursive,
			'R|recursive'	  => \$OptionRecursive,
			'u|undo'	  => \$OptionUndo,
			'help'		  => \$OptionHelp,
			'i|interactive'	  => \$OptionInteractive,
			'p|permanent'	  => \$OptionPermanent,
			'v|verbose'	  => \$OptionVerbose,
			'x|regex'         => \$OptionRegex,
			'color!'	  => \$OptionColor,
			'date!'		  => \$OptionDate,
			'relative-date!'  => \$OptionRelativeDate,
			's|size'	  => \$OptionSize,
			'h|human'         => \$OptionHumanReadable,
			'version'         => \$OptionVersion,
			'd|debug'         => \$OptionDebug,
	) == 1 or Usage();

	$Term::ANSIColor::AUTORESET = 1;

	if($OptionForce > 0) {
		$OptionInteractive = 0;
	}

	# Do not reserve space without -s option.
	if($OptionSize == 0) {
		$ListPathWidthPerc += $ListSizeWidthPerc;
		$ListSizeWidthPerc = 0;
	}

	if($OptionDate == 0) {
		$ListNameWidthPerc += $ListDateWidthPerc;
		$ListDateWidthPerc = 0;
	}

	my $screen_width = (GetTerminalSize())[0];

	# Adjust for each character '| '
	$screen_width = $screen_width - 4;

	$ListNameWidth = int($screen_width * $ListNameWidthPerc / 100);
	$ListDateWidth = int($screen_width * $ListDateWidthPerc / 100);
	$ListSizeWidth = int($screen_width * $ListSizeWidthPerc / 100);
	$ListPathWidth = int($screen_width * $ListPathWidthPerc / 100);

	if($OptionDate != 0 and $ListDateWidth > 25) {
		my $overflow = $ListDateWidth - 25;
		$ListNameWidth += (int($overflow / 2));
		$ListPathWidth += ($overflow - int($overflow / 2));
		$ListDateWidth = 25;
	}
	if($OptionSize != 0 and $ListSizeWidth > 15) {
		$ListPathWidth += ($ListSizeWidth - 15);
		$ListSizeWidth = 15;
	}

	$SSizeWidth   = int($screen_width * $SSizeWidthPerc   / 100);
	$SDevWidth  = int($screen_width * $SDevWidthPerc  / 100);

	if($SSizeWidth > 15) {
		$SDevWidth += ($SSizeWidth - 15);
		$SSizeWidth = 15;
	}

	# FileTypeColors
	InitFileTypeColors();
}

sub DebugDump()
{;
	print <<DEBUG
	USER            = $Session{UserName}
	USER ID         = $Session{UserID}
	USER HOME       = $Session{HomePath}
	USER HOME DEV   = $Session{HomeDev}
	USER HOME TRASH = $Session{HomeTrash}
	TIME            = $Session{CurrentDate}
	LIST NAME WIDTH = $ListNameWidth
	LIST DATE WIDTH = $ListDateWidth
	LIST SIZE WIDTH = $ListSizeWidth
	LIST PATH WIDTH = $ListPathWidth
	SIZE SIZE WIDTH = $SSizeWidth
	SIZE DEV  WIDTH = $SDevWidth

	RECOGNIZED DEVICES
DEBUG
;
	foreach my $dev (sort keys %SystemDevices) {
		print "\t$dev\n";
	}
	exit;
}


##############################################################################
#		                   Help!                                     #
##############################################################################

sub Version()
{
	print "TRASH VERSION: $VERSION\n";
	exit;
}

sub Usage()
{
	print <<USAGE
TRSH VERSION $VERSION
AUTHOR: Amithash Prasad <amithash\@gmail.com>
Copyright 2010 under the terms of GPLv3

USAGE: rm [OPTIONS]... [FILES]...
FILES: A list of files to recover or delete.
rm FILES just moves FILES to the trash. By default, directories are not deleted.

OPTIONS:

-u|--undo [FILES]
Undo's a delete (Restores FILES or files matching REGEX from trash). 
Without arguments, the latest deleted file is restored.

-p|--permanent FILES
Instructs trsh to permanently delete FILES and completely bypass the trash

-i|--interactively
Prompt the user before any operation.

-r|--recursive
Allows directories to be deleted.

-v|--verbose
Provide verbose output.

-e|--empty [FILES]
Removed FILES or files matching REGEX from the trash (Permanently).
Without arguments, the trash is emptied.

-f|--force
Forces any operation:
	deletion   : overrides -i and does not prompt the user for any action.
	             with -p passes the -f flag to /bin/rm
	restore    : will force overwrites of files and will not ask for user permission.
	empty file : will not ask the user's permission for each file.
	empty trash: will not ask for confirmation from the user.

-l|--list
Display the contents of the trash.

--color (Default) (or --nocolor)
Print listings (Refer -l) with (or without) the terminal's support for colored text.

--date (Default) (or --nodate)
Print (Or do not print) the deletion date with the trash listing (-l)

--relative-date (Default) (or --norelative-date)
Display (or do not display) date in listings as a relative figure in words.

-x|--regex
Considers all parameters (All uses) as perl regexes. So you can delete, undo or remove files
using perl's extensive regex.

-s|--size
Display the size in bytes of the trash. 
If used along with -l, the trash listing will also display each file's size.

-h|--human-readable
If used along with -s, the file size displayed will be human readable
(KB, MB etc) rather than in bytes.

--help
Displays this help and exits.

Please read the README or `man trsh` for more information
USAGE
;
exit;
}

##############################################################################
#		    Coloring and Printing Functions                          #
##############################################################################

sub PrintColored($$) 
{
	my $string	=	shift;
	my $col		=	shift;
	if($OptionColor > 0) {
		print colored($string,$col);
	} else {
		print "$string"
	}
}

sub SetWidths($)
{
	my $ref	=	shift;
	my @list = @{$ref};
	my $name_w = length("Trash Entry ");
	my $date_w = length("Deletion Date ");
	my $size_w = length("Size ");
	my $path_w = length("Restore Path ");

	foreach my $p (@list) {
		my $date = HumanReadableDate($p->{DATE});
		my $name = $p->{NAME};
		my $size = $p->{SIZE};
		my $path = $p->{PATH};
		if(length("$date") > $date_w) {
			$date_w = length("$date ");
		}
		if(length("$name") > $name_w) {
			$name_w = length("$name ");
		}
		if(length("$size") > $size_w) {
			$size_w = length("$size ");
		}
		if(length("$path") > $path_w) {
			$path_w = length("$path ");
		}
	}
	if($name_w < $ListNameWidth) {
		if($OptionDate == 1) {
			$ListDateWidth += ($ListNameWidth - $name_w);
		} elsif($OptionSize == 1) {
			$ListSizeWidth += ($ListNameWidth - $name_w);
		} else {
			$ListPathWidth += ($ListNameWidth - $name_w);
		}
		$ListNameWidth = $name_w;
	}
	if($OptionDate > 0 and $date_w < $ListDateWidth) {
		if($OptionSize > 0) {
			$ListSizeWidth += ($ListDateWidth - $date_w);
		} else {
			$ListPathWidth += ($ListDateWidth - $date_w);
		}
		$ListDateWidth = $date_w;
	}
	if($OptionSize > 0 and $size_w < $ListSizeWidth) {
		$ListPathWidth += ($ListSizeWidth - $size_w);
		$ListSizeWidth = $size_w;
	}
}

sub InitFileTypeColors()
{
	my %num_to_col = (
		30	=>	"Black",
		31	=>	"Red",
		32	=>	"Green",
		33	=>	"Yellow",
		34	=>	"Blue",
		35	=>	"Magenta",
		36	=>	"Cyan",
		37	=>	"White",
	);
	my @dircolors = split(/\n/,`dircolors -p`);
	foreach my $entry (@dircolors) {
		next if($entry =~ /^\s*#/); # Ignore comments
		next if($entry =~ /^TERM/); # Ignore terminals
		# Remove Trailing comments.
		if($entry =~ /([^#]+)\s*#.+$/) {
			$entry = $1;
		}
		if($entry =~ /\.(.+) (\d+)[;:](\d+)$/)  {
			my $ft  = $1;
			my $att = int($2);
			my $fg  = int($3);
			if($fg >= 30 and $fg <= 37) {
				# Valid Col
				$TypeColors{$ft} = $num_to_col{$fg};
			}
			next;
		}
		if($entry =~ /(.+)\s+(\d\d);(\d\d)/)  {
			my $ft  = $1;
			my $att = int($2);
			my $fg  = int($3);
			if($fg >= 30 and $fg <= 37) {
				# Valid Col
				$AttrColors{$ft} = $num_to_col{$fg};
			}
			next;
		}
	}
}


sub Crop($$)
{
	my $string	=	shift;
	my $width	=	shift;
	$width = $width - 2;
	if(length($string) <= $width) {
		return $string;
	}
	my @tmp = split(//,$string);
	my $ret = join("", @tmp[0..$width]);
	return $ret;
}

sub HumanReadableSize($)
{
	my $sz = shift;
	my $kb = 1024;
	my $mb = 1024 * $kb;
	my $gb = 1024 * $mb;
	my $tb = 1024 * $gb;
	my $pb = 1024 * $tb;
	if($sz > $pb) {
		$sz = $sz / $pb;
		return sprintf("%.3f PB", $sz);
	} elsif($sz > $tb) {
		$sz = $sz / $tb;
		return sprintf("%.3f TB", $sz);
	} elsif($sz > $gb) {
		$sz = $sz / $gb;
		return sprintf("%.3f GB", $sz);
	} elsif($sz > $mb) {
		$sz = $sz / $mb;
		return sprintf("%.3f MB", $sz);
	} elsif($sz > $kb) {
		$sz = $sz / $kb;
		return sprintf("%.3f kB", $sz);
	} else {
		return sprintf("%.3f B", $sz);
	}
}


##############################################################################
#		            File Type Functions                              #
##############################################################################

sub FileTypeString($)
{
	my $path	=	shift;
	my $what;
	if(-d $path) {
		$what = "directory";
	} if(-f $path and -s $path == 0) {
		$what = "regular empty file";
	} else {
		$what = "regular file";
	}
	return $what;
}

sub FileTypeColor($)
{
	my $name	=	shift;

	my $ft = "";

	my $base = basename($name);
	if($base =~ /^(.+)-\d+$/) {
		$base = $1;
	}
	if($base =~ /^.+\.(.+)$/) {
		$ft = lc($1);
	}

	if(-l $name) {
		return $AttrColors{LINK};
	} elsif(-d $name) {
		return $AttrColors{DIR};
	} elsif(-x $name) {
		return $AttrColors{EXEC};
	} elsif(defined($TypeColors{$ft})) {
		return $TypeColors{$ft};
	} else {
		return "reset";
	}
}


##############################################################################
#		           System Level Functions                            #
##############################################################################

sub SysMove($$)
{
	my $from = shift;
	my $to = shift;

	return system("mv", $from, $to);
}

sub SysMkdir($)
{
	my $dir = shift;

	return system("mkdir", "-p", $dir);
}

sub SysDelete($$)
{
	my $file   = shift;
	my $flags  = shift;

	if($flags =~ /^\s*$/) {
		return system("rm", $file);
	} else {
		return system("rm", $flags, $file);
	}
}

sub Df()
{
	open IN, "df -T |" or die "Could not do a df\n";
	my $h_l = <IN>;
	my @header = ('Type', '1K-blocks', 'Used', 'Available', 'Use%', 'Mount');
	my %return;

	while(my $line = <IN>) {
		my $ret = {};
		chomp($line);
		next if($line =~ /^\s*$/);
		my @tmp = split(/\s+/,$line);
		while(scalar(@tmp) < scalar(@header)) {
			$line = <IN>;
			chomp($line);
			next if($line =~ /^\s*$/);
			push @tmp, split(/\s+/, $line);
		}
		my $dev = shift @tmp;
		for(my $i = 0; $i < scalar @tmp; $i++) {
			if($i <= $#header) {
				$ret->{$header[$i]} = $tmp[$i];
			} else {
				$ret->{$header[$#header]} .= " $tmp[$i]";
			}
		}
		$return{$dev} = $ret;
	}
	return \%return;
}

sub AbsolutePath($)
{
	my $in		=	shift;
	return File::Spec->rel2abs( $in ) ;
}

sub InHome($)
{
	my $path	=	shift;

	if($path =~ /$Session{HomePath}.+/) {
		return 1;
	}
	return 0;
}

sub GetUserPermission($)
{
	my $question	=	shift;
	my $success = 0;
	my $ans;
	while($success == 0) {
		print "$question (y/n): ";
		$ans = <STDIN>;
		chomp($ans);
		if($ans eq "y") {
			return 1;
		}
		if($ans eq "n") {
			return 0;
		}
	}
}

sub DirSize($)
{
	my $path = shift;
	my $size = 0;
	my $fd;
	opendir($fd, $path) or die "$!\n";
	for my $item (readdir($fd)) {
		next if($item =~ /^\.\.?$/);
		my $path = "$path/$item";
		$size += ((-d $path) ? DirSize($path) : FileSize($path));
	}
	closedir($fd);

	return $size;
}

sub FileSize($)
{
	my $path = shift;
	return (-f $path) ? (stat($path))[7] : 0;
}

sub EntrySize($)
{
	my $path = shift;
	return (-d $path) ? DirSize($path) : FileSize($path);
}

sub PrepareRegex($)
{
	my $reg		=	shift;
	$reg =~ s/\$$//;
	$reg =~ s/\//\\\//g;
	my $regex = eval { qr/($reg)/ };
	if($@) {
		print "ERROR: Invalid regex: $reg\n$@ LINE: ".  __LINE__ . "\n";
		exit;
	}
	return $regex;
}

##############################################################################
#		           Date related functions                            #
##############################################################################

sub HumanReadableDate($)
{
	my $tdate	=	shift;

	my $date = SplitDate($tdate);
	my $on = "AM";
	my $mod_hour = $date->{HOUR};

	if($date->{HOUR} == 0) {
		$on = "AM";
		$mod_hour = 12;
	} elsif($date->{HOUR} == 12) {
		$on = "PM";
	} elsif($date->{HOUR} > 12) {
		$on = "PM";
		$mod_hour = $date->{HOUR} - 12;
	}

	my $ret = "";

	if($OptionRelativeDate == 1) {
		my $desc = "";
		my $today = SplitDate($Session{CurrentDate});
		my $days = DiffDate($date, $today);
		if($days == 0) {
			$desc = "Today";
		} elsif($days == 1) {
			$desc = "Yesterday";
		} elsif($days < 7) {
			$desc = "$days days old";
		} elsif($days < 30) {
			my $weeks = int($days / 7);
			if($weeks == 1) {
				$desc = "Last week";
			} else {
				$desc = "$weeks weeks old";
			}
		} elsif($days < 365) {
			my $months = int($days / 30);
			if($months == 1) {
				$desc = "Last month";
			} else {
				$desc = "$months months old";
			}
		} elsif($days < (365 * 2)) {
			$desc = "Last year";
		} else {
			my $years = int($days / 365);
			$desc = "$years years old";
		}

		$ret = "$desc";
	} else {
		$ret = "$mod_hour:$date->{MINUTE}:$date->{SECOND}$on $date->{MONTH}/$date->{DATE}/$date->{YEAR}";
	}

	return $ret;
}

sub SplitDate($)
{
	my $tdate	=	shift;

	my @tmp = split(/T/,$tdate);
	$tdate = $tmp[0];
	my $ttime = $tmp[1];

	if($ttime =~ /(.+)\+.+/) {
		$ttime = $1;
	}

	my @hdate = split(/-/,$tdate);
	my @htime = split(/:/,$ttime);

	my %date = (
	HOUR   => int($htime[0]) + 0,
	MINUTE => int($htime[1]) + 0,
	SECOND => int($htime[2]) + 0,
	DATE   => int($hdate[2]) + 0,
	MONTH  => int($hdate[1]) + 0,
	YEAR   => int($hdate[0]) + 0,
	);
	return \%date;
}

sub DiffDate($$)
{
	my $date1 = shift;
	my $date2 = shift;

	if($date1->{YEAR} == $date2->{YEAR}) {
		return Date2Days($date2) - Date2Days($date1);
	}
	my $days = Year2Days($date1) - Date2Days($date1);
	for(my $i = $date1->{YEAR} + 1; $i < $date2->{YEAR}; $i++) {
		$days += Date2Days($date1);
	}
	$days += Date2Days($date2);
}

sub Date2Days($)
{
	my $date	=	shift;
	my %days_month = (
		1	=>	31,
		2	=>	28,
		3	=>	31,
		4	=>	30,
		5	=>	31,
		6	=>	30,
		7	=>	31,
		8	=>	31,
		9	=>	30,
		10	=>	31,
		11	=>	30,
		12	=>	31
	);
	if($date->{YEAR} % 4 == 0) {
		$days_month{2} = $days_month{2} + 1;
	}
	my $days = 0;
	for(my $i=1; $i < $date->{MONTH}; $i++) {
		$days += $days_month{$i};
	}
	$days += $date->{DATE};
	
	return $days - 1;
}
sub Year2Days($)
{
	my $date	=	shift;
	if($date->{YEAR} % 4 == 0) {
		return 366;
	}
	return 365;
}

sub Glob
{
	my @patterns	=	@_;
	my @ret;
	foreach my $pattern (@patterns) {
		$pattern =~ s/\\/\\\\/g;
		$pattern =~ s/\`/\\\`/g;
		$pattern =~ s/"/\\"/g;
		$pattern =~ s/\$/\\\$/g;
		$pattern =~ s/ /\\ /g;
		my @list = glob($pattern);
		foreach my $f (@list) {
			my $file = AbsolutePath($f);
			my $base = basename($file);
			next if($base eq ".");
			next if($base eq "..");
			push @ret, $file;
		}
	}
	return @ret;
}

