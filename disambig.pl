#!/usr/bin/perl

use strict;
use warnings;

my $pathtodata='/usr/local/share/ga2gd/disambig';

sub get_filename
{
	(my $sprioc) = @_;
	my $spriocfhocal = $sprioc;
	$spriocfhocal =~ s/<[^>]+>//g;
	(my $tg) = $sprioc =~ m/^<([A-Z])/;
	$spriocfhocal =~ s/'//g;
	$spriocfhocal =~ s/�/a_/g;
	$spriocfhocal =~ s/�/e_/g;
	$spriocfhocal =~ s/�/i_/g;
	$spriocfhocal =~ s/�/o_/g;
	$spriocfhocal =~ s/�/u_/g;
	$spriocfhocal .= $tg;
	$spriocfhocal = 'ba_NM' if ($sprioc eq '<N pl="n" gnt="n" gnd="m">b�</N>');
	return "$pathtodata/$spriocfhocal.dat";
}

sub resolve_one
{
	(my $sentence, my $sprioc) = @_;
	my $P;
	my $C;
	my $unseen;
	open (DATAIN, "<:bytes", get_filename($sprioc)) or die "Could not open input .dat file for word $sprioc: $!\n";
	# reads in hashrefs $P, $C, $unseen
	local $/;
	my $boo=<DATAIN>;
	close DATAIN;
	eval $boo; 

	my $ans;  # best sense for this sentence
	my $max=-1e12;
	foreach my $s (keys %$P) {
		my $val = $P->{$s};
		while ($sentence =~ m/<s>(<[^>]+>[^<]+<\/[A-Z]>)<\/s>/g) {
			unless ($sprioc eq $1) {
				if (exists($C->{"$1|$s"})) {
					$val += $C->{"$1|$s"};
				}
				else { # 0 count, so smooth
					$val += $unseen->{$s};
				}
			}
		}
		if ($val > $max) {
			$max = $val;
			$ans = $s;
		}
	}
	return $ans;
#	return "<s $ans>$sprioc</s>";
}

my @ambig;
open (AMBIGS, "<:bytes", "/usr/local/share/ga2gd/ambig.txt") or die "Could not open list of ambiguous stems: $!\n";
while (<AMBIGS>) {
	chomp;
	push @ambig, $_;
}
close AMBIGS;


# read in sentences to disambiguate; input format should be output of
# "stemmer -l"
while (<STDIN>) {
	my $sentence = $_;
	foreach my $sprioc (@ambig) {
		$sentence =~ s/<t>(<[^>]+>[^<]+<\/[A-Z]>)<\/t>(<s>$sprioc<\/s>)/"<t ".resolve_one($sentence,$sprioc).">$1<\/t>$2"/eg;
	}
	print $sentence;
}

exit 0;
