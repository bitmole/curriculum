#!/bin/bash

# created 2023-01-14
# last modified 2023-02-15

# echo doing do-workbook-page.sh $1

adocfile=$1

fcontainingdirectory=$(dirname $adocfile)

containingdirectory=$(realpath --relative-to=$TOPDIR/distribution/$NATLANG $fcontainingdirectory)

lessondirectory=$(echo $containingdirectory|$SED -e 's#\(lessons/[^/]*\).*#\1#')

test -f distribution/$NATLANG/$lessondirectory/.proglang-ignore && exit

test -d $fcontainingdirectory/.cached || mkdir -p $fcontainingdirectory/.cached

distrootdir=$(realpath --relative-to=$fcontainingdirectory $TOPDIR/distribution/$NATLANG)/

adocbasename=$(basename $adocfile)

ascfile=$containingdirectory/.cached/.${adocbasename%.adoc}.asc

whtmlfile=$containingdirectory/${adocbasename%.adoc}.html

htmlfile=${ascfile%.asc}.html

otherdirarg="#f"

if $(echo $adocfile|grep -q '/\(fragments\|xtra\|xtras\)/'); then
  otherdirarg="#t"
fi

solutionsmodearg="#f"

if $(echo $adocfile|grep -q '/solution-pages/'); then
  solutionsmodearg="#t"
fi

lesson=$(echo $containingdirectory|$SED -e 's#lessons/\([^/]*\).*#\1#')

proglangarg="pyret"

if $(echo $lesson|grep -q '\-wescheme$'); then
  proglangarg=wescheme
elif $(echo $lesson|grep -q '\-codap$'); then
  proglangarg=codap
elif $(echo $lesson|grep -q '\-none$'); then
  proglangarg=none
elif $(echo $lesson|grep -q '\-spreadsheets$'); then
  proglangarg=spreadsheets
fi

echo "(\"$adocbasename\" #:containing-directory \"$containingdirectory\" #:dist-root-dir \"$distrootdir\" #:lesson \"$lesson\" #:other-dir $otherdirarg #:solutions-mode? $solutionsmodearg #:proglang \"$proglangarg\")" >>  $ADOCABLES_INPUT

if test $otherdirarg != "#t" ; then
  echo $ascfile >> $ADOC_INPUT

  echo $htmlfile >> $ADOC_POSTPROC_WORKBOOKPAGE_INPUT

fi
