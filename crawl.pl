#!/usr/bin/perl -w

#use diagnostics -verbose;
#enable  diagnostics;

use Getopt::Long;
use Config::Simple;
use List::MoreUtils qw( uniq any );
use Data::Dumper;
use feature 'say';
use strict;
use Template;

# TODO make configurable via cl switches
my $modulepath = "./mod";
my $cfg = new Config::Simple("autocv.spec");
my $odir = "./output";

my %spec = $cfg->vars();
my @speckeys = keys %spec;
my @blockkeys;
my @modules;

# produce single blocks to be updated by the corresponding modules
sub chop_block {
	my $blockhash = $cfg->get_block($_);
	my $defaulthash = $cfg->get_block('default');
	my $filename = "$odir/$_.singlespec";
	print "storing single block $_ in $filename\n";
	open(BF, "> $filename") || die "error: cannot open $filename";
	print BF "\n\n# common\n";
	map { print BF "$_=$$defaulthash{$_}\n" } keys %$defaulthash;
	print BF "\n\n# specific\n";
	map { print BF "$_=$$blockhash{$_}\n" } keys %$blockhash;
	close(BF);
}

# mimic a feature that is said to appear in later versions of Config::Simple 
foreach (@speckeys) {
	my @ubk = split('\.', $_);
	push (@blockkeys, $ubk[0]) unless (any { $_ eq $ubk[0]} @blockkeys);
}
#@blockkeys = uniq @blockkeys;

print "processing blocks: ";
map { print "$_ "} @blockkeys;
print "\n";

my $uagang_n = 0;

print "scanning $modulepath for modules ...\n";
my @moduledirs = split(':', $modulepath);
foreach (@moduledirs) {
	my $moduledir = $_;
	opendir(my $dirfh, $moduledir) || die "can't open dir $moduledir: $!";
	#my @dots = grep { /^\./ && -f "$moduledir/$_" } readdir($dirfh);
	foreach(readdir($dirfh)) {
		push (@modules, join('/', $moduledir, substr($_, 0, -4) )) if substr($_, -3, -1) eq 'pm';
	}
	closedir $dirfh;
}
map { print " $_\n"; } @modules;

print "iterating blocks ... \n";
foreach (@blockkeys) {
	my $blockname = $_;
	last if $blockname eq 'default';
	print "$blockname: ";
	my $blockhash = $cfg->get_block($blockname);

	chop_block($blockname);
	if(fork()==0) {
		print "trying modules  ...\n";
		foreach(@modules) {
				print;
				my $file = "$_.pm";
				my $mod = (split('/', $_))[-1];
				
				eval {
					require "$file";
					print $mod . " from $file\n";
					$mod->import();
					my $idurl = $$blockhash{'id_url'};
					print "id_url = $idurl\n";
					my $rh = $mod->fetch($idurl, $odir, $blockname);
					my $tmp = new Config::Simple("$odir/$blockname.singlespec") || die "error: cannot open $odir/$blockname.singlespec";
					map { 
						$tmp->param($_, $$rh{$_});
						print "result: $_ => $$rh{$_}\n";
					} (keys %$rh);
					$tmp->save();
				} or do {
					$@ and die "error in $mod: $@";
				}
		}
	}
	print "\n";
	$uagang_n++;
}
print "spawned $uagang_n requests\n";
wait();
print "---\n";

my $ntf=0;
foreach(@blockkeys) {
	#if (fork()==0) {
		my $blockname = $_;
		my $blockhash = new Config::Simple("$odir/$blockname.singlespec") || die "error: cannot open $odir/$blockname.singlespec";
		my $template = Template->new();
		$template->view_form($blockhash, $odir, $blockname) unless $blockname eq "default";
	#} else {
	#	$ntf++;
	#	if($ntf > 10) {
	#		#TODO wait for commits or something
	#		print "reached more than 10 forms.\n";
	#		print " * * * hit ENTER to proceed with further templates * * *";
	#		my $dummy=<STDIN>;
	#	}
	#}
}
