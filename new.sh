#!/bin/bash
# This script creates a new post or draft in jekyll with pre-filled front matter
# ./script some title for your post
# use -d option for draft
# by Xianny -- http://journal.xianny.com/2017/02/21/autogen-jekyll-new-post.html
FILEDIR="_posts/"

while getopts "d" opt; do
    case $opt in
        d)
            FILEDIR="_drafts/"
            ;;
    esac
done

if [ ! -d "$FILEDIR" ]; then
  mkdir $FILEDIR
fi

shift $((OPTIND-1))

TITLE=""
for word in $@
do
    TITLE+="-$word"
done

FILENAME="$FILEDIR$(date +%Y-%m-%d)$TITLE.md"
echo "---" > $FILENAME

if [ $# -gt 0 ]
  then
    echo "title: \"$@\"" >> $FILENAME
fi

echo "layout: post" >> $FILENAME
echo "date: $(date +%Y-%m-%d) $(date +%T) $(date +%z)" >> $FILENAME
echo "tags: " >> $FILENAME
echo "categories: " >> $FILENAME

echo "---" >> $FILENAME

emacs $FILENAME &
