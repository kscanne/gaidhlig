INSTALL=/usr/bin/install
SHELL=/bin/sh
MAKE=/usr/bin/make
INSTALL_DATA=$(INSTALL) -m 444
GRAM=${HOME}/gaeilge/gramadoir/gr

all : cuardach.txt aistrigh ga2gd rialacha.txt disambig.pl ambig.txt gdfixer apertium-ga-gd.ga.dix

# Note "caighdean" package installed separately
# The dependencies listed here, plus disambig/*.dat, a README, Copyright, etc.
# are all that is needed for a ga2gd tarball
install : all
	$(INSTALL) aistrigh /usr/local/bin
	$(INSTALL) ga2gd /usr/local/bin
	$(INSTALL) gdfixer /usr/local/bin
	$(INSTALL) disambig.pl /usr/local/bin
	$(INSTALL_DATA) cuardach.txt /usr/local/share/ga2gd
	$(INSTALL_DATA) rialacha.txt /usr/local/share/ga2gd
	$(INSTALL_DATA) ambig.txt /usr/local/share/ga2gd
	rm -f /usr/local/share/ga2gd/disambig/*.dat
	cp -f ../traenail/*.dat /usr/local/share/ga2gd/disambig
	chmod 444 /usr/local/share/ga2gd/disambig/*.dat

add : FORCE
	cp -f focloir.txt focloir.txt.bak
	perl i.pl -f
	sort -t '_' -k1,1 -k2,2 focloir.txt > temp.txt
	mv -f temp.txt focloir.txt
	diff -u focloir.txt.bak focloir.txt | more

GD.txt : focloir.txt i.pl
	perl i.pl -g # writes "GD.txt"

lexicon-gd.txt : GD.txt
	cat GD.txt | sed '/^-$$/d' | LC_COLLATE=POSIX sort -u -k1,1 -k2,2n > $@
#	rest of the commands below are just informational - how much more of lextodo.txt is left?
	mv -f lextodo.txt lextodo.txt.bak
	cat lextodo.txt.bak | while read x; do TEMP=`echo $$x | sed 's/^\([^ ]*\) .*/^\1 /'`; if ! egrep "$$TEMP" lexicon-gd.txt > /dev/null; then echo $$x; fi; done > lextodo.txt
	diff -u lextodo.txt.bak lextodo.txt | more
	cat $@ | iconv -f utf8 -t iso-8859-1 > $(GRAM)/gd/$@
	(cd $(GRAM)/gd; make rebuildlex)


GA.txt : /home/kps/math/code/data/Dictionary/IG
	Gin 18 # writes "ga.txt"
	cat ga.txt | perl -p $(GRAM)/ga/posmap.pl | LC_ALL=C sed '/^xx /s/.*/xx 4/' | iconv -f iso-8859-1 -t utf8 > $@
	rm -f ga.txt

gd2ga.pot : focloir.txt
	(echo 'msgid ""'; echo 'msgstr ""'; echo '"Content-Type: text/plain; charset=UTF-8\\n"'; echo) > $@
	cat focloir.txt | egrep '0 *$$' | egrep -v '^[^_]+ ' | sed 's/^\([^_]*_[^ \t]*\).*/msgid "\1"\nmsgstr ""\n/' >> $@

ga2gd.pot : GA.txt
	(echo 'msgid ""'; echo 'msgstr ""'; echo '"Content-Type: text/plain; charset=UTF-8\\n"'; echo) > $@
	cat GA.txt | tr '\n' '@' | sed 's/-@/\n/g' | sed 's/@.*//' | egrep -v '^xx' | sort -k1,1 -k2,2n | uniq | perl ./tagcvt.pl ga | tr '"' "'" | LC_ALL=C sed 's/.*/msgid "&"\nmsgstr ""\n/' >> $@

gd2ga.po : gd2ga.pot
	msgmerge -N -q --backup=off -U $@ gd2ga.pot > /dev/null 2>&1
	touch $@

neamhrialta.pot : GA.txt
	(echo 'msgid ""'; echo 'msgstr ""'; echo '"Content-Type: text/plain; charset=UTF-8\\n"'; echo) > $@
	cat GA.txt | tr '\n' '@' | sed 's/-@/\n/g' | egrep '^xx ' | tr '@' '\n' | egrep -v '^xx ' | egrep ' ' | sort -k1,1 -k2,2n | uniq | perl ./tagcvt.pl ga | tr '"' "'" | sed 's/.*/msgid "&"\nmsgstr ""\n/' >> $@

