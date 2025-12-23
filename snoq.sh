!#/bin/bash
echo "hi"
curl -s "https://www.summitatsnoqualmie.com/mountain-report#snow-totals" > dat/snoqdata.html
cat snoqdata.html