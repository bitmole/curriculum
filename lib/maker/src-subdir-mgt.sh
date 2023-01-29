# created 2023-01-20
# last modified 2023-01-28

function adjustproglangsubdirs() {
  local d=$1
  local pl=$2

  if test -d "$d"/"$pl"; then
    $CP -p "$d"/"$pl"/* "$d"
  fi

  local lang
  for lang in codap pyret wescheme spreadsheets none; do
    if test -d "$d"/$lang; then
      rm -fr "$d"/$lang
    fi
  done

  local subdir
  for subdir in "$d"/*; do
    if test -d "$subdir"; then
      adjustproglangsubdirs "$subdir" "$pl"
    fi
  done
}

function shadowcopydir() {
  local srcdir=$1
  local tgtdir=$2
  mkdir -p "$tgtdir"

  local f
  for f in "$srcdir"/*; do
    local g=$(basename "$f")
    if test -f "$f"; then
      $CP -p "$f" "$tgtdir"
    elif test -d "$f"; then
      shadowcopydir "$f" "$tgtdir"/"$g"
    fi
  done
}

function make_solution_pages() {
  test -d pages || return
  test -d solution-pages-2 && rm -fr solution-pages-2
  $CP -pr pages solution-pages-2
  $CP -p $PROGDIR/.hta* solution-pages-2
  if test -d solution-pages; then
    shadowcopydir solution-pages solution-pages-2
    rm -fr solution-pages
  fi
  mv solution-pages-2 solution-pages
  test -d pages/.cached || mkdir -p pages/.cached
  test -d solution-pages/.cached || mkdir -p solution-pages/.cached
}
