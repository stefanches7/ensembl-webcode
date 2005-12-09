#!/bin/sh

#
# This script generates a shell script and linking config files which are used
# to generate the 'pdoc' perl documentation.
#
# These scripts are generated in the P2WDOC_LOC directory defined below.
#
# The actual Pdoc software can be obtained from: 
# 	http://sourceforge.net/projects/pdoc
# or by:
#	cvs -d:pserver:anonymous@cvs.pdoc.sourceforge.net:/cvsroot/pdoc login
#
#	When prompted for the password, press 'Enter' key, then type:
#
#	cvs -z3 -d:pserver:anonymous@cvs.pdoc.sourceforge.net:/cvsroot/pdoc
#		co pdoc-live
#
# or contact Raphael Leplae (used to work at Sanger): lp1@sanger.ac.uk
#
#
# To generate the Pdocs, edit the variables below, and then run this script.  
# It will generate a script called make_html_docs.sh and a number of files (one
# for each Fnumber set of perl modules) which contain cross-linking information.#
# This script will change to P2QDOC_LOC and run the make_html_docs.sh script
# The Pdocs will be generated in the PDOC_LOC directory.  
# This script will mkdir each of the Fnumber directories in the PDOC_LOC 
# directory first: e.g. mkdir PDOC_LOC/bioperl-live, etc.
#
# jws 2002-01-08
#
# fc1 2005-10-21 edits

. /etc/profile

PERLMOD_LOC="/ensemblweb/www/www_37"   # current server root
#PERLMOD_LOC="/ensemblweb/www/server"   # current server root

PDOC_LOC="$PERLMOD_LOC/htdocs/info/software/Pdoc"    # where you want Pdocs created
HTTP="/info/software/Pdoc"
P2WDOC_LOC="/ensemblweb/shared/bin/pdoc-live"  # Pdoc code location
P2WDOCER="/ensemblweb/shared/bin/pdoc-live/perlmod2www.pl"


F1=bioperl-live
F2=ensembl
F3=ensembl-analysis
F4=ensembl-compara
F5=ensembl-draw
F6=ensembl-external
F7=ensembl-pipeline
F8=ensembl-variation
F9=perl
F10=biomart-web
F11=biomart-plib
F12=public-plugins
F13=modules
F14=conf

rm -f $P2WDOC_LOC/make_html_docs.*

cd $PERLMOD_LOC
(
  echo "#!/bin/sh"
  echo "# Script to generate HTML version of PERL docs using perlmod2www.pl"
  echo "# This script has been automatically generated by create_perl_to_html.sh"
) > $P2WDOC_LOC/make_html_docs.sh

echo "Check out ensembl-pipeline and ensembl analysis"
cvs co ensembl-pipeline ensembl-analysis

for i in bioperl-live ensembl ensembl-analysis ensembl-compara ensembl-draw ensembl-external ensembl-variation perl modules conf biomart-web biomart-plib public-plugins ensembl-pipeline
do
        mkdir $PDOC_LOC/$i
  	echo "CURRENT MODULE: $i"
  	echo "#CURRENT MODULE: $i" >> $P2WDOC_LOC/make_html_docs.sh 
 	echo "$P2WDOCER -source $PERLMOD_LOC/$i -target $PDOC_LOC/$i -raw -webcvs http://cvsweb.sanger.ac.uk/cgi-bin/cvsweb.cgi/$i/ -xltable $P2WDOC_LOC/$i.xlinks " >> $P2WDOC_LOC/make_html_docs.sh

  	echo "$PERLMOD_LOC/$F1 $HTTP/$F1
$PERLMOD_LOC/$F2 $HTTP/$F2
$PERLMOD_LOC/$F3 $HTTP/$F3
$PERLMOD_LOC/$F4 $HTTP/$F4
$PERLMOD_LOC/$F5 $HTTP/$F5
$PERLMOD_LOC/$F6 $HTTP/$F6
$PERLMOD_LOC/$F7 $HTTP/$F7
$PERLMOD_LOC/$F8 $HTTP/$F8
$PERLMOD_LOC/$F9 $HTTP/$F9
$PERLMOD_LOC/$F10 $HTTP/$F10
$PERLMOD_LOC/$F11 $HTTP/$F11
$PERLMOD_LOC/$F12 $HTTP/$F12
$PERLMOD_LOC/$F13 $HTTP/$F13
$PERLMOD_LOC/$F14 $HTTP/$F14
" > $P2WDOC_LOC/xlinks.pre
	perl -n -e "print unless m#$PERLMOD_LOC/$i $HTTP/$i#;" < $P2WDOC_LOC/xlinks.pre >$P2WDOC_LOC/$i.xlinks

done

(
	echo "echo \"About to tidy-up the html files\""
	echo "cd $PDOC_LOC"
	echo "for i in \`/usr/bin/find . -name \"*.html\" -type f\`"
	echo "do"
	echo "perl -i -p -e 'print \"<!--#set var=\\\"decor\\\" value=\\\"none\\\"-->\" if $.==1;s#http://www.ensembl.org##g;' \$i"
	echo "done"
	echo "echo \"done\""
) >> $P2WDOC_LOC/make_html_docs.sh

chmod 755 $P2WDOC_LOC/make_html_docs.sh
rm $P2WDOC_LOC/xlinks.pre

# Running big pdoc script
echo "Running $P2WDOC_LOC/make_html_docs.sh";
cd $P2WDOC_LOC
./make_html_docs.sh

echo "Deleting generated index $PDOC_LOC/index.html file in favour of cvs version"
cd $PDOC_LOC
rm index.html
cvs -q up 

# cd back into server root directory:
echo "Change back to server root directory";
cd $PERLMOD_LOC

exit 0
