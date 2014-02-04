#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode;
use Locale::PO;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# GD lexicon manager.  Not part of the ga2gd runtime distribution;
# just used for maintaining critical "cuardach.txt" bilingual lexicon

# TODO: option to output gramadoir-gd eile-gd.bs pairs...
if ($#ARGV != 0) {
	die "Usage: $0 [-f|-g|-s|-t|-u]\n-f: Manual additions to focloir.txt\n-g: Write GD.txt, essentially same as gramadoir lexicon-gd.txt\n-s: Write gd2ga lexicon pairs-gd.txt\n-t: Write ga2gd lexicon cuardach.txt\n";
}

my %lexicon;
my %standard;
my %freq;

sub dhorlenite
{
	my ( $word ) = @_;
	$word = lenite($word);
	$word =~ s/^([aeiouàèìòùAEIOUÀÈÌÒÙ]|[Ff]h[aeiouàèìòù])/dh'$1/;
	return $word;
}

sub lenite
{
	my ( $word ) = @_;
	$word =~ s/^([bcdfgmptBCDFGMPT])([^h'-])/$1h$2/;
	$word =~ s/^([Ss])([lnraeiouàèìòù])/$1h$2/;
	return $word;
}

sub prefixm
{
	my ( $word ) = @_;
	$word =~ s/^([aeiouàèìòùAEIOUÀÈÌÒÙ])/m'$1/;
	return $word;
}

sub prefixd
{
	my ( $word ) = @_;
	$word =~ s/^([aeiouàèìòùAEIOUÀÈÌÒÙ])/d'$1/;
	return $word;
}

sub prefixb
{
	my ( $word ) = @_;
	$word =~ s/^([aeiouàèìòùAEIOUÀÈÌÒÙ])/b'$1/;
	return $word;
}

sub prefixh
{
	my ( $word ) = @_;
	$word =~ s/^([aeiouàèìòùAEIOUÀÈÌÒÙ])/h-$1/;
	return $word;
}

sub prefixt
{
	my ( $word, $code ) = @_;
	if ($code eq '76') {
		$word =~ s/^([aeiouàèìòùAEIOUÀÈÌÒÙ])/t-$1/;
	}
	if ($code eq '72' or $code eq '92') {
		$word =~ s/^([Ss][aeiouàèìòùlnr])/t-$1/;
	}
	return $word;
}

sub slenderize
{
	my ( $word ) = @_;

	if ($word =~ m/ea[^aeiouàèìòù]+$/) {
		if ($word =~ m/ea(?:nn|[cd]h)$/) {
			$word =~ s/ea([^aeiouàèìòù]+)$/i$1/;
		}
		else {
			$word =~ s/ea([^aeiouàèìòù]+)$/ei$1/;
		}
	}
	else {
		$word =~ s/([aouàòù])([^aeiouàèìòù]+)$/$1i$2/;
	}

	return $word;
}

sub imperative
{
	my ( $word, $root, $i, $n ) = @_;

	if ($n == 2 and $i == 1) {   # bithibh should be OK
		if ($root eq 'their') {
			$root = 'abraibh';   # irreg
		}
		elsif ($root eq 'cith') {
			$root = 'faicibh';   # irreg
		}
		elsif ($root eq 'gheibh') {
			$root = 'faighibh';   # irreg
		}
		elsif ($root =~ m/([aouàòù][^aeiouàèìòù]+)$/) {
			$root =~ s/([aouàòù][^aeiouàèìòù]+)$/$1aibh/;
		}
		else {
			$root =~ s/([eèiì][^aeiouàèìòù]+)$/$1ibh/;
		}
		return $root;
	}
	else {
		return $word;
	}

}

sub future
{
	my ( $root, $i, $n ) = @_;

	if ($root eq 'their' or $root eq 'gheibh' or $root eq 'thig') {
		1;  # do nothing, not "theiridh"!
	}
	elsif ($root eq 'bith') {
		$root = 'bidh';
		# default would be bithidh which is a legit 
		# future of "bi"
	}
	elsif ($root eq 'dèan') {
		$root = 'nì';
	}
	elsif ($root eq 'cith') {
		$root = 'chì';
	}
	elsif ($root eq 'rach') {
		$root = 'thèid';
	}
	elsif ($root eq 'toir') {
		$root = 'bheir';
	}
	elsif ($root =~ m/([aouàòù][^aeiouàèìòù]+)$/) {
		$root =~ s/([aouàòù][^aeiouàèìòù]+)$/$1aidh/;
	}
	else {
		$root =~ s/([eèiì][^aeiouàèìòù]+)$/$1idh/;
	}

	return $root;
	
}

# bi =>  bhithinn/bhitheamaid ok, but stick with 'bhiodh' for 2nd/3rd
sub conditional
{
	my ( $root, $i, $n ) = @_;
	if ($n == 1) {
		if ($i == 0) {
			if ($root =~ m/([aouàòù][^aeiouàèìòù]+)$/) {
				$root =~ s/([aouàòù][^aeiouàèìòù]+)$/$1ainn/;
			}
			else {
				$root =~ s/([eèiì][^aeiouàèìòù]+)$/$1inn/;
			}
		}
		else {
			if ($root =~ m/([aouàòù][^aeiouàèìòù]+)$/) {
				$root =~ s/([aouàòù][^aeiouàèìòù]+)$/$1amaid/;
			}
			else {
				$root =~ s/([eèiì][^aeiouàèìòù]+)$/$1eamaid/;
			}
		}
	}
	else {
		if ($root eq 'bith') {
			$root = 'biodh';
		}
		elsif ($root =~ m/([aouàòù][^aeiouàèìòù]+)$/) {
			$root =~ s/([aouàòù][^aeiouàèìòù]+)$/$1adh/;
		}
		else {
			$root =~ s/([eèiì][^aeiouàèìòù]+)$/$1eadh/;
		}
	}

	return dhorlenite($root);
}

sub past
{
	my ( $word ) = @_;
	if ( $word eq 'abair' ) {
		$word = 'thubhairt';
	}
	elsif ( $word eq 'bi' ) {
		$word = 'bha';
	}
	elsif ($word eq 'beir') {
		$word = 'rug';
	}
	elsif ($word eq 'cluinn') {
		$word = 'chuala';
	}
	elsif ($word eq 'dèan') {
		$word = 'rinn';
	}
	elsif ($word eq 'faic') {
		$word = 'chunnaic';
	}
	elsif ($word eq 'faigh') {
		$word = 'fhuair';
	}
	elsif ($word eq 'rach') {
		$word = 'chaidh';
	}
	elsif ($word eq 'ruig') {
		$word = 'ràinig';
	}
	elsif ($word eq 'tabhair') {
		$word = 'thug';
	}
	elsif ($word eq 'thig') {
		$word = 'thàinig';
	}
	else {
		$word = dhorlenite($word);
	}

	return $word;
}

sub default_pp
{
	my ( $word ) = @_;
	if ($word =~ /([aouàòù])([^aeiouàèìòù]+)$/) {
		$word =~ s/$/ta/;
	}
	elsif ($word =~ /([eièì])([^aeiouàèìòù]+)$/) {
		$word =~ s/$/te/;
	}
	return $word;
}

sub default_verbal_root
{
	my ( $word ) = @_;
	return $word;
}

# unlike others, attaches _nm at end
sub default_vn
{
	my ( $word ) = @_;
	if ($word =~ /aich$/) {
		$word =~ s/ich$/chadh_nm/;
	}
	elsif ($word =~ /ich$/) {
		$word =~ s/ich$/eachadh_nm/;
	}
	elsif ($word =~ /([aouàòù])([^aeiouàèìòù]+)$/) {
		$word =~ s/$/adh_nm/;
	}
	elsif ($word =~ /([eièì])([^aeiouàèìòù]+)$/) {
		$word =~ s/$/eadh_nm/;
	}
	return $word;
}

sub default_plural_adj
{
	my ( $word ) = @_;
	unless ($word =~ m/[aeiouàèìòù][^aeiouàèìòù]+[aeiouàèìòù]/) {
		if ($word =~ m/[aouàòù][^aeiouàèìòù]+$/) {
			$word =~ s/$/a/;
		}
		elsif ($word =~ m/i[^aeiouàèìòù]+$/) {
			$word =~ s/$/e/;
		}
		
	}
	return $word;
}

sub default_gsm
{
	my ( $word ) = @_;
	return slenderize($word);
}

sub default_gsf
{
	my ( $word ) = @_;
	$word = slenderize($word);
	$word =~ s/([^aeiouàèìòù])$/$1e/;
	return $word;
}

sub default_plural
{
	my ( $word ) = @_;

	if ($word =~ m/iche$/) {
		$word =~ s/$/an/;
	}
	elsif ($word =~ m/[aeiouàèìòù]$/) {
		$word = 'x';
		# or +an, but mostly seem abstract
	}
	elsif ($word =~ m/achd$/) {
		$word = 'x';
	}
	elsif ($word =~ m/eadh$/) {
		$word =~ s/adh$/idhean/;
	}
	elsif ($word =~ m/[^e]adh$/) {
		$word =~ s/dh$/idhean/;
	}
	elsif ($word =~ m/each$/) {
		$word =~ s/each$/ich/;
	}
	elsif ($word =~ m/[^e]ach$/) {
		$word =~ s/ach$/aich/;
	}
	elsif ($word =~ m/[aouàòù][^aeiouàèìòù]+$/) {
		$word =~ s/$/an/;
	}
	else {
		$word =~ s/$/ean/;	
	}
	return $word;

}

sub default_gen
{
	my ( $word ) = @_;

	if ($word =~ m/[aeiouàèìòù]$/) {
		1;
	}
	elsif ($word =~ m/chd$/) {
		1;
	}
	elsif ($word =~ m/[aouàòù][^aeiouàèìòù]+$/) {
		$word = slenderize($word);
	}
	elsif ($word =~ m/air$/) {
		1;
	}
	else {
		$word =~ s/$/e/;	
	}
	return $word;

}

# 5/12/05 returns reference to an array
# 5/23/05; potentially $arg is multiword phrase ("port adhair") 
#  in which case the first word is inflected and the remainder
#  is tacked on to the result
#  First arg is a gd word as it appears in focloir.txt or in msgstr
#  of ga2gd.po; e.g. "athchuinge_nf"; can have spaces too: "aisig air ais_v"
#  Second arg is usually false; but true if this function is called
#  recursively on the verbal noun of a verb
sub gramadoir_output {

	my ( $arg, $constit_p ) = @_;
	(my $word, my $pos) = $arg =~ m/^([^_]+)_(\S+)$/;
	unless (exists($lexicon{$arg})) {
		print STDERR "Gramadoir output failed for $arg... this should not happen!\n";
		return [];
	}
	my $ret = [];
	my $data = $lexicon{$arg};
	my $tail = '';
	($tail) = $arg =~ /( [^_]+)/ if ($arg =~ m/ /);
	$word =~ s/ .*//;
	# nouns: 8 nom sing, 7 gen sin, 8 nom pl, 7 gen pl = 30
	if ($pos =~ /^n[mf]/) {
		(my $gencode, my $plcode) = $data =~ m/^([^\t]+)\t+(.+)$/;
		my $nomnum = 72;
		my $gennum = 88;
		my $plnum = 104;
		my $genplnum = 120;
		if ($pos eq 'nm') {
			$nomnum += 4;
			$gennum += 4;
			$plnum += 4;
			$genplnum += 4;
		}

		push @$ret, "$word$tail $nomnum";
		push @$ret, lenite($word)."$tail $nomnum";
		push @$ret, "$word$tail $nomnum";
		push @$ret, prefixm($word)."$tail $nomnum";
		push @$ret, prefixd($word)."$tail $nomnum";
		push @$ret, prefixb($word)."$tail $nomnum";
		push @$ret, prefixh($word)."$tail $nomnum";
		push @$ret, prefixt($word,$nomnum)."$tail $nomnum";
		if ($gencode eq '0') {
			$gencode = default_gen($word);
		}
		push @$ret, $gencode."$tail $gennum";
		push @$ret, lenite($gencode)."$tail $gennum";
		push @$ret, "$gencode$tail $gennum";
		push @$ret, prefixm($gencode)."$tail $gennum";
		push @$ret, prefixd($gencode)."$tail $gennum";
		push @$ret, prefixh($gencode)."$tail $gennum";
		push @$ret, prefixt($gencode,$gennum)."$tail $gennum";
		if ($plcode eq '0') {
			$plcode = default_plural($word);
		}
		elsif ($plcode eq '1') {
			$plcode = 'xx';
			$plnum = 4;
			$genplnum = 4;
		}
		unless ($constit_p ) {
			push @$ret, "$plcode$tail $plnum";
			push @$ret, lenite($plcode)."$tail $plnum";
			push @$ret, "$plcode$tail $plnum";
			push @$ret, prefixm($plcode)."$tail $plnum";
			push @$ret, prefixd($plcode)."$tail $plnum";
			push @$ret, prefixb($plcode)."$tail $plnum";
			push @$ret, prefixh($plcode)."$tail $plnum";
			push @$ret, "$plcode$tail $plnum";
			push @$ret, "$plcode$tail $genplnum";
			push @$ret, lenite($plcode)."$tail $genplnum";
			push @$ret, "$plcode$tail $genplnum";
			push @$ret, prefixm($plcode)."$tail $genplnum";
			push @$ret, prefixd($plcode)."$tail $genplnum";
			push @$ret, prefixh($plcode)."$tail $genplnum";
			push @$ret, "$plcode$tail $genplnum";
		}
	}
	elsif ($pos eq 'n') {   # no gender, but lenited, etc.
		push @$ret, "$word$tail 64";
		push @$ret, lenite($word)."$tail 64";
		push @$ret, "$word$tail 64";
		push @$ret, prefixm($word)."$tail 64";
		push @$ret, prefixd($word)."$tail 64";
		push @$ret, prefixb($word)."$tail 64";
		push @$ret, prefixh($word)."$tail 64";
	}
	# adjs: 4 nom, 2 gsm, 3 gsf, 3 pl = 12 total
	elsif ($pos eq 'a') {
		(my $compcode, my $plcode) = $data =~ m/^([^\t]+)\t+(.+)$/;
		push @$ret, "$word$tail 128";
		push @$ret, lenite($word)."$tail 128";
		push @$ret, prefixb($word)."$tail 128";
		push @$ret, prefixh($word)."$tail 128";
		my $gsm = default_gsm($word);
		push @$ret, "$gsm$tail 156";
		push @$ret, lenite($gsm)."$tail 156";
		if ($compcode eq '0') {
			$compcode = default_gsf($word);
		}
		push @$ret, "$compcode$tail 152";
		push @$ret, lenite($compcode)."$tail 152";
		push @$ret, prefixb($compcode)."$tail 152";
		if ($plcode eq '0') {
			$plcode = default_plural_adj($word);
		}
		push @$ret, "$plcode$tail 160";
		push @$ret, lenite($plcode)."$tail 160";
		push @$ret, prefixb($plcode)."$tail 160";
	}
	elsif ($pos eq 'aindec') {
		push @$ret, "$word$tail 128" foreach (1..12);
	}
	elsif ($pos eq 'card' or $pos eq 'ord') {
		push @$ret, "$word$tail 128";
		push @$ret, lenite($word)."$tail 128";
		push @$ret, "$word$tail 128";
		push @$ret, prefixb($word)."$tail 128";
		push @$ret, prefixh($word)."$tail 128";
	}
	# verbs: 8 vn, 7 gen vn, 16 pp (5+3+4+4, see adj),
	# + 21 for each of 1st/2nd/3rd Sing/Pl + Aut, - 2 (no prefix h if 
	# 1st person imperative) => 7*21-2 = 145 verb forms, 176 total
	elsif ($pos eq 'v') {
		(my $vncode, my $rootcode) = $data =~ m/^([^\t]+)\t+(.+)$/;
		$rootcode = $word if ($rootcode eq '0');
		push @$ret, "$word$tail 200";  # extra thing added to Gin 18 output
		my $vnnum = 76;
		if ($vncode eq '0') {
			$vncode = default_vn($word);
			$vncode =~ s/_.*$//;
			push @$ret, "$vncode$tail 76";
			push @$ret, lenite($vncode)."$tail 76";
			push @$ret, "$vncode$tail 76";
			push @$ret, prefixm($vncode)."$tail 76";
			push @$ret, prefixd($vncode)."$tail 76";
			push @$ret, prefixb($vncode)."$tail 76";
			push @$ret, prefixh($vncode)."$tail 76";
			push @$ret, prefixt($vncode,76)."$tail 76";
			my $gencode = default_gen($vncode);
			push @$ret, $gencode."$tail 92";
			push @$ret, lenite($gencode)."$tail 92";
			push @$ret, "$gencode$tail 92";
			push @$ret, prefixm($gencode)."$tail 92";
			push @$ret, prefixd($gencode)."$tail 92";
			push @$ret, prefixh($gencode)."$tail 92";
			push @$ret, prefixt($gencode,92)."$tail 92";
		}
		else {  # irreg vn, so look up in lexicon
			# might have a tail, but want to generate forms before adding
			# the tail; see for example "aisig air ais_v", vn = "aiseag_nm"
			my $subret = gramadoir_output($vncode, 1);
			for my $f (@$subret) {
				$f =~ s/ ([0-9]+)$/$tail $1/;
				push @$ret, $f;
			}
			# and vncode, vnnum used below too...
			$vnnum = 72 if ($vncode =~ m/nf$/);
			$vncode =~ s/_.*$//;
		}
		#  16  pp's
		my $pp = default_pp($word);
		push @$ret, "$pp$tail 128";
		push @$ret, lenite($pp)."$tail 128";
		push @$ret, "$pp$tail 128";
		push @$ret, prefixb($pp)."$tail 128";
		push @$ret, prefixh($pp)."$tail 128";
		push @$ret, "$pp$tail 156";
		push @$ret, lenite($pp)."$tail 156";
		push @$ret, "$pp$tail 156";
		push @$ret, "$pp$tail 152";
		push @$ret, lenite($pp)."$tail 152";
		push @$ret, "$pp$tail 152";
		push @$ret, prefixb($pp)."$tail 152";
		push @$ret, "$pp$tail 160";
		push @$ret, lenite($pp)."$tail 160";
		push @$ret, "$pp$tail 160";
		push @$ret, prefixb($pp)."$tail 160";

		# now actual verb forms
		for (my $i=0; $i < 2; $i++) {
		  for (my $n=1; $n < 5; $n++) {
		  	unless ($n==4 and $i==0) {
				my $numer = 200;
				my $pron = '';
				$numer = 192 if ($n==4);
				# imperative
				my $w = imperative($word,$rootcode,$i,$n);	
		  		push @$ret, "$w$tail $numer";
		  		push @$ret, "$w$tail $numer";
		  		push @$ret, "$w$tail $numer";
		  		push @$ret, prefixh($w)."$tail $numer" unless ($n==1);
				# present
				$numer++;
		  		push @$ret, "$vncode $vnnum";
		  		push @$ret, "$vncode $vnnum";
		  		push @$ret, "$vncode $vnnum";
				# past
				$w = past($word);	
				$numer+=2;
				if ($n == 1 and $i == 1) {
					$pron = ' sinn';
				}
				elsif ($n == 3 and $i == 1) {
					$pron = ' iad';
				}
				else {
					$pron = '';
				}
		  		push @$ret, $w."$pron$tail $numer";
		  		push @$ret, $w."$pron$tail $numer";
		  		push @$ret, $w."$pron$tail $numer";
				# future
				$w = future($rootcode,$i,$n);	
				$numer++;
				if ($n == 1 and $i == 1) {
					$pron = ' sinn';
				}
				else {
					$pron = '';
				}
		  		push @$ret, "$w$pron$tail $numer";
		  		push @$ret, lenite($w)."$pron$tail $numer";
		  		push @$ret, "$w$pron$tail $numer";
				# imperfect
				$numer++;
		  		push @$ret, "$vncode $vnnum";
		  		push @$ret, "$vncode $vnnum";
		  		push @$ret, "$vncode $vnnum";
				# conditional
				$w = conditional($rootcode,$i,$n);	
				$numer++;
				if ($n == 2 and $i == 0) {
					$pron = ' tu';   # not "thu"
				}
				elsif ($n == 3 and $i == 1) {
					$pron = ' iad';
				}
				else {
					$pron = '';
				}
		  		push @$ret, "$w$pron$tail $numer";
		  		push @$ret, "$w$pron$tail $numer";
		  		push @$ret, "$w$pron$tail $numer";
				# subjunctive
				$numer++;
		  		push @$ret, "$vncode$tail $vnnum";
		  		push @$ret, "$vncode$tail $vnnum";
			}
		  }
		}
	}
	elsif ($pos eq 'vcop') {
		push @$ret, "$word$tail 194" for (1..177);
	}
	elsif ($pos eq 'pronm') {
		(my $emphcode, my $dummy) = $data =~ m/^([^\t]+)\t+(.+)$/;
		$emphcode='xx' if ($emphcode eq '0');
		push @$ret, "$word$tail 20";
		push @$ret, "$emphcode 22";
	}
	elsif ($pos eq 'art') {
		push @$ret, "$word$tail 8";
	}
	elsif ($pos eq 'prep') {
		push @$ret, "$word$tail 12";
	}
	elsif ($pos eq 'pn') {
		push @$ret, "$word$tail 16";
		push @$ret, "$word$tail 16";   # not sure why
	}
	elsif ($pos eq 'adv') {
		push @$ret, "$word$tail 24";
	}
	elsif ($pos eq 'conj') {
		push @$ret, "$word$tail 28";
	}
	elsif ($pos eq 'interr') {
		push @$ret, "$word$tail 32";
	}
	elsif ($pos eq 'excl') {
		push @$ret, "$word$tail 36";
	}
	elsif ($pos eq 'poss') {
		push @$ret, "$word$tail 40";
	}
	elsif ($pos eq 'u') {
		push @$ret, "$word$tail 1";
	}
	else {
		print STDERR "Unknown pos code\n";
	}
	return $ret;
}

sub userinput {
	my ($prompt) = @_;
	return '' if ($prompt =~ m/^dummy/);
	print "$prompt: ";
	$| = 1;          # flush
	$_ = getc;
	my $ans;
	while (m/[^\n]/) {
		$ans .= $_;
		$_ = getc;
	}
	return $ans;
}

sub get_prompt {
	my ($pos, $num) = @_;
	if ($pos =~ /^n[mf]/) {
		return "genitive" if ($num == 1);
		return "plural";
	}
	elsif ($pos eq 'a') {
		return "gsf" if ($num == 1);
		return "plural";
	}
	elsif ($pos eq 'v') {
		return "vn" if ($num == 1);
		return "root";
	}
	elsif ($pos eq 'pronm') {
		return "emphatic" if ($num == 1);
		return "dummy";
	}
	else {
		return "dummy";
	}
}

sub print_guesses {
	my ($newword) = @_;
	print "word=$newword\n";
	(my $word, my $pos) = $newword =~ /^([^_]+)_(\S+)$/;
	print "word=$word,pos=$pos\n";
	my $tail = '';
	($tail) = $word =~ /( [^_]+)/ if / /;
	$word =~ s/ .*//;
	if ($pos =~ /^n[fm]/) {
		my $guess = default_gen($word);
		my $f = $freq{$guess};
		$f = '0' unless defined $f;
		print "gen=$guess$tail ($f)\npl =";
		$guess = default_plural($word);
		$f = $freq{$guess};
		$f = '0' unless defined $f;
		print "$guess$tail ($f)\n";
	}
	elsif ($pos eq 'a') {
		my $guess = default_gsf($word);
		my $f = $freq{$guess};
		$f = '0' unless defined $f;
		print "gsf=$guess$tail ($f)\npl =";
		$guess = default_plural_adj($word);
		$f = $freq{$guess};
		$f = '0' unless defined $f;
		print "$guess$tail ($f)\n";
	}
	elsif ($pos eq 'v') {
		my $guess = default_vn($word);
		my $f = $freq{$guess};
		$f = '0' unless defined $f;
		print "vn=$guess$tail ($f)\nroot =";
		$guess = default_verbal_root($word);
		$f = $freq{$guess};
		$f = '0' unless defined $f;
		print "$guess$tail ($f)\n";
	}
	elsif ($pos eq 'pronm') {
		print "emph=NO GUESS\n";
	}
	elsif ($pos eq 'n' or $pos eq 'vcop' or $pos eq 'art' or $pos eq 'prep' or $pos eq 'pn' or $pos eq 'adv' or $pos eq 'conj' or $pos eq 'interr' or $pos eq 'excl' or $pos eq 'poss' or $pos eq 'u' or $pos eq 'aindec' or $pos eq 'card' or $pos eq 'ord') {
		1;  # no guesses for these
	}
	else {
		print STDERR "Unknown pos code\n";
		return 0;
	}
	return 1;
}

# updates global variables "lexicon" and possible "standard"
sub user_add_word
{
	my $newword=userinput('Enter a word_pos (q to quit)');
	if ($newword eq 'q') {
		return 0;
	}
	else {
		(my $pos) = $newword =~ m/^[^_]+_(.*)$/;
		if (print_guesses($newword)) {
			my $currone = '0';
			my $currtwo = '0';
			$currone=userinput(get_prompt($pos,1).' (<CR>=same, no spaces)');
			$currone='0' unless $currone;
			$currtwo=userinput(get_prompt($pos,2).' (<CR>=same,x=none,no spaces)');
			$currtwo='0' unless $currtwo;
			$currtwo='1' if ($currtwo eq 'x');
			$lexicon{$newword} = "$currone\t$currtwo";
			my $stnd=userinput('Alternate of (<CR>=nothing)');
			if (defined($stnd)) {
				$standard{$newword} = $stnd;
				print "Warning: standard form $stnd isn't in lexicon...\n" unless (exists($lexicon{$stnd}));
			}
		}
		return 1;
	}
}

sub write_focloir
{
	open (OUTDICT, ">:utf8", "focloir.txt") or die "Could not open dictionary: $!\n";
	foreach (sort keys %lexicon) {
		my $std = '0';
		$std = $standard{$_} if (exists($standard{$_}));
		print OUTDICT "$_\t".$lexicon{$_}."\t$std\n";
	}
	close OUTDICT;
}

my %tags;
sub read_tags
{
	open (POSTAGS, "<:bytes", "/home/kps/gaeilge/gramadoir/gr/ga/pos-ga.txt") or die "Could not open Irish pos tags list: $!\n";

	while (<POSTAGS>) {
		my $curr = decode("iso-8859-1", $_);
		$curr =~ m/^([0-9]+)\s+(<[^>]+>)/;
		$tags{$1} = $2;
	}

}

sub to_xml
{
	my ($input) = @_;
	$input =~ m/^(.+) ([0-9]+)/;
	my $tag = $tags{$2};
	my $ans = $tag.$1;
	$tag =~ s/<(.).*/<\/$1>/;
	return $ans.$tag;
}

my @allpos = qw/ a v n nm nf art pronm prep pn adv vcop conj interr excl poss u aindec card ord /;

# reads po file (filename first arg) into bilingual hash (hashref second arg)
sub read_po_file
{
	(my $pofile, my $bilingual) = @_;

	my $aref = Locale::PO->load_file_asarray($pofile);
	foreach my $msg (@$aref) {
		my $id = decode("utf8", $msg->msgid());
		my $str = decode("utf8",$msg->msgstr());
		if (defined($id) && defined($str)) {
			unless ($id eq '""' or $str eq '""') {
				$id =~ s/"//g;
				$str =~ s/"//g;
				(my $tag, my $rest) = $id =~ m/^(<[^>]+>)([^<]+<\/.>)$/;
				$tag =~ s/'/"/g;
				for my $aistriuchan (split (/;/,$str)) {
					next if ($aistriuchan eq '?');
					if (exists($lexicon{$aistriuchan})) {
						if (exists($bilingual->{$tag.$rest})) {
							$bilingual->{$tag.$rest} .= ";$aistriuchan";
						}
						else {
							$bilingual->{$tag.$rest} = $aistriuchan;
						}
						print STDERR "Warning: $aistriuchan is listed as an alternate form in focloir.txt\n" if (exists($standard{$aistriuchan}));
					}
					else {
						my $win='';
						foreach (@allpos) {
							if (exists($lexicon{$aistriuchan."_".$_})) {
								if ($win) {
									print STDERR "$aistriuchan is ambiguous ($win,$_) as translation of $rest: add a POS to msgstr!\n";
								}
								else {
									$win = $_;
								}
							}
						}
						if ($win) {
							if (exists($bilingual->{$tag.$rest})) {
								$bilingual->{$tag.$rest} .= ";$aistriuchan"."_$win";
							}
							else {
								$bilingual->{$tag.$rest} = $aistriuchan."_$win";
							}
						}
						else {
							print STDERR "$aistriuchan: given as xln of $rest; add to gd lexicon!!\n";
						}
					} # end "else not in lex"
				} # end loop over split/;/
			}
		}
	}
}

sub gd2ga_lexicon
{
}

sub ga2gd_lexicon
{
	# headwords only; keys on Irish side have XML markup, 
	# values on Scottish side look like focloir.txt headwords,
	# or else with _pos omitted if no ambiguity.
	my %bilingual;
	read_tags();
	read_po_file('ga2gd.po', \%bilingual);

	open (IGLEX, "<:utf8", "GA.txt") or die "Could not open Irish lexicon: $!\n";
	open (OUTLEX, ">:utf8", "cuardach.txt") or die "Could not open lexicon: $!\n";

	my $index=0;
	my $translated_p;
	my @allforms;  # array of arrayrefs; one for each transl (usually 1!)
	my $gd_count=0;
	my $headword_key='';
	while (<IGLEX>) {
		chomp;
		my $igline = $_;
		if ($igline eq '-') {
			if ($index < $gd_count and $translated_p) {
				print STDERR "Too many gd forms for $headword_key\n";
			}
			$index=0;
		}
		else {
			my $mykey = to_xml($igline);
			if ($index==0) {
				$translated_p = exists($bilingual{$mykey});
				if ($translated_p) {
					$headword_key = $mykey;	
					# all components of $bilingual{$mykey}
					# are guaranteed to be in lexicon hash:
					# see the read_po_file function above!
					$gd_count = -1;
					@allforms = ();
					for my $geedee (split /;/,$bilingual{$mykey}) {
						my $arrref=gramadoir_output($geedee, 0);
						push @allforms,$arrref;
						if ($gd_count != scalar @$arrref and $gd_count != -1) {
							print STDERR "Varying gd counts among the translations of $headword_key\n";
							
						}
						$gd_count = scalar @$arrref;
					}
				}
			}
			if ($translated_p) {
				if ($index == $gd_count) {
					print STDERR "Too many ga forms for $headword_key, gdtotal=$gd_count\n";
				}
				elsif ($index < $gd_count) {
					my $toshow = "$mykey ";
					for my $transls (@allforms) {
						my $thisgd = @$transls[$index];
						$thisgd =~ s/ [0-9]+$//;
						$toshow .= "$thisgd;";
					}
					$toshow =~ s/;$/\n/;
					print OUTLEX $toshow;
				}
			}
			$index++;
		}
	}

	close IGLEX;
	close OUTLEX;
}



#-#-#-#-#-#-#-#-#-#-#-#-#  START OF MAIN PROGRAM #-#-#-#-#-#-#-#-#-#-#-#-#-#

# focloir.txt is really a tsv; tabs separate four fields on
# each line; spaces allowed within a field
open (DICT, "<:utf8", "focloir.txt") or die "Could not open dictionary: $!\n";
while (<DICT>) {
	chomp;
	/^([^_]+_\S+)\t+(.+)\t+([^\t]+)$/;
	$lexicon{$1} = $2;
	$standard{$1} = $3 unless ($3 eq '0');
}
close DICT;

if ($ARGV[0] eq '-f') {
	open (FREQ, "<:utf8", '/usr/local/share/crubadan/gd/FREQ') or die "Could not open frequency file: $!\n";
	while (<FREQ>) {
		chomp;
		m/^ *([0-9]+) (.*)/;
		$freq{$2} = $1;
	}
	close FREQ;

	1 while (user_add_word());
	write_focloir();
}
elsif ($ARGV[0] eq '-g') {
	# does not currently include alternate forms
	# if using this for gramadoir-gd, would want those in eile-gd.bs
	open (OUTLEX, ">:utf8", "GD.txt") or die "Could not open lexicon: $!\n";
	foreach (sort keys %lexicon) {
		unless (/ / or exists($standard{$_})) {
			my $forms = gramadoir_output($_, 0);
			print OUTLEX "-\n";
			foreach (@$forms) {
				s/^([^ ]+) ([^ ]+) ([0-9]+)$/$1 $3/;  # strip pronouns
				print OUTLEX "$_\n";
			}
		}
	}
	close OUTLEX;
}
elsif ($ARGV[0] eq '-s') {
	gd2ga_lexicon();
}
elsif ($ARGV[0] eq '-t') {
	ga2gd_lexicon();
}
else {
	die "Unrecognized option: $ARGV[0]\n";
}

exit 0;
