#!/bin/bash
echo "hi"
curl -s "https://www.summitatsnoqualmie.com/mountain-report" > dat/snoqdata.html
cat dat/snoqdata.html