#!/bin/sh

[ -d doc ] || mkdir doc
[ -d html ] || mkdir html

index=html/index.html

podpath=--podpath=.:Beyonwiz

# Header for index.html

cat > $index << '_EOF'
<html>
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
   <title>BWFWTools documentation</title>
<link rev="made" href="mailto:Peter.Lamb@dit.csiro.au">
</head>
<body>
  <h1>BWFWTools documentation</h1>
  <dir>
_EOF

for i in "$@"; do

    # Get the basename, whether it's a .pl or .pm file

    j=`basename $i .pl`
    j=`basename $j .pm`
    echo $j;

    d=`dirname $i`
    [ -d html/$d ] || mkdir -p html/$d

    # Extract the synopsis line for index.html

    synopsis=`sed -n \
	-e '/=head1 NAME/,/=head1 SYNOPSIS/{
	        /^[^=]/p
	    }' \
	    $i`

    # Convert the Perl POD markup to HTML
    pod2html --htmlroot=.. --podroot=. $podpath --htmldir=. \
             --header --title=$j \
             --infile=$i > html/$d/$j.html
    # Add a line to index.html
    echo "<li><a href=\"$j.html\">$synopsis</li>" >> $index

    # Convert the Perl POD markup to plain text with DOS line separators
    pod2text --loose $i | perl -ape 's/\n/\r\n/ if(!/\r\n$/)' > doc/$j.txt

done

# Header for index.html

cat >> $index << '_EOF'
  </dir>
</body>
</html>
_EOF

# Tidy up

rm -f pod2htmd.tmp pod2htmi.tmp