FOINSE=$(GRAM)/ga/comhshuite-ga.in
comhshuite.pot : $(FOINSE)
	(echo 'msgid ""'; echo 'msgstr ""'; echo '"Content-Type: text/plain; charset=UTF-8\\n"'; echo) > $@
	cat $(FOINSE) | iconv -f iso-8859-1 -t utf8 | perl ./saorog.pl | tr '"' "'" | LC_ALL=C sed 's/.*/msgid "&"\nmsgstr ""\n/' >> $@ 

ga2gd.po : ga2gd.pot
	msgmerge -N -q --backup=off -U $@ ga2gd.pot > /dev/null 2>&1
	touch $@

neamhrialta.po : neamhrialta.pot
	msgmerge -N -q --backup=off -U $@ neamhrialta.pot > /dev/null 2>&1
	touch $@

comhshuite.po : comhshuite.pot
	msgmerge -N -q --backup=off -U $@ comhshuite.pot > /dev/null 2>&1
	touch $@

stemmer.pot : neamhrialta.pot comhshuite.pot
	(cat neamhrialta.pot; egrep '[^</][A-ZÁÉÍÓÚ]' comhshuite.pot | egrep -v 'Content-Type' | LC_ALL=C sed 's/.*/&\nmsgstr ""\n/') > $@

stemmer.po : stemmer.pot
	msgmerge -N -q --backup=off -U $@ stemmer.pot > /dev/null 2>&1
	touch $@

CCGG=${HOME}/gaeilge/ga2gd/ccgg
searchable.txt: ga2gd.po
	cat ga2gd.po neamhrialta.po comhshuite.po | egrep -v '^#~' | tr -d "\n" | sed 's/msgid/\n&/g' | egrep -v 'msg(id|str) ""' | sed 's/^msgid "<[^>]*>//' | sed 's/"#.*/"/' | sed 's/^\([^<]*\)<\/.>"msgstr "\([^"]*\)"/\2\t\1/' | sed 's/_\([a-z]*\)/ (\1)/' > $@
	cat $@ | sed 's/\t.*//' | egrep -n '^' | sed 's/:/: /' > $(CCGG)/ga2gd-b
	cat $@ | sed 's/.*\t//' | egrep -n '^' | sed 's/:/: /' > $(CCGG)/ga2gd

# creates a list of ambiguous words for disambig.pl to loop over and check for
ambig.txt : ga2gd.po
	perl showambig | egrep '^msgid' | sed 's/^msgid "//; s/"$$//' | tr "'" '"' > $@

# reads GA.txt also but ga2gd.po depends on that already
cuardach.txt : comhshuite.po neamhrialta.po ga2gd.po focloir.txt i.pl
	perl i.pl -t
	sed -i '/ xx$$/d' $@
	(sed '/^#/d' comhshuite.po neamhrialta.po | sed "/^msgid/{s/='/=@/g; s/' /@ /g; s/'>/@>/}" | tr '@' '"' | tr -d '\n' | sed 's/msgid "/\n/g' | egrep '>"msgstr' | egrep -v 'msgstr ""' | sed 's/"msgstr "/ /; s/"$$//'; cat cuardach.txt | egrep -v '> x$$' | egrep -v '> xx ' | egrep -v '>xx<') | sort -t '>' -k2,2 | uniq > temp.txt
	mv -f temp.txt $@

pairs-gd.txt: gd2ga.po focloir.txt GA.txt i.pl
	perl i.pl -s
	sed '/ xx$$/d' $@ | LC_ALL=C sort -u | LC_ALL=C sort -k1,1 > temp.txt
	mv -f temp.txt $@

lookup.txt : cuardach.txt i.pl
	perl i.pl -t 2>&1 | sort -t ':' -k1,1 > $@

# Using mcneir list now
#CRUB=/usr/local/share/crubadan/gd
#GLAN-update : lexicon-gd.txt FORCE
#	cat lexicon-gd.txt | sed 's/ .*//' | LC_ALL=ga_IE sort -u | iconv -f iso-8859-1 -t utf8 > $(CRUB)/GLAN
#	cp $(CRUB)/GLAN $(CRUB)/LEXICON
#	togail gd glan 20

fullstem.txt : GA.txt
	cat GA.txt | tr '\n' '@' | sed 's/-@/\n/g' | egrep -v '^xx' | perl -p -e 'chomp; ($$hd) = /([^@]+)/; s/@/ $$hd\n/g' | egrep -v '^xx' | sort -u | perl ./tagcvt.pl ga | sort -u > $@

