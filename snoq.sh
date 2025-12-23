!#/bin/bash
echo "hi"
curl -s "https://www.summitatsnoqualmie.com/mountain-report#snow-totals" > snoqdata.html
cat snoqdata.html