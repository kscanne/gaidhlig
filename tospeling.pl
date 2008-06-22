#!/usr/bin/perl

use strict;
use warnings;

# pipe fullstem-nomutate.txt through this
# and output in "speling.org" format; see
# http://wiki.apertium.org/wiki/Speling_format

while (<STDIN>) {
	chomp;
	(my $pos, my $surface, my $lemmapos, my $lemma) = m/^(<[^>]+>)([^<]+)<\/[A-Z]> <([A-Z])[^>]*>([^<]+)<\/[A-Z]>$/;
	my $flags;
	my $my_pos;
	if ($pos =~ m/^<N/) {
		$my_pos = 'n';
		if ($pos =~ m/gnd="m"/) {
			$my_pos .= '.m';
		}
		elsif ($pos =~ m/gnd="f"/) {
			$my_pos .= '.f';
		}
		if ($pos =~ m/pl="y"/) {
			$flags = 'pl';
		}
		else {
			$flags = 'sg';
		}
		if ($pos =~ m/gnt="n"/) {
			$flags .= '.com';
		}
		elsif ($pos =~ m/gnt="y"/) {
			$flags .= '.gen';
		}
		else {
			$flags .= '.dat';
		}
		if ($lemmapos eq 'V') {
			$my_pos = 'vblex';
			$flags = "ger.$flags";
		}
		print "$lemma; $surface; $flags; $my_pos\n";
	}
	elsif ($pos =~ m/^<V/) {  # don't forget copula
		$my_pos = 'vblex';
		if ($pos =~ m/cop="y"/ or $lemma eq 'feadra�s') {
			next;
		}
		else {
	         # ignoring p="[y|n]" now, use endings
			if ($pos =~ m/t="ord"/) {
				$flags = 'imp';
				if ($surface eq $lemma) {
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
				}
				elsif ($surface =~ m/[i�]m$/ or $surface eq 't�anam') {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
				}
				elsif ($surface =~ m/dh$/) {
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
				}
				elsif ($surface =~ m/te?ar$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				elsif ($surface =~ m/mis$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				elsif ($surface =~ m/g�$/) {
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
				}
				elsif ($surface =~ m/d�s$/) {
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
				else {
					print STDERR "Fadhb le foirm $surface\n";
				}
			}
			elsif ($pos =~ m/t="l�ith"/) {
				$flags = 'pres';
				if ($surface =~ m/nn$/ or $surface eq 'deir') {
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
				elsif ($surface =~ m/te?ar$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				elsif ($surface =~ m/m$/) {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
				}
				elsif ($surface =~ m/mid$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				else {
					print STDERR "Fadhb le foirm $surface\n";
				}
			}
			elsif ($pos =~ m/t="coinn"/) {
				$flags = 'cni';
				if ($surface =~ m/inn$/) {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
				}
				elsif ($surface =~ m/fe?�$/) {
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
				}
				elsif ($surface =~ m/dh$/) {
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
				}
				elsif ($surface =~ m/fa?�$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				elsif ($surface =~ m/imis$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				elsif ($surface =~ m/id�s$/) {
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
				else {
					print STDERR "Fadhb le foirm $surface\n";
				}
			}
			elsif ($pos =~ m/t="gn�th"/) {
				$flags = 'pii';
				if ($surface =~ m/nn$/) {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
				}
				elsif ($surface =~ m/te?�$/) {
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
				}
				elsif ($surface =~ m/dh$/) {
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
				}
				elsif ($surface =~ m/ta?�$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				elsif ($surface =~ m/mis$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				elsif ($surface =~ m/d�s$/) {
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
				else {
					print STDERR "Fadhb le foirm $surface\n";
				}
			}
			elsif ($pos =~ m/t="f�ist"/) {
				$flags = 'fti';
				if ($surface =~ m/mid$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				elsif ($surface =~ m/fe?ar$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				elsif ($surface =~ m/idh$/) {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
				else {
					print STDERR "Fadhb le foirm $surface\n";
				}
			}
			elsif ($pos =~ m/t="caite"/) {
				$flags = 'past';
				if ($surface =~ m/mar$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				elsif ($surface =~ m/dar$/) {
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
				elsif ($surface =~ m/dh$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				else {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
				}
			}
			elsif ($pos =~ m/t="foshuit"/) {
				$flags = 'prs';
				if ($surface =~ m/mid$/) {
					print "$lemma; $surface; $flags.p1.pl; $my_pos\n";
				}
				elsif ($surface =~ m/te?ar$/) {
					print "$lemma; $surface; $flags.aut; $my_pos\n";
				}
				else {
					print "$lemma; $surface; $flags.p1.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p3.sg; $my_pos\n";
					print "$lemma; $surface; $flags.p2.pl; $my_pos\n";
					print "$lemma; $surface; $flags.p3.pl; $my_pos\n";
				}
			}
		}
	}
	elsif ($pos =~ m/^<A/) {
		$my_pos = 'adj';
		if ($pos =~ m/gnt="y"/) {
			if ($pos =~ m/gnd="m"/) {
				$flags = 'm';
			}
			elsif ($pos =~ m/gnd="f"/) {
				$flags = 'f';
			}
			$flags .= '.sg.gen';
		}
		elsif ($pos =~ m/pl="y"/) {
			$flags = 'pl';
		}
		else {
			$flags = 'sg';
		}
		if ($lemmapos eq 'V') {
			$my_pos = 'vblex';
			$flags = "pp.$flags";
		}
		print "$lemma; $surface; $flags; $my_pos\n";
	}
#	elsif ($pos =~ m/^<R/) {
#		$my_pos = 'adv';
#	}
#	elsif ($pos =~ m/^<S/) {
#		$my_pos = 'pr';
#	}
#	elsif ($pos =~ m/^<P/) {
#		$my_pos = 'prn';
#	}
#	elsif ($pos =~ m/^<T/) {
#		$my_pos = 'det';
#	}
#	elsif ($pos =~ m/^<I/) {
#		$my_pos = 'ij';
#	}
	else {
		next;  # <O>, <C>, <D>, <U>, <Q>
	}
}
exit 0;
