#!/bin/bash

# ASCII art for the word "weather"
currenttemp=$(cat "db/7day.json" | grep -m 1 -A 27 '"number": 1,' | grep '"temperature"' | sed 's/.*: "\(.*\)".*/\1/' | sed 's/[^0-9]*\([0-9]\+\).*/\1/' | head -n 1)
touch db/frontEndMicro.html
cat <<EOF >db/frontEndMicro.html
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>CloudsyMicro</title>
		<style>
			@font-face {
				font-family: 'CustomFont';
				src: url('font.otf') format('opentype');
			}
			body, html {
				margin: 0;
				padding: 0;
				height: 100%;
				overflow: hidden;
			}
			.container {
				position: relative;
				width: 100%;
				height: 100%;
			}
			img {
				width: 100%;
				height: 100%;
				object-fit: contain;
			}
			.overlay-text {
				position: absolute;
				bottom: 8px;
				right: 10px;
				color: #D1E9F6;
				font-size: 18vw;;
				font-family: 'CustomFont';
				font-weight: bold;
				background-color: rgba(0, 0, 0, 00); /* Optional background for better readability */
				padding: 10px;
				border-radius: 5px; /* Optional, to make it look nicer */
			}
			.overlay-text1 {
				position: absolute;
				bottom: 7px;
				right: 9px;
				color: #F6EACB;
				font-size: 18vw;;
				font-family: 'CustomFont';
				font-weight: bold;
				background-color: rgba(0, 0, 0, 00); /* Optional background for better readability */
				padding: 10px;
				border-radius: 5px; /* Optional, to make it look nicer */
			}
			.overlay-text2 {
				position: absolute;
				bottom: 6px;
				right: 8px;
				color: white;
				font-size: 18vw;;
				font-family: 'CustomFont';
				font-weight: bold;
				background-color: rgba(0, 0, 0, 00); /* Optional background for better readability */
				padding: 10px;
				border-radius: 5px; /* Optional, to make it look nicer */
			}
			.overlay-text3 {
				position: absolute;
				bottom: 5px;
				right: 7px;
				color: #EECAD5;
				font-size: 18vw;;
				font-family: 'CustomFont';
				font-weight: bold;
				background-color: rgba(0, 0, 0, 0.0); /* Optional background for better readability */
				padding: 10px;
				border-radius: 3px; /* Optional, to make it look nicer */
			}
			
		</style>
	</head>
	<body>
		<div class="container">
			<img src="radar.gif" alt="Radar Image Unavailable">
			<div class="overlay-text">$currenttemp</div>
			<div class="overlay-text1">$currenttemp</div>
			<div class="overlay-text2">$currenttemp</div>
			<div class="overlay-text3">$currenttemp</div>
		</div>
		<!-- JavaScript to refresh the page every 10 minutes -->
		<script>
			setTimeout(function(){
				location.reload();
			}, 610000); // Refresh every 10 minutes (600,000 milliseconds)
		</script>
	</body>
</html>




EOF