fullstem-gd.txt : GD.txt
	cat GD.txt | tr '\n' '@' | sed 's/-@/\n/g' | egrep -v '^xx' | perl -p -e 'chomp; ($$hd) = /([^@]+)/; s/@/ $$hd\n/g' | egrep -v '^x[ x]' | sort -u | perl ./tagcvt.pl gd | sort -u > $@

all-gd.txt: GD.txt
	cat GD.txt | egrep -v '^xx ' | egrep -v -- '^-$$' | sed 's/ [0-9]*$$//' | LC_ALL=C sort -u > $@

fullstem-nomutate.txt : fullstem.txt
	cat fullstem.txt | sed '/ t="\(caite\|coinn\|gnáth\|foshuit\)"/s/">\(.\)h\([^Ff]\)/">\1\2/' | egrep -v '<F>' | egrep -v ">.[A-ZÁÉÍÓÚh'-]" | egrep -v '>(m[Bb]|g[Cc]|n[DdGg]|b[Pp]|t[Ss]|d[Tt])' | egrep -v 'h="y"' | egrep -v 't="ord">h.*>[aeiouáéíóú]' > $@

fullstem-nomutate-gd.txt : fullstem-gd.txt
	cat fullstem-gd.txt | egrep -v ">.[h']" | egrep -v ">[th]-" > $@

speling-ga.txt : fullstem-nomutate.txt
	cat fullstem-nomutate.txt | perl tospeling.pl > $@

apertium-toinsert.txt : speling-ga.txt
	python ${HOME}/seal/apertium/apertium/apertium-tools/speling/speling-paradigms-py25.py speling-ga.txt > tempdic
	python ${HOME}/seal/apertium/apertium/apertium-tools/speling/paradigm-chopper.py tempdic 1line > $@
	rm -f tempdic
	sed -i '1,3d' $@
	sed -i '/^  <\/section>$$/d' $@
	sed -i '/^<\/dictionary>$$/d' $@
	sed -i '/__\(n_[mf]\|vblex\|adj\)"/s/"><i>\([aAáÁbBcCdDeEéÉfFgGiIíÍmMoOóÓpPtTuUúÚ]\)/"><par n="initial-\1"\/><i>/' $@
	sed -i '/__\(n_[mf]\|vblex\|adj\)"/s/"><i>\([sS]\)\([aeiouáéíóúlnr]\)/"><par n="initial-\1"\/><i>\2/' $@

apertium-ga-gd.ga.dix : apertium-toinsert.txt apertium-ga-gd.ga.dix.in
	sed '/Insert Here -->/r apertium-toinsert.txt' apertium-ga-gd.ga.dix.in > $@
	cp apertium-ga-gd.ga.dix ~/seal/apertium/incubator/apertium-ga-gv/apertium-ga-gv.ga.dix

speling-gd.txt : fullstem-nomutate-gd.txt
	cat fullstem-nomutate-gd.txt | perl tospeling-gd.pl > $@

Lingua-GA-Stemmer/share/stemmer.txt : GA.txt Lingua-GA-Stemmer/scripts/stemmer fullstem.txt
	(sed '/^#/d' stemmer.po | sed "/^msg/{s/='/=@/g; s/' /@ /g; s/'>/@>/}" | tr '@' '"' | tr -d '\n' | sed 's/msgid "/\n/g' | egrep '>"msgstr' | egrep -v 'msgstr ""' | sed 's/"msgstr "/ /; s/"$$//'; cat fullstem.txt) | sort -u > $@
	perl -I Lingua-GA-Stemmer/lib Lingua-GA-Stemmer/scripts/stemmer -p $@
	(cd Lingua-GA-Stemmer; perl Makefile.PL; make)

triailcheck : FORCE
	cat test.txt | sed '/^#/d' | ga2gd > torthai-nua.txt
	vimdiff torthai.txt torthai-nua.txt
	rm -f torthai-nua.txt

torthai.txt-update : FORCE
	rm -f torthai.txt
	cat test.txt | sed '/^#/d' | ga2gd > torthai.txt

clean :
	rm -f GA.txt GD.txt *.bak *.pot messages.mo lookup.txt cuardach.txt lexicon-gd.txt ambig.txt fullstem.txt fullstem-gd.txt fullstem-nomutate*.txt speling*.txt apertium-toinsert.txt apertium-ga-gd.ga.dix torthai-nua.txt

distclean :
	$(MAKE) clean

.PRECIOUS : ga2gd.po

FORCE :
