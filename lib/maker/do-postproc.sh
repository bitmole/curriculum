#!/bin/bash
# created 2023-01-19
# last modified 2023-01-21

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
    if test -n "$SHTML"; then
      fbase=${fbase%.html}.shtml
    fi
    local fhtml=$fdir/$fbase
    cp -p $fhtmlcached $fhtml
    bumpcsspathdir
    resolveabbrevs
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
  if test $ASCIIDOCNODE; then
  $SED -i \
    -e '/^<link.*asciidoctor\.css/s/<link\(.*\)>/%INSERTLIBCURRICULUMCSS<link DISCARD \1>/' \
    -e '/%INSERTLIBCURRICULUMCSS/r '$TMPFILE-3.txt \
    -e 's/%INSERTLIBCURRICULUMCSS//' \
    -e 's/<link DISCARD .*asciidoctor\.css.*>//' \
    $f
    else
  $SED -i \
    -e '/^<link.*curriculum\.css/s/<link\(.*\)>/%INSERTLIBCURRICULUMCSS<link DISCARD \1>/' \
    -e '/%INSERTLIBCURRICULUMCSS/r '$TMPFILE-3.txt \
    -e 's/%INSERTLIBCURRICULUMCSS//' \
    -e 's/<link DISCARD .*curriculum\.css.*>//' \
    $f
  fi

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

run_postproc postproc_pwyindep $ADOC_POSTPROC_PWYINDEP_INPUT
run_postproc postproc_workbookpage $ADOC_POSTPROC_WORKBOOKPAGE_INPUT

export SHTML=1
run_postproc postproc_lessonplan $ADOC_POSTPROC_LESSONPLAN_INPUT
run_postproc postproc_narrative $ADOC_POSTPROC_NARRATIVE_INPUT
run_postproc postproc_narrativeaux $ADOC_POSTPROC_NARRATIVEAUX_INPUT
run_postproc postproc_resources $ADOC_POSTPROC_RESOURCES_INPUT
