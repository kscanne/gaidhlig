#!/usr/bin/perl

# used in makefile

use strict;
use warnings;

my %tags;

sub converter
{
	(my $word, my $code) = @_;
	my $tag = $tags{$code};
	my $ans = $tag.$word;
	$tag =~ s/<(.).*/<\/$1>/;
	$ans .= $tag;
	return $ans;
}

open (POSTAGS, "/home/kps/gaeilge/gramadoir/gr/ga/pos-ga.txt") or die "Could not open Irish pos tags list: $!\n";

while (<POSTAGS>) {
	m/^([0-9]+)\s+(<[^>]+>)/;
	$tags{$1} = $2;
}

while (<STDIN>) {
	s/([^ ]+) ([0-9]+)/converter($1,$2)/eg;
	print;
}
exit 0;
