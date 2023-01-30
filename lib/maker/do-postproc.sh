#!/bin/bash
# created 2023-01-19
# last modified 2023-01-30

cd $TOPDIR/distribution/$NATLANG

# echo doing do-postproc $1

MAXBASHTHREADS=20
NOPARALLEL=1

function calculatedistrootdir() {
  local f=$1
  f=$(echo $f|$SED -e 's/^\.\///')
  # echo doing calculatedistrootdir $f
  local doubledots=$(echo $f|$SED -e 's/\/\.\//\//g')
  # echo I doubledots= $doubledots
  doubledots=$(echo $doubledots|$SED -e 's/[^\/]//g')
  # echo II doubledots= $doubledots
  doubledots=$(echo $doubledots|$SED -e 's/^\///')
  # echo III doubledots= $doubledots
  doubledots=$(echo $doubledots|$SED -e  's/\//..\//g')
  # echo calculatedistrootdir for $f is $DISTROOTDIR
  echo $doubledots
}

function postproc_func() {
  local fhtmlcached=$1
  if test -f "$fhtmlcached"; then
    local localDISTROOTDIR=$(calculatedistrootdir $fhtmlcached)
    local fdir=${fhtmlcached%/.cached/.*html}
    local fbase=${fhtmlcached##*/.}
    test -n "$SHTML" && fbase=${fbase%.html}.shtml
    local fhtml=$fdir/$fbase
    cp -p $fhtmlcached $fhtml
    bumpcsspathdir
    resolveabbrevs
    test -n "$GDRIVE" && insertgdrivesave
  fi
}

function run_postproc() {

  # local postproc_func=$1
  local bigfile=$2

  rm -f $bigfile-split*
  if test ! -f $bigfile; then return; fi

  split -l $MAXBASHTHREADS $bigfile $bigfile-split
  local smallfile fhtml
  for smallfile in $bigfile-split*; do
    if test -s "$smallfile"; then
      for fhtml in $(cat $smallfile); do
        postproc_func $fhtml
      done
    fi
  done

}

function bumpcsspathdir() {
  local f=$fhtml

  local f_head=${f%.*}
  local TMPFILE=$f_head.$TMPAFX

  cat > $TMPFILE-3.txt <<EOF
  <link rel="stylesheet" href="${localDISTROOTDIR}lib/curriculum.css" />
EOF
  $SED -i \
    -e '/^<link.*curriculum\.css/s/<link\(.*\)>/%INSERTLIBCURRICULUMCSS<link DISCARD \1>/' \
    -e '/%INSERTLIBCURRICULUMCSS/r '$TMPFILE-3.txt \
    -e 's/%INSERTLIBCURRICULUMCSS//' \
    -e 's/<link DISCARD .*curriculum\.css.*>//' \
    $f

  rm -f $TMPFILE-3.txt
}

function resolveabbrevs() {
  local f=$fhtml
  local fdir=$(dirname $f)
  local fbase=${f##*/}
  local mathjaxneeded=
  local codemirrorneeded=
  if grep -q %CURRICULUMSCRIPT $f; then
    mathjaxneeded=1
  fi
  local CODELANG=pyret
  if test "$PROGLANG" = wescheme; then
    CODELANG=racket
  fi
  $SED -i \
    -e 's/<pre>/<pre><code class="'$CODELANG'">/g' \
    -e 's/<\/pre>/<\/code><\/pre>/g' \
    -e 's/<code>/<code class="'$CODELANG'">/g' \
    $f
  if grep -q 'class=\"\(pyret\|racket\)\"' $f || grep -q 'class=\"circleevalsexp\"' $f; then
    codemirrorneeded=1
  fi
  $SED -i \
    -e 's/%PYRETKEYWORD%\([^%]*\)%END%/<span class="pyretkeyword">\1<\/span>/g' \
    \
    -e 's/%CURRICULUMCOMMA%/,/g' \
    \
    -e 's/<p>\(%CURRICULUMCOMMENT%\)/\1/' \
    -e 's/\(%ENDCURRICULUMCOMMENT%\)<.p>/\1/' \
    -e 's/%CURRICULUMCOMMENT%/<!-- /' \
    -e 's/%ENDCURRICULUMCOMMENT%/\n-->/' \
    \
    -e 's/%CURRICULUMSCRIPT%/<script type="math\/tex"/g' \
    -e 's/%BEGINCURRICULUMSCRIPT%/>/g' \
    -e 's/%ENDCURRICULUMSCRIPT%/<\/script>/g' \
    \
    -e 's/%CURRICULUMPMMATH%/<!--CURRICULUMPMMATH<tt>/g' \
    -e 's/%ENDCURRICULUMPMMATH%/<\/tt>CURRICULUMPMMATH-->/g' \
    \
    -e 's/%CURRICULUM\([^%]*\)%/<\1/g' \
    -e 's/%BEGINCURRICULUM\([^%]*\)%/>/g' \
    -e 's/%ENDCURRICULUM\([^%]*\)%/<\/\1>/g' \
    \
    -e 's/&#8656;/\&lt;=/g' \
    -e 's/&#8594;/-\&gt;/g' \
    \
    -e 's/^\(<div id="preamble\)">/\1_disabled" class="lessonSummary">/' \
    $f
  $SED -i \
    -e 's/<span class="\([^"]\+\)">\(<figure class="image"\)/\2 style="text-align: \1"/g' \
    -e 's/\(<\/figure>\)<\/span>/\1/g' \
    $f
  $SED -i \
    -e '/%SIDEBARSECTION%/,/%ENDSIDEBARSECTION%/s/\(<\/div>\)<\/p>/\1/' \
    $f
  $SED -i \
    -e '/%SIDEBARSECTION%/,/%ENDSIDEBARSECTION%/s/<p>\(<div\)/\1/' \
    $f
  $SED -i \
    -e 's/%SIDEBARSECTION%/--><\/div><div class="sidebar"><div id="toggle"><\/div><div class="paragraph"><!--/' \
    $f
  $SED -i \
    -e 's/%ENDSIDEBARSECTION%/--><\/div><!--/' \
    $f
  $SED -i \
    -e '/BOGUSACKNOWLEDGMENTSECTIONHEADER/d' \
    $f
  #
  if test ! -f $fdir/.cached/.bootstraplesson.txt; then
  cat > $fdir/.cached/.bootstraplesson.txt <<EOF
    <script src="${localDISTROOTDIR}lib/langtable.js"></script>
    <script src="${localDISTROOTDIR}lib/bootstraplesson.js"></script>
    <script src="${localDISTROOTDIR}lib/dictionaries.js"></script>
    <script src="${localDISTROOTDIR}dependency-graph.js"></script>
    <script src="${localDISTROOTDIR}pathway-tocs.js"></script>
    <script>var pathway;</script>
EOF
  fi
   $SED -i \
    -e '/^ *<link.*curriculum\.css/s/^/%INSERTBOOTSTRAPLESSON\0/' \
    -e "/%INSERTBOOTSTRAPLESSON/r $fdir/.cached/.bootstraplesson.txt" \
    -e 's/%INSERTBOOTSTRAPLESSON//' \
    $f
  #
  if test "$mathjaxneeded"; then
    if test ! -f $fdir/.cached/.mathjax.txt; then
    cat > $fdir/.cached/.mathjax.txt <<EOF
      <script src="${localDISTROOTDIR}extlib/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML%2Clocal%2Fmathjaxlocal.js"></script>
      <script>window.status = "not_ready_to_print";</script>
EOF
    fi
    $SED -i \
      -e '/^ *<link.*curriculum\.css/s/^/%INSERTMATHJAX\0/' \
      -e "/%INSERTMATHJAX/r $fdir/.cached/.mathjax.txt" \
      -e 's/%INSERTMATHJAX//' \
      $f
  fi
  #
  if test "$codemirrorneeded"; then
    #FIXME: is codemirror.css needed?
    if test ! -f $fdir/.cached/.codemirror.txt; then
    cat > $fdir/.cached/.codemirror.txt <<EOF
    <link rel="stylesheet" href="${localDISTROOTDIR}lib/codemirror.css" />
    <script src="${localDISTROOTDIR}lib/codemirror.js"></script>
    <script src="${localDISTROOTDIR}lib/runmode.js"></script>
    <script src="${localDISTROOTDIR}lib/scheme2.js"></script>
    <script src="${localDISTROOTDIR}lib/pyret-mode.js"></script>
EOF
    fi
$SED -i \
  -e '/^ *<link.*curriculum\.css/s/^/%INSERTCODEMIRROR\0/' \
  -e "/%INSERTCODEMIRROR/r $fdir/.cached/.codemirror.txt" \
  -e 's/%INSERTCODEMIRROR//' \
  $f
  fi
  #
  local tif=$fdir/.cached/${fbase%.*}-comment.txt
  if test ! -f $tif; then
    tif=$fdir/.cached/.${fbase%.*}-comment.txt
  fi
  if test -f $tif; then
    $SED -i \
      -e '/^<body[^>]*>/s/<body[^>]*>/\0%INSERTCURRICULUMCOMMENT/' \
      -e '/%INSERTCURRICULUMCOMMENT/r '$tif \
      -e 's/%INSERTCURRICULUMCOMMENT//' \
      $f
  fi
  if test $TEACHERRESOURCEPAGE; then
    $SED -i \
      -e 's/^<body class="/\0TeacherResources /' \
      $f
  elif test -z $WORKBOOKPAGE && test -z $LESSONPLANPAGE && test -z $DATASHEETPAGE; then
    $SED -i \
      -e 's/^<body class="/\0narrativepage /' \
      $f
  fi
}

function adjustgdrivecolgroup() {
  local f=$1

  local CTEMP=$(mktemp); rm -f $CTEMP

  local CTEMPFILE=$(basename $CTEMP)-cols.txt

  grep '^<col style.*> *$' $f > $CTEMPFILE

  local num=$(wc -l $CTEMPFILE|$SED -e 's/^ *\([^ ]*\).*/\1/')

  if test $num -eq 0; then
    rm -f $CTEMPFILE
    return
  fi

  $SED -i \
    -e 's/^<col //' \
    -e 's/> *$//' \
    $CTEMPFILE

  local i=1

  local cline
  local flnum

  while test $i -le $num; do
    cline=$($SED -ne "$i p" $CTEMPFILE)

    flnum=$(grep -n '^<th ' $f|$SED -e 1q|$SED -e 's/^\([^:]*\).*/\1/')

    $SED -i \
      -e "$flnum s/^<th /<th%GDRIVE $cline /" \
      $f

    i=$((i + 1))

  done

  rm -f $CTEMPFILE

  $SED -i \
    -e 's/^<th%GDRIVE /<th /' \
    $f

}

function modifygdrivepage() {
  local f=$1
  local h=$2

  $SED -i \
    -e '/include virtual=".menubar.ssi"/d' \
    -e 's/^<p>Relevant Standards<select.*<\/select><\/p> *$/<p>Standards<\/p>/' \
    -e '/^<p><em>Select one or more standards from the menu on the left.*<\/p> *$/d' \
    -e 's/\(class="paragraph \)alignedStandardsIntro/\1/' \
    -e 's/\(class="dlist \)alignedStandards /\1/' \
    -e 's/href=\("\(https\|http\):\/\/\)/href%GDRIVEEXTERNALHREF=\1/g' \
    -e 's/<div/<span/g' \
    -e 's/<\/div>/<\/span>/g' \
    -e 's/<dt class="hdlist1">/\0<br\/>/g' \
    -e 's/<span class="sect1 lesson-section-1">/\0<hr\/>/g' \
    -e 's/<span class="openblock acknowledgment">/\0<hr\/>/g' \
    -e 's/<h2.*>\(.*\)<span class="duration">\(.*\)<\/span><\/h2>/<table class="grid-none frame-none section-heading"><tr><td width="65%">\1<\/td><td width="35%">\2<\/td><\/tr><\/table>/g' \
    -e 's/<tt\(.*\)>\(.*\)<\/tt>/<span\1>\2<\/span>/g' \
    $f
  $SED -i \
    -e 's/^\(.*\)<span\(  *class="paragraph lesson-point"\)/%GDRIVESPANDIV\1<div\2/g' \
    $f
  $SED -i \
    -e '/^%GDRIVESPANDIV/,/^<\/span>/ s/^<\/span>/<\/div>/' \
    -e 's/^%GDRIVESPANDIV//' \
    $f
  $SED -i \
    -e 's/href="/\0'$hrefPrefix'\//g' \
    $f
  $SED -i \
    -e 's/%GDRIVEEXTERNALHREF//g' \
    -e '/^ *<link rel="stylesheet".*\.css/d' \
    -e '/^ *<script .*\(codemirror\|runmode\|scheme2\|pyret-mode\|bootstraplesson\)/d' \
    -e '/<span class="tooltiptext">.*<\/span>/d' \
    $f
  echo "<style>" > $TMPFILE.css
  #echo doing gdrive-import: PWD is $(pwd)
  #echo cat $DISTROOTDIR/lib/gdrive-import.css
  cat lib/gdrive-import.css >> $TMPFILE.css
  echo "</style>" >> $TMPFILE.css
  $SED -i \
    -e '/<\/title>/r '$TMPFILE.css \
    $f

  $SED -i \
    -e 's/<span class="begin-ignore-for-gdrive">/<!--\0/g' \
    -e 's/<span class="end-ignore-for-gdrive"><\/span>/\0-->/g' \
    $f

  $SED -i \
    -e '/studentAnswer/ s/&#x5f;/\0\0/g' \
    $f

  rm -f $TMPFILE.css

  adjustgdrivecolgroup $f

  $SED -i \
    -e 's/<span class="\(begin\|end\)-ignore-for-gdrive"><\/span>//g' \
    $h

}

function insertgdrivesave() {

  local f=$fhtml
  # echo doing insertgdrivesave $f in $(pwd)
  local f_head=${f%.*}
  local other_f=$f_head-gdrive-import.html
  local pageTitle=
  if test -f $f_head.adoc; then
    pageTitle=$(grep '^= ' $f_head.adoc|head -n 1|$SED -e 's/^= *//' -e 's/  *$//')
  fi

  if test ! "$pageTitle"; then
    pageTitle=$f_head
  fi

  pageTitle=$(echo $pageTitle|$SED -e 's/[“”]/\\\\"/g')
  pageTitle=$(echo $pageTitle|$SED -e 's/\//\\\//g')

  local TMPFILE=$f_head.$TMPAFX

  #echo TMPFILE is $TMPFILE

  cat > $TMPFILE-1.txt <<EOF
  <script>
  window.status = window.status || 'ready_to_print';
  window.___gcfg = {
  parsetags: 'explicit'
  };
  </script>
  <script src="https://apis.google.com/js/platform.js" async defer></script>
  <script>function renderSaveToDrive() {
    var isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    gapi.savetodrive.render('savetodrive-div', {
    src:%INSERTGDRIVEURL,
    filename:"%INSERTGDRIVELESSONTITLE",
    sitename:"Bootstrap, Brown University"
  });
  if(isSafari){
    var warning = document.createElement("div");
    warning.id = "safariWarning";
    warning.innerHTML = "You appear to be using Safari, which interferes with Google's Save-to-Drive button. You can fix it by going to Preferences, clicking 'Privacy', and making sure that 'Prevent cross-site tracking' is <b>not</b> checked."
    var button = document.getElementById("savetodrive-div");
    button.parentNode.insertBefore(warning, warning.nextSibling);
  }
}
</script>
EOF
  cat > $TMPFILE-2.txt <<EOF
  <div id="savetodrive-div"></div>

EOF
  $SED -i \
    -e 's/^\(<body  *[^>]*\)>/\1 onload="renderSaveToDrive()">/' \
    -e 's/<\/head>/%INSERTGDRIVESAVE1\n\0/' \
    -e 's/<\/h1>.*/\0\n%INSERTGDRIVESAVE2/' \
    -e '/^<div id="body"/ s/id="body"/\0 onload="renderSaveToDrive()"/' \
    $f

  if test $WORKBOOKPAGE; then
    $SED -i \
      -e 's/^<body class="/\0workbookpage /' \
      $f
    if test $NOTESPAGE; then
      $SED -i \
        -e 's/^<body class="/\0LessonNotes /' \
        $f
    fi
    if test $BACKMATTERPAGE; then
      $SED -i \
        -e 's/^<body class="/\0back-matter /' \
        $f
    fi
  elif test $DATASHEETPAGE; then
    $SED -i \
      -e 's/^<body class="/\0datasheetpage /' \
      $f
  fi

  if ! grep -q %INSERTGDRIVESAVE2 $f; then
    $SED -i \
      -e 's/<div id="header">/\0\n%INSERTGDRIVESAVE2/' \
      $f
  fi

  $SED -i \
    -e '/%INSERTGDRIVESAVE1/r '$TMPFILE-1.txt \
    -e '/%INSERTGDRIVESAVE2/r '$TMPFILE-2.txt \
    -e 's/%INSERTGDRIVESAVE[12]//' \
    $f

  #echo deleting $TMPFILE 12 .txt
  rm -f $TMPFILE-[12].txt

  $SED -i \
    -e 's/%INSERTGDRIVELESSONTITLE/'"$pageTitle"'/' \
    $f

  $CP -p $f $other_f

  $SED -i \
    -e "s/%INSERTGDRIVEURL/(window.location.href.match(\/\\\\\/$\/)?(window.location.href+'index-gdrive-import.html'):(window.location.href.replace(\/([^\\\\\/]+)\\\\.([^.\\\\\/]+)$\/, '\$1-gdrive-import.html')))/" \
    $f

  $SED -i \
    -e 's/%INSERTGDRIVEURL/window.location.href/' \
    $other_f

  modifygdrivepage $other_f $f
}

#############################################################################

GDRIVE=1

run_postproc postproc_pwyindep $ADOC_POSTPROC_PWYINDEP_INPUT
run_postproc postproc_workbookpage $ADOC_POSTPROC_WORKBOOKPAGE_INPUT

SHTML=1 run_postproc postproc_lessonplan $ADOC_POSTPROC_LESSONPLAN_INPUT
SHTML=1 run_postproc postproc_narrative $ADOC_POSTPROC_NARRATIVE_INPUT
SHTML=1 GDRIVE= run_postproc postproc_narrativeaux $ADOC_POSTPROC_NARRATIVEAUX_INPUT
SHTML=1 run_postproc postproc_resources $ADOC_POSTPROC_RESOURCES_INPUT
