#!/bin/bash

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -z|--zip) zip_code="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# ASCII art for the word "weather"
echo " ______     __         ______     __  __     ____    ______     __  __    "
echo "/\  ___\   /\ \       /\  __ \   /\ \/\ \   | |  \  /\  ___\   /\ \_\ \   "
echo "\ \ \____  \ \ \____  \ \ \/\ \  \ \ \_\ \  | | . \ \ \___  \  \ \____ \  "
echo " \ \_____\  \ \_____\  \ \_____\  \ \_____\ | |___/  \/\_____\  \/\_____\ "
echo "  \/_____/   \/_____/   \/_____/   \/_____/ |/___/    \/_____/   \/_____/ "
echo " "
echo " "

# If no zip code argument is provided, prompt user for zip code
if [ -z "$zip_code" ]; then
    read -p "	Enter your zip code: " zip_code
fi

# sanitize and extract only the first 5 digits from the zip code
zip_code=${zip_code//[^0-9]/}   # Remove all non-digit characters
zip_code=${zip_code:0:5}         # Extract the first 5 digits

# display entered zip code
echo "	You entered zip code: $zip_code"
echo " "
echo " "

# extract latitude and longitude from zip_code
rawcurrentlat=$(cat zipcodes/uszips.csv | grep -w "\"$zip_code\"" | awk -F',' '{gsub(/"/, "", $2); print $2}')
rawcurrentlon=$(cat zipcodes/uszips.csv | grep -w "\"$zip_code\"" | awk -F',' '{gsub(/"/, "", $3); print $3}')
adjustedlat=$(printf "%.4f" $rawcurrentlat)
adjustedlon=$(printf "%.4f" $rawcurrentlon)

# check if the variable ends with ".0" or ".00" or any number of zeroes
# remove trailing zeroes after the decimal point
if [[ $adjustedlat =~ \.[0-9]*0$ ]]; then
    currentlat="${adjustedlat%0}"
	else currentlat="${adjustedlat}"
fi

if [[ $adjustedlon =~ \.[0-9]*0$ ]]; then
    currentlon="${adjustedlon%0}"
	else currentlon="${adjustedlon}"
fi

# check if the system is running Linux or windows
if [ "$(uname)" == "Linux" ]; then
    osVer="linux"
	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
		osVer="windows"
	elif [ "$(expr substr $(uname -s) 1 9)" == "CYGWIN_NT" ]; then
		osVer="windows"
	else
		osVer="windows"
fi

mkdir -p "db/weekly"

# the error zone : fun stuff
Error_time() {
    random_number=$((RANDOM % 2))  # Generate a random number between 0 and 1
    case $random_number in
        0)
            echo " error pulling data from NOAA
 █     █░ ██░ ██  ▒█████   ▒█████   ██▓███    ██████                            
▓█░ █ ░█░▓██░ ██▒▒██▒  ██▒▒██▒  ██▒▓██░  ██▒▒██    ▒                            
▒█░ █ ░█ ▒██▀▀██░▒██░  ██▒▒██░  ██▒▓██░ ██▓▒░ ▓██▄                              
░█░ █ ░█ ░▓█ ░██ ▒██   ██░▒██   ██░▒██▄█▓▒ ▒  ▒   ██▒                           
░░██▒██▓ ░▓█▒░██▓░ ████▓▒░░ ████▓▒░▒██▒ ░  ░▒██████▒▒ ██▓                       
░ ▓░▒ ▒   ▒ ░░▒░▒░ ▒░▒░▒░ ░ ▒░▒░▒░ ▒█▓▒ ░  ░▒ ▒▓▒ ▒ ░ ▒▓▒                       
  ▒ ░ ░   ▒ ░▒░ ░  ░ ▒ ▒░   ░ ▒ ▒░ ▒▓▒░ ░   ░ ░▒  ░ ░ ░▒                        
  ░   ░   ░  ░░ ░░ ░ ░ ▒  ░ ░ ░ ▒  ░▒ ░     ░  ░  ░   ░                         
    ░     ░  ░  ░    ░ ░      ░ ░  ░░             ░    ░                        
 ███▄    █  ▒█████      █     █░▓█████ ▄▄▄     ▄▄▄█████▓ ██░ ██ ▓█████  ██▀███  
 ██ ▀█   █ ▒██▒  ██▒   ▓█░ █ ░█░▓█   ▀▒████▄   ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒
▓██  ▀█ ██▒▒██░  ██▒   ▒█░ █ ░█ ▒███  ▒██  ▀█▄ ▒ ▓██░ ▒░▒██▀▀██░▒███   ▓██ ░▄█ ▒
▓██▒  ▐▌██▒▒██   ██░   ░█░ █ ░█ ▒▓█  ▄░██▄▄▄▄██░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  
▒██░   ▓██░░ ████▓▒░   ░░██▒██▓ ░▒████▒▓█   ▓██▒ ▒██▒ ░ ░▓█▒░██▓░▒████▒░██▓ ▒██▒
░ ▒░   ▒ ▒ ░ ▒░▒░▒░    ░ ▓░▒ ▒  ░░ ▒░ ░▒▒   ▓▒█░ ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░
░ ░░   ░ ▒░  ░ ▒ ▒░      ▒ ░ ░   ░ ░  ░ ▒   ▒▒ ░   ░     ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░
   ░   ░ ░ ░ ░ ░ ▒       ░   ░     ░    ░   ▒    ░       ░  ░░ ░   ░     ░░   ░ 
       ░   an  ░ ░  error  ░   has ░  ░     ░  ░ occurred░  ░  ░   ░  ░   ░     " && echo "error pulling data from NOAA" > 'db/frontEnd.html'
	
            ;;
        1)
            echo " error pulling data from NOAA
 _____                                            _____ 
( ___ )                                          ( ___ )
 |   |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|   | 
 |   |                                            |   | 
 |   |   w e l l     t h a t s     b a d          |   | 
 |   |                                            |   | 
 |   |         the   weather   broke              |   | 
 |   |                                            |   | 
 |   |                 either   theres            |   | 
 |   |                                            |   | 
 |   |   C O N N E C T I O N   P R O B L E M S    |   | 
 |   |                                            |   | 
 |   |                    or                      |   | 
 |   |                                            |   | 
 |   |     s o m e o n e   d e s t r o y e d      |   | 
 |   |                                            |   | 
 |   |   T H E   W E A T H E R   S E R V I C E    |   | 
 |   |                                            |   | 
 |___|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|___| 
(_____)      error fetching data                 (_____)" && echo "error pulling data from NOAA" > 'db/frontEnd.html'
            ;;
        *)
            echo "Unknown error" && echo "error pulling data from NOAA" > 'db/frontEnd.html'
            ;;
    esac
}

# the loading screen
cat <<EOF >db/frontEnd.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloudsy</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        :root {
            --primary-pink: #ff7eb9;
            --primary-blue: #7cc0ff;
            --accent-pink: #ff65a3;
            --accent-blue: #5e9fff;
            --glass-dark: rgba(30, 33, 58, 0.8);
            --glass-border: rgba(255, 255, 255, 0.1);
            --glass-highlight: rgba(255, 255, 255, 0.05);
            --text-light: #f5f6fa;
            --text-dim: rgba(245, 246, 250, 0.7);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(-45deg, #1e203a, #252845, #2a2d54, #303865);
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
            color: var(--text-light);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .container {
            display: flex;
            gap: 20px;
            width: 100%;
            max-width: 1400px;
            height: 90vh;
			align-items: center;
        }
        
        .card {
            background: var(--glass-dark);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-radius: 24px;
            border: 1px solid var(--glass-border);
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3);
            padding: 24px;
            overflow: hidden;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            opacity: 0;
            transform: translateY(20px);
        }
        
        .card:hover {
            transform: translateY(-5px) translateZ(0);
            box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
        }
        
        .weekly-forecast {
			align-items: center;
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .current-weather {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
        }
        
        .hourly-forecast {
            flex: 1;
            overflow-y: auto;
        }
        
        h2, h3 {
            color: var(--text-light);
            margin-bottom: 16px;
            font-weight: 600;
        }
        
        h2 {
            font-size: 1.5rem;
            position: relative;
            display: inline-block;
        }
        
        h2::after {
            content: '';
            position: absolute;
            bottom: -4px;
            left: 0;
            width: 50px;
            height: 3px;
            background: linear-gradient(90deg, var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
        
        .weather-icon {
            width: 105%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .current-temp {
            font-size: 3rem;
            font-weight: 700;
            background: linear-gradient(45deg, var(--primary-pink), var(--primary-blue));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            margin: 8px 0;
            text-shadow: 0 4px 12px rgba(124, 192, 255, 0.2);
        }
        
        .weather-details {
            margin: 16px 0;
            width: 100%;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .detail-label {
            font-weight: 500;
            color: var(--text-dim);
        }
        
        .detail-value {
            font-weight: 600;
        }
        
        .radar-image {
            width: 100%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .forecast-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        
        .forecast-table th {
            text-align: left;
            padding: 12px 8px;
            font-weight: 500;
            color: var(--text-dim);
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-table td {
            padding: 12px 8px;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-day {
            font-weight: 600;
        }
        
        .forecast-temp {
            text-align: right;
            font-weight: 600;
            color: var(--primary-blue);
        }
        
        .forecast-desc {
            font-size: 0.9rem;
            line-height: 1.4;
            color: var(--text-dim);
        }
        
        .hourly-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
            transition: background 0.2s ease;
        }
        
        .hourly-row:hover {
            background: var(--glass-highlight);
        }
        
        .hourly-time {
            font-weight: 500;
            width: 80px;
        }
        
        .hourly-temp {
            font-weight: 600;
            width: 60px;
            text-align: center;
            color: var(--primary-pink);
        }
        
        .precip-chance {
            display: flex;
            align-items: center;
            width: 100px;
        }
        
        .precip-bar {
            height: 6px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
            margin-left: 8px;
            flex-grow: 1;
            position: relative;
            overflow: hidden;
        }
        
        .precip-fill {
            position: absolute;
            top: 0;
            left: 0;
            height: 100%;
            background: linear-gradient(90deg, var(--accent-pink), var(--accent-blue));
            border-radius: 3px;
        }
        
        .precip-value {
            font-size: 0.8rem;
            font-weight: 500;
            color: var(--primary-blue);
        }
        
        .condition-highlight {
            color: var(--primary-pink);
            font-weight: 600;
        }
        
        @media (max-width: 1024px) {
            .container {
                flex-direction: column;
                height: auto;
            }
            
            .card {
                margin-bottom: 20px;
            }
        }
        
        /* Scrollbar styling */
        ::-webkit-scrollbar {
            width: 6px;
        }
        
        ::-webkit-scrollbar-track {
            background: rgba(0, 0, 0, 0.1);
            border-radius: 3px;
        }
        
        ::-webkit-scrollbar-thumb {
            background: linear-gradient(var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
    </style>
</head>
	<body>
		<center><div class="container">
			<div class="weekly-forecast">
				<p><img src="loading.gif" alt="Loading, please wait" class="radar-image"></p>
			</div>
		</div></center>
		<!-- JavaScript to refresh the page every 10 minutes -->
		<script>
			setTimeout(function(){
				location.reload();
			}, 6000); // Refresh every 10 minutes (600,000 milliseconds)
		</script>
	</body>
</html>


EOF
# duplicate it to mobile version
cat <<EOF >db/frontEndmobile.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloudsy</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        :root {
            --primary-pink: #ff7eb9;
            --primary-blue: #7cc0ff;
            --accent-pink: #ff65a3;
            --accent-blue: #5e9fff;
            --glass-dark: rgba(30, 33, 58, 0.8);
            --glass-border: rgba(255, 255, 255, 0.1);
            --glass-highlight: rgba(255, 255, 255, 0.05);
            --text-light: #f5f6fa;
            --text-dim: rgba(245, 246, 250, 0.7);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(-45deg, #1e203a, #252845, #2a2d54, #303865);
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
            color: var(--text-light);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .container {
            display: flex;
            gap: 20px;
            width: 100%;
            max-width: 1400px;
            height: 90vh;
			align-items: center;
        }
        
        .card {
            background: var(--glass-dark);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-radius: 24px;
            border: 1px solid var(--glass-border);
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3);
            padding: 24px;
            overflow: hidden;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            opacity: 0;
            transform: translateY(20px);
        }
        
        .card:hover {
            transform: translateY(-5px) translateZ(0);
            box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
        }
        
        .weekly-forecast {
			align-items: center;
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .current-weather {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
        }
        
        .hourly-forecast {
            flex: 1;
            overflow-y: auto;
        }
        
        h2, h3 {
            color: var(--text-light);
            margin-bottom: 16px;
            font-weight: 600;
        }
        
        h2 {
            font-size: 1.5rem;
            position: relative;
            display: inline-block;
        }
        
        h2::after {
            content: '';
            position: absolute;
            bottom: -4px;
            left: 0;
            width: 50px;
            height: 3px;
            background: linear-gradient(90deg, var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
        
        .weather-icon {
            width: 105%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .current-temp {
            font-size: 3rem;
            font-weight: 700;
            background: linear-gradient(45deg, var(--primary-pink), var(--primary-blue));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            margin: 8px 0;
            text-shadow: 0 4px 12px rgba(124, 192, 255, 0.2);
        }
        
        .weather-details {
            margin: 16px 0;
            width: 100%;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .detail-label {
            font-weight: 500;
            color: var(--text-dim);
        }
        
        .detail-value {
            font-weight: 600;
        }
        
        .radar-image {
            width: 100%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .forecast-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        
        .forecast-table th {
            text-align: left;
            padding: 12px 8px;
            font-weight: 500;
            color: var(--text-dim);
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-table td {
            padding: 12px 8px;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-day {
            font-weight: 600;
        }
        
        .forecast-temp {
            text-align: right;
            font-weight: 600;
            color: var(--primary-blue);
        }
        
        .forecast-desc {
            font-size: 0.9rem;
            line-height: 1.4;
            color: var(--text-dim);
        }
        
        .hourly-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
            transition: background 0.2s ease;
        }
        
        .hourly-row:hover {
            background: var(--glass-highlight);
        }
        
        .hourly-time {
            font-weight: 500;
            width: 80px;
        }
        
        .hourly-temp {
            font-weight: 600;
            width: 60px;
            text-align: center;
            color: var(--primary-pink);
        }
        
        .precip-chance {
            display: flex;
            align-items: center;
            width: 100px;
        }
        
        .precip-bar {
            height: 6px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
            margin-left: 8px;
            flex-grow: 1;
            position: relative;
            overflow: hidden;
        }
        
        .precip-fill {
            position: absolute;
            top: 0;
            left: 0;
            height: 100%;
            background: linear-gradient(90deg, var(--accent-pink), var(--accent-blue));
            border-radius: 3px;
        }
        
        .precip-value {
            font-size: 0.8rem;
            font-weight: 500;
            color: var(--primary-blue);
        }
        
        .condition-highlight {
            color: var(--primary-pink);
            font-weight: 600;
        }
        
        @media (max-width: 1024px) {
            .container {
                flex-direction: column;
                height: auto;
            }
            
            .card {
                margin-bottom: 20px;
            }
        }
        
        /* Scrollbar styling */
        ::-webkit-scrollbar {
            width: 6px;
        }
        
        ::-webkit-scrollbar-track {
            background: rgba(0, 0, 0, 0.1);
            border-radius: 3px;
        }
        
        ::-webkit-scrollbar-thumb {
            background: linear-gradient(var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
    </style>
</head>
	<body>
		<center><div class="container">
			<div class="weekly-forecast">
				<p><img src="loading.gif" alt="Loading, please wait" class="radar-image"></p>
			</div>
		</div></center>
		<!-- JavaScript to refresh the page every 10 minutes -->
		<script>
			setTimeout(function(){
				location.reload();
			}, 6000); // Refresh every 10 minutes (600,000 milliseconds)
		</script>
	</body>
</html>


EOF

# open the loading screen on different OS
html_file="db/frontEnd.html"
	if [ $osVer == "linux" ]; then
		xdg-open "$html_file"
	fi
	
	if [ $osVer == "windows" ]; then
		powershell -Command "Start-Process -FilePath 'db/frontEnd.html' -WindowStyle Normal"
	fi

# main loop indefinitely
while true; do

    # info pulling
	echo "		Generating..."
	echo "			Please wait"
	echo " "
	echo " "

    curl -s "https://api.weather.gov/points/${currentlat},${currentlon}" > db/stationlookup.json
		currentstation=$(cat "db/stationlookup.json" | grep '"radarStation"' | awk -F'"' '{print $4}')
		errorcheck=$(cat db/stationlookup.json | grep fireWeather)
	
	if [ -z "${errorcheck}" ]; then
		Error_time
		exit
	fi

    curl -s "https://radar.weather.gov/ridge/standard/${currentstation}_loop.gif" > db/radar.gif
	curl -s "https://api.weather.gov/alerts?point=${currentlat},${currentlon}" > db/alerts.json
		currentzone=$(grep forecastZone db/stationlookup.json | awk -F '"' '{print $4}' | awk -F '/' '{print $6}')
		alert1=$(grep "/$currentzone" db/alerts.json)
		sevenday=$(cat "db/stationlookup.json" | grep '"forecast"' | awk -F'"' '{print $4}')
	curl -s "$sevenday" > db/7day.json
#	dev notes: you now have 3 assets
# 	stationlookup
# 	7day.json
# 	radar.gif
		currentcity=$(cat db/stationlookup.json | grep city | awk 'NR==2' | awk -F'"' '{print $4}')
		currentcondition=$(cat "db/7day.json" | grep -m 1 -A 27 '"number": 1,' | grep '"shortForecast"' | sed 's/.*: "\(.*\)".*/\1/')
		currenttemp=$(cat "db/7day.json" | grep -m 1 -A 27 '"number": 1,' | grep '"temperature"' | sed 's/.*: "\(.*\)".*/\1/' | sed 's/[^0-9]*\([0-9]\+\).*/\1/' | head -n 1)
		hourlyURL=$(cat "db/stationlookup.json" | grep '"forecastHourly"' | awk -F'"' '{print $4}')
		currentcond=$(cat "db/7day.json" | grep -m 1 -A 27 '"number": 1,' | grep '"detailedForecast"' | awk -F '"' '{print $4}')	

# unused but it works	
	if grep -q "today" db/7day.json; then
		grep "today" db/7day.json
		else
		grep "tonight" db/7day.json
	fi
	
	curl -s "$hourlyURL" > db/TOD.json
	
	# hourly
		hourRawTime1a=$(cat "db/TOD.json" | grep -m 1 startTime | awk -F '[:-T]' '{print $4}')
		hourRawTime2a=$(cat "db/TOD.json" | grep -m 2 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime3a=$(cat "db/TOD.json" | grep -m 3 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime4a=$(cat "db/TOD.json" | grep -m 4 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime5a=$(cat "db/TOD.json" | grep -m 5 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime6a=$(cat "db/TOD.json" | grep -m 6 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime7a=$(cat "db/TOD.json" | grep -m 7 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime8a=$(cat "db/TOD.json" | grep -m 8 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime9a=$(cat "db/TOD.json" | grep -m 9 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime10a=$(cat "db/TOD.json" | grep -m 10 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime11a=$(cat "db/TOD.json" | grep -m 11 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime12a=$(cat "db/TOD.json" | grep -m 12 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime13a=$(cat "db/TOD.json" | grep -m 13 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime14a=$(cat "db/TOD.json" | grep -m 14 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime15a=$(cat "db/TOD.json" | grep -m 15 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime16a=$(cat "db/TOD.json" | grep -m 16 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime17a=$(cat "db/TOD.json" | grep -m 17 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime18a=$(cat "db/TOD.json" | grep -m 18 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime19a=$(cat "db/TOD.json" | grep -m 19 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime20a=$(cat "db/TOD.json" | grep -m 20 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime21a=$(cat "db/TOD.json" | grep -m 21 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime22a=$(cat "db/TOD.json" | grep -m 22 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime23a=$(cat "db/TOD.json" | grep -m 23 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime24a=$(cat "db/TOD.json" | grep -m 24 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)
		hourRawTime25a=$(cat "db/TOD.json" | grep -m 25 startTime | awk -F '[:-T]' '{print $4}' | tail -n 1)

	for i in {1..25}; do
		eval hourTemp${i}a=$(cat 'db/TOD.json' | grep -m $i '"temperature":' | awk -F '[:]' '{print $2}' | awk -F ',' '{print $1}' | awk -F '[ ]' '{print $2}' | tail -n 1)
	done

	for i in {1..25}; do
		eval hourRain${i}a=$(cat 'db/TOD.json' | grep -m $i -A 2 '"probabilityOfPrecipitation' | awk -F '[:]' '{print $2}' | awk -F ',' '{print $1}' | awk -F '[ ]' '{print $2}' | tail -n 1)
	done

	convert_to_12_hour_format() {
		local hour=$1

    # remove leading zeros if present
		hour=${hour#0}

		if (( hour > 12 )); then
			hour=$((hour - 12))
			suffix="pm"
			else
			suffix="am"
		fi

		echo "$hour:00$suffix"
	}

	# generate Times
		hour=$hourRawTime1a
			hourTime1=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime2a
			hourTime2=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime3a
			hourTime3=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime4a
			hourTime4=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime5a
			hourTime5=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime6a
			hourTime6=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime7a
			hourTime7=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime8a
			hourTime8=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime9a
			hourTime9=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime10a
			hourTime10=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime11a
			hourTime11=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime12a
			hourTime12=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime13a
			hourTime13=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime14a
			hourTime14=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime15a
			hourTime15=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime16a
			hourTime16=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime17a
			hourTime17=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime18a
			hourTime18=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime19a
			hourTime19=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime20a
			hourTime20=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime21a
			hourTime21=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime22a
			hourTime22=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime23a
			hourTime23=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime24a
			hourTime24=$(convert_to_12_hour_format "$hour")
		hour=$hourRawTime25a
			hourTime25=$(convert_to_12_hour_format "$hour")

	# 7 day forecast staging
	# convert to american
	weeklyDate1=$(cat db/7day.json | grep generatedAt | awk -F '"' '{print $4}' | awk -F ':' '{print $1}' | awk -F 'T' '{print $1}' | awk -F '-' '{print $1}')
	weeklyDate2=$(cat db/7day.json | grep generatedAt | awk -F '"' '{print $4}' | awk -F ':' '{print $1}' | awk -F 'T' '{print $1}' | awk -F '-' '{print $2}')
	weeklyDate3=$(cat db/7day.json | grep generatedAt | awk -F '"' '{print $4}' | awk -F ':' '{print $1}' | awk -F 'T' '{print $1}' | awk -F '-' '{print $3}')
	weeklyDateFinal=$(echo $weeklyDate2-$weeklyDate3-$weeklyDate1)

	# weekly section / orobas loop
	awk '{printf "%s", $0}' "db/7day.json" > db/weekly/long.txt
	counter=100
	for ((i=1; i<=14; i++)); do
		((counter++))
		cat 'db/weekly/long.txt' | awk -F 'number' -v var="$i" '{print $var}' | awk '{ gsub(/,/, ",\n"); print }' > "db/weekly/$counter.txt"
	done
	directory="db/weekly"
	rm db/weekly/101.txt
	for file in "$directory"/*; do
		if grep -q "night" "$file"; then
			rm "$file"
		fi
	done
	for file in "$directory"/*; do
		if grep -q "Today" "$file"; then
			rm "$file"
		fi
	done
	for file in "$directory"/*; do
		if grep -q "name.*This\|This.*name" "$file"; then
			rm "$file"
		fi
	done
	# initialize counter
	counter=0
	for file in "$directory"/*; do
		((counter++))
		content=$(grep -i "name" "$file" | awk -F '"' '{print $4}')
		declare "weeklyName$counter=$content"
	done
	for ((i = 1; i <= counter; i++)); do
		var="weeklyName$i"
	done
	counter=0
	for file in "$directory"/*; do
		((counter++))
		content=$(grep -i "shortForecast" "$file" | awk -F '"' '{print $4}')
		declare "weeklyShort$counter=$content"
	done
	for ((i = 1; i <= counter; i++)); do
		var="weeklyShort$i"
	done
	counter=0
	for file in "$directory"/*; do
		((counter++))
		content=$(grep -A 10 -i "detailedForecast" "$file" | sed ':a;N;$!ba;s/\n//g' | awk -F '"' '{print $4}')
		declare "weeklyLong$counter=$content"
	done
	for ((i = 1; i <= counter; i++)); do
		var="weeklyLong$i"
	done
	counter=0
	for file in "$directory"/*; do
		((counter++))
    	content=$(grep -i '"temperature"' "$file" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}'| awk -F ',' '{print $1}')
        declare "weeklyTemp$counter=$content"
	done
	for ((i = 1; i <= counter; i++)); do
		var="weeklyTemp$i"
	done
	
	
	
	
	
# alert section

# File containing JSON data
json_file1="db/alerts.json"

# Get current time in ISO 8601 format
current_time1=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Function to parse alerts and check expiration
parse_alerts1() {
  local in_alert=false
  local expires=""
  local id=""
  local event=""
  local headline=""
  local severity=""
  local urgency=""
  local description=""
  local instruction=""

  while IFS= read -r line; do
    # Detect start of an alert

    # Capture event
    if [[ $line =~ \"event\": ]]; then
      event=$(echo "$line" | sed -E 's/.*"event": "([^"]+)".*/\1/')
    fi

    # Capture expires
    if [[ $line =~ \"expires\": ]]; then
      expires=$(echo "$line" | sed -E 's/.*"expires": "([^"]+)".*/\1/')
    fi

    # Capture headline
    if [[ $line =~ \"headline\": ]]; then
      headline=$(echo "$line" | sed -E 's/.*"headline": "([^"]+)".*/\1/')
    fi

    # Capture severity
    if [[ $line =~ \"severity\": ]]; then
      severity=$(echo "$line" | sed -E 's/.*"severity": "([^"]+)".*/\1/')
    fi

    # Capture urgency
    if [[ $line =~ \"urgency\": ]]; then
      urgency=$(echo "$line" | sed -E 's/.*"urgency": "([^"]+)".*/\1/')
    fi
	
	# Capture description
    if [[ $line =~ \"description\": ]]; then
      description=$(echo "$line" | sed -E 's/.*"description": "([^"]+)".*/\1/')
    fi

    # Capture instruction
    if [[ $line =~ \"instruction\": ]]; then
      instruction=$(echo "$line" | sed -E 's/.*"instruction": "([^"]+)".*/\1/')
    fi

    # If end of an alert is detected, check expiration
    if [[ $line =~ \"response\": ]]; then
      if [[ "$expires" > "$current_time" ]]; then
        echo "$event"
        echo "Expires: $expires"
        echo "$headline"
        echo "Severity: $severity"
        echo "Urgency: $urgency"
		echo "$description"
        echo "Instruction: $instruction"
        echo "-----------------------"
      fi
      # Reset variables
      id=""
      event=""
      expires=""
      headline=""
      severity=""
      urgency=""
	  description=""
      instruction=""
    fi
  done < "$json_file1"
}

# Run the 1stparser then the additional parser to ensure only active alerts are shown
echo " " > db/activealerts.txt
echo " " > db/activealerts1.json
parse_alerts1 > db/activealerts1.json
bash db/alertparser.sh




# write HTML content to a file
    cat <<EOF >db/frontEndraw.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloudsy</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        :root {
            --primary-pink: #ff7eb9;
            --primary-blue: #7cc0ff;
            --accent-pink: #ff65a3;
            --accent-blue: #5e9fff;
            --glass-dark: rgba(30, 33, 58, 0.8);
            --glass-border: rgba(255, 255, 255, 0.1);
            --glass-highlight: rgba(255, 255, 255, 0.05);
            --text-light: #f5f6fa;
            --text-dim: rgba(245, 246, 250, 0.7);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(-45deg, #1e203a, #252845, #2a2d54, #303865);
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
            color: var(--text-light);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .container {
            display: flex;
            gap: 20px;
            width: 100%;
            max-width: 1400px;
            height: 90vh;
        }
		
				        .containerhalf {
            display: column;
            gap: 20px;
            width: 30%;
            max-width: 1400px;
            height: 90vh;
			padding: 20px;
        }
        
        .card {
            background: var(--glass-dark);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-radius: 24px;
            border: 1px solid var(--glass-border);
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3);
            padding: 24px;
            overflow: hidden;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            opacity: 0;
            transform: translateY(20px);
        }
        
        .card:hover {
            transform: translateY(-5px) translateZ(0);
            box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
        }
        
        .weekly-forecast {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .current-weather {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
        }
        
        .hourly-forecast {
            flex: 1;
            overflow-y: auto;
        }
        
        h2, h3 {
            color: var(--text-light);
            margin-bottom: 16px;
            font-weight: 600;
        }
        
        h2 {
            font-size: 1.5rem;
            position: relative;
            display: inline-block;
        }
        
        h2::after {
            content: '';
            position: absolute;
            bottom: -4px;
            left: 0;
            width: 50px;
            height: 3px;
            background: linear-gradient(90deg, var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
        
        .weather-icon {
            width: 105%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .current-temp {
            font-size: 3rem;
            font-weight: 700;
            background: linear-gradient(45deg, var(--primary-pink), var(--primary-blue));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            margin: 8px 0;
            text-shadow: 0 4px 12px rgba(124, 192, 255, 0.2);
        }
        
        .weather-details {
            margin: 16px 0;
            width: 100%;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .detail-label {
            font-weight: 500;
            color: var(--text-dim);
        }
        
        .detail-value {
            font-weight: 600;
        }
        
        .radar-image {
            width: 100%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .forecast-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        
        .forecast-table th {
            text-align: left;
            padding: 12px 8px;
            font-weight: 500;
            color: var(--text-dim);
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-table td {
            padding: 12px 8px;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-day {
            font-weight: 600;
        }
        
        .forecast-temp {
            text-align: right;
            font-weight: 600;
            color: var(--primary-blue);
        }
        
        .forecast-desc {
            font-size: 0.9rem;
            line-height: 1.4;
            color: var(--text-dim);
        }
        
        .hourly-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
            transition: background 0.2s ease;
        }
        
        .hourly-row:hover {
            background: var(--glass-highlight);
        }
        
        .hourly-time {
            font-weight: 500;
            width: 80px;
        }
        
        .hourly-temp {
            font-weight: 600;
            width: 60px;
            text-align: center;
            color: var(--primary-pink);
        }
        
        .precip-chance {
            display: flex;
            align-items: center;
            width: 100px;
        }
        
        .precip-bar {
            height: 6px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
            margin-left: 8px;
            flex-grow: 1;
            position: relative;
            overflow: hidden;
        }
        
        .precip-fill {
            position: absolute;
            top: 0;
            left: 0;
            height: 100%;
            background: linear-gradient(90deg, var(--accent-pink), var(--accent-blue));
            border-radius: 3px;
        }
        
        .precip-value {
            font-size: 0.8rem;
            font-weight: 500;
            color: var(--primary-blue);
        }
        
        .condition-highlight {
            color: var(--primary-pink);
            font-weight: 600;
        }
        
        @media (max-width: 1024px) {
            .container {
                flex-direction: column;
                height: auto;
            }
            
            .card {
                margin-bottom: 20px;
            }
        }
        
        /* Scrollbar styling */
        ::-webkit-scrollbar {
            width: 6px;
        }
        
        ::-webkit-scrollbar-track {
            background: rgba(0, 0, 0, 0.1);
            border-radius: 3px;
        }
        
        ::-webkit-scrollbar-thumb {
            background: linear-gradient(var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
    </style>
</head>
<body id="hereisthealerttag">
    <div class="container">
        <div class="card weekly-forecast">
            <h2>Weekly Forecast</h2>
            <table class="forecast-table">
                <tr>
                    <td class="forecast-day">$weeklyName1</td>
                    <td class="forecast-temp">$weeklyTemp1°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong1</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName2</td>
                    <td class="forecast-temp">$weeklyTemp2°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong2</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName3</td>
                    <td class="forecast-temp">$weeklyTemp3°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong3</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName4</td>
                    <td class="forecast-temp">$weeklyTemp4°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong4</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName5</td>
                    <td class="forecast-temp">$weeklyTemp5°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong5</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName6</td>
                    <td class="forecast-temp">$weeklyTemp6°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong6</td>
                </tr>
            </table>
        </div>
        
        <div class="card current-weather">
            <img src="logo.gif" alt="Cloudsy" class="weather-icon">
            <div class="current-temp">$currenttemp°F</div>
            <h3>$currentcity</h3>
            <p><span class="condition-highlight">$currentcondition</span></p>
            
            <div class="weather-details">
                <div class="detail-row">
                    <span class="detail-label">Radar Station</span>
                    <span class="detail-value">$currentstation</span>
                </div>
            </div>
            
            <img src="radar.gif" alt="Radar Image Unavailable" class="radar-image">
            
            <p style="font-size: 0.9rem; color: var(--text-dim); margin-top: 8px;">
                $currentcond
            </p>
        </div>
        
        <div class="card hourly-forecast">
            <h2>Hourly Forecast</h2>
            <div class="hourly-scroll">
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime1</span>
                    <span class="hourly-temp">$hourTemp1a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain1a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain1a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime2</span>
                    <span class="hourly-temp">$hourTemp2a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain2a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain2a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime3</span>
                    <span class="hourly-temp">$hourTemp3a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain3a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain3a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime4</span>
                    <span class="hourly-temp">$hourTemp4a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain4a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain4a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime5</span>
                    <span class="hourly-temp">$hourTemp5a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain5a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain5a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime6</span>
                    <span class="hourly-temp">$hourTemp6a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain6a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain6a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime7</span>
                    <span class="hourly-temp">$hourTemp7a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain7a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain7a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime8</span>
                    <span class="hourly-temp">$hourTemp8a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain8a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain8a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime9</span>
                    <span class="hourly-temp">$hourTemp9a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain9a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain9a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime10</span>
                    <span class="hourly-temp">$hourTemp10a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain10a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain10a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime11</span>
                    <span class="hourly-temp">$hourTemp11a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain11a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain11a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime12</span>
                    <span class="hourly-temp">$hourTemp12a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain12a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain12a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime13</span>
                    <span class="hourly-temp">$hourTemp13a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain13a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain13a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime14</span>
                    <span class="hourly-temp">$hourTemp14a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain14a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain14a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime15</span>
                    <span class="hourly-temp">$hourTemp15a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain15a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain15a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime16</span>
                    <span class="hourly-temp">$hourTemp16a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain16a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain16a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime17</span>
                    <span class="hourly-temp">$hourTemp17a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain17a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain17a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime18</span>
                    <span class="hourly-temp">$hourTemp18a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain18a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain18a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime19</span>
                    <span class="hourly-temp">$hourTemp19a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain19a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain19a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime20</span>
                    <span class="hourly-temp">$hourTemp20a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain20a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain20a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime21</span>
                    <span class="hourly-temp">$hourTemp21a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain21a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain21a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime22</span>
                    <span class="hourly-temp">$hourTemp22a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain22a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain22a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime23</span>
                    <span class="hourly-temp">$hourTemp23a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain23a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain23a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime24</span>
                    <span class="hourly-temp">$hourTemp24a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain24a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain24a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime25</span>
                    <span class="hourly-temp">$hourTemp25a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain25a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain25a%;"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript to refresh the page every 10 minutes -->
    <script>
        setTimeout(function(){
            location.reload();
        }, 610000); // Refresh every 10 minutes (600,000 milliseconds)
        
        // Add animation to cards on load
        document.addEventListener('DOMContentLoaded', function() {
            const cards = document.querySelectorAll('.card');
            cards.forEach((card, index) => {
                setTimeout(() => {
                    card.style.opacity = '1';
                    card.style.transform = 'translateY(0)';
                }, index * 100);
            });
        });
    </script>
</body>
</html>


EOF

# write HTML content to a file
    cat <<EOF >db/frontEndmobileraw.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloudsy</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        :root {
            --primary-pink: #ff7eb9;
            --primary-blue: #7cc0ff;
            --accent-pink: #ff65a3;
            --accent-blue: #5e9fff;
            --glass-dark: rgba(30, 33, 58, 0.8);
            --glass-border: rgba(255, 255, 255, 0.1);
            --glass-highlight: rgba(255, 255, 255, 0.05);
            --text-light: #f5f6fa;
            --text-dim: rgba(245, 246, 250, 0.7);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(-45deg, #1e203a, #252845, #2a2d54, #303865);
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
            color: var(--text-light);
            min-height: 100vh;
            display: grid;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .container {
            display: column;
            gap: 20px;
            width: 100%;
            max-width: 1400px;
            height: 90vh;
        }
		
		        .containerhalf {
            display: column;
            gap: 20px;
            width: 100%;
            max-width: 100%;
            height: 100%;
			padding: 20px;
        }
        
        .card {
            background: var(--glass-dark);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-radius: 24px;
            border: 1px solid var(--glass-border);
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3);
            padding: 24px;
            overflow: hidden;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            opacity: 0;
            transform: translateY(20px);
        }
        
        .card:hover {
            transform: translateY(-5px) translateZ(0);
            box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
        }
        
        .weekly-forecast {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .current-weather {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
        }
        
        .hourly-forecast {
            flex: 1;
            overflow-y: auto;
        }
        
        h2, h3 {
            color: var(--text-light);
            margin-bottom: 16px;
            font-weight: 600;
        }
        
        h2 {
            font-size: 1.5rem;
            position: relative;
            display: inline-block;
        }
        
        h2::after {
            content: '';
            position: absolute;
            bottom: -4px;
            left: 0;
            width: 50px;
            height: 3px;
            background: linear-gradient(90deg, var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
        
        .weather-icon {
            width: 100%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .current-temp {
            font-size: 3rem;
            font-weight: 700;
            background: linear-gradient(45deg, var(--primary-pink), var(--primary-blue));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            margin: 8px 0;
            text-shadow: 0 4px 12px rgba(124, 192, 255, 0.2);
        }
        
        .weather-details {
            margin: 16px 0;
            width: 100%;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .detail-label {
            font-weight: 500;
            color: var(--text-dim);
        }
        
        .detail-value {
            font-weight: 600;
        }
        
        .radar-image {
            width: 100%;
            max-width: 500px;
            border-radius: 12px;
            margin: 16px 0;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
            border: 1px solid var(--glass-border);
        }
        
        .forecast-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        
        .forecast-table th {
            text-align: left;
            padding: 12px 8px;
            font-weight: 500;
            color: var(--text-dim);
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-table td {
            padding: 12px 8px;
            border-bottom: 1px solid var(--glass-border);
        }
        
        .forecast-day {
            font-weight: 600;
        }
        
        .forecast-temp {
            text-align: right;
            font-weight: 600;
            color: var(--primary-blue);
        }
        
        .forecast-desc {
            font-size: 0.9rem;
            line-height: 1.4;
            color: var(--text-dim);
        }
        
        .hourly-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--glass-border);
            transition: background 0.2s ease;
        }
        
        .hourly-row:hover {
            background: var(--glass-highlight);
        }
        
        .hourly-time {
            font-weight: 500;
            width: 80px;
        }
        
        .hourly-temp {
            font-weight: 600;
            width: 60px;
            text-align: center;
            color: var(--primary-pink);
        }
        
        .precip-chance {
            display: flex;
            align-items: center;
            width: 100px;
        }
        
        .precip-bar {
            height: 6px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
            margin-left: 8px;
            flex-grow: 1;
            position: relative;
            overflow: hidden;
        }
        
        .precip-fill {
            position: absolute;
            top: 0;
            left: 0;
            height: 100%;
            background: linear-gradient(90deg, var(--accent-pink), var(--accent-blue));
            border-radius: 3px;
        }
        
        .precip-value {
            font-size: 0.8rem;
            font-weight: 500;
            color: var(--primary-blue);
        }
        
        .condition-highlight {
            color: var(--primary-pink);
            font-weight: 600;
        }
        
        @media (max-width: 1024px) {
            .container {
                flex-direction: column;
                height: auto;
            }
            
            .card {
                margin-bottom: 20px;
            }
        }
        
        /* Scrollbar styling */
        ::-webkit-scrollbar {
            width: 6px;
        }
        
        ::-webkit-scrollbar-track {
            background: rgba(0, 0, 0, 0.1);
            border-radius: 3px;
        }
        
        ::-webkit-scrollbar-thumb {
            background: linear-gradient(var(--primary-pink), var(--primary-blue));
            border-radius: 3px;
        }
    </style>
</head>
<body id="hereisthealerttag">
    <div class="container">
        <div class="card current-weather">
            <img src="logo.gif" alt="Cloudsy" class="weather-icon">
            <div class="current-temp">$currenttemp°F</div>
            <h3>$currentcity</h3>
            <p><span class="condition-highlight">$currentcondition</span></p>
            
            <div class="weather-details">
                <div class="detail-row">
                    <span class="detail-label">Radar Station</span>
                    <span class="detail-value">$currentstation</span>
                </div>
            </div>
            
            <img src="radar.gif" alt="Radar Image Unavailable" class="radar-image">
            
            <p style="font-size: 0.9rem; color: var(--text-dim); margin-top: 8px;">
                $currentcond
            </p>
        </div>
		
		<div class="card weekly-forecast">
            <h2>Weekly Forecast</h2>
            <table class="forecast-table">
                <tr>
                    <td class="forecast-day">$weeklyName1</td>
                    <td class="forecast-temp">$weeklyTemp1°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong1</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName2</td>
                    <td class="forecast-temp">$weeklyTemp2°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong2</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName3</td>
                    <td class="forecast-temp">$weeklyTemp3°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong3</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName4</td>
                    <td class="forecast-temp">$weeklyTemp4°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong4</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName5</td>
                    <td class="forecast-temp">$weeklyTemp5°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong5</td>
                </tr>
                <tr>
                    <td class="forecast-day">$weeklyName6</td>
                    <td class="forecast-temp">$weeklyTemp6°F</td>
                </tr>
                <tr>
                    <td colspan="2" class="forecast-desc">$weeklyLong6</td>
                </tr>
            </table>
        </div>
        
        <div class="card hourly-forecast">
            <h2>Hourly Forecast</h2>
            <div class="hourly-scroll">
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime1</span>
                    <span class="hourly-temp">$hourTemp1a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain1a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain1a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime2</span>
                    <span class="hourly-temp">$hourTemp2a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain2a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain2a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime3</span>
                    <span class="hourly-temp">$hourTemp3a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain3a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain3a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime4</span>
                    <span class="hourly-temp">$hourTemp4a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain4a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain4a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime5</span>
                    <span class="hourly-temp">$hourTemp5a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain5a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain5a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime6</span>
                    <span class="hourly-temp">$hourTemp6a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain6a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain6a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime7</span>
                    <span class="hourly-temp">$hourTemp7a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain7a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain7a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime8</span>
                    <span class="hourly-temp">$hourTemp8a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain8a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain8a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime9</span>
                    <span class="hourly-temp">$hourTemp9a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain9a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain9a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime10</span>
                    <span class="hourly-temp">$hourTemp10a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain10a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain10a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime11</span>
                    <span class="hourly-temp">$hourTemp11a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain11a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain11a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime12</span>
                    <span class="hourly-temp">$hourTemp12a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain12a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain12a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime13</span>
                    <span class="hourly-temp">$hourTemp13a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain13a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain13a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime14</span>
                    <span class="hourly-temp">$hourTemp14a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain14a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain14a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime15</span>
                    <span class="hourly-temp">$hourTemp15a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain15a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain15a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime16</span>
                    <span class="hourly-temp">$hourTemp16a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain16a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain16a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime17</span>
                    <span class="hourly-temp">$hourTemp17a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain17a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain17a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime18</span>
                    <span class="hourly-temp">$hourTemp18a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain18a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain18a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime19</span>
                    <span class="hourly-temp">$hourTemp19a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain19a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain19a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime20</span>
                    <span class="hourly-temp">$hourTemp20a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain20a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain20a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime21</span>
                    <span class="hourly-temp">$hourTemp21a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain21a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain21a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime22</span>
                    <span class="hourly-temp">$hourTemp22a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain22a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain22a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime23</span>
                    <span class="hourly-temp">$hourTemp23a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain23a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain23a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime24</span>
                    <span class="hourly-temp">$hourTemp24a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain24a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain24a%;"></div>
                        </div>
                    </div>
                </div>
                <div class="hourly-row">
                    <span class="hourly-time">$hourTime25</span>
                    <span class="hourly-temp">$hourTemp25a°F</span>
                    <div class="precip-chance">
                        <span class="precip-value">$hourRain25a%</span>
                        <div class="precip-bar">
                            <div class="precip-fill" style="width: $hourRain25a%;"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript to refresh the page every 10 minutes -->
    <script>
        setTimeout(function(){
            location.reload();
        }, 610000); // Refresh every 10 minutes (600,000 milliseconds)
        
        // Add animation to cards on load
        document.addEventListener('DOMContentLoaded', function() {
            const cards = document.querySelectorAll('.card');
            cards.forEach((card, index) => {
                setTimeout(() => {
                    card.style.opacity = '1';
                    card.style.transform = 'translateY(0)';
                }, index * 100);
            });
        });
    </script>
</body>
</html>


EOF




# modfied the alerts and then injects alerts into the page if any are active
if (( $(wc -l < db/activealerts.txt) > 13 )); then
sed -i -E 's/\\n\\n/\n/g; s/\\n/ /g' db/activealerts.txt
sed -i '9,$s/\(.*\)/<p>\1<\/p>/' db/activealerts.txt
sed -i '1i<div>' db/activealerts.txt
sed -i '1i<div class="containerhalf">' db/activealerts.txt
echo '</div>' >> db/activealerts.txt
echo '</div>' >> db/activealerts.txt




# Find the line number of the exact match.
line=$(grep -n '<body id="hereisthealerttag">$' db/frontEndraw.html | cut -d: -f1)

if [ -n "$line" ]; then
  # Create a temporary file.
  tmpfile=$(mktemp)

  # Write the lines up to (and including) the matching line.
  head -n "$line" db/frontEndraw.html > "$tmpfile"

  # Append the contents of db/activealerts.txt.
  cat db/activealerts.txt >> "$tmpfile"

  # Append the remainder of the file.
  tail -n +$((line + 1)) db/frontEndraw.html >> "$tmpfile"

  # Replace the original file with the updated file.
  mv "$tmpfile" db/frontEndraw.html
fi




# Find the line number of the exact match mobile.
line=$(grep -n '<body id="hereisthealerttag">$' db/frontEndmobileraw.html | cut -d: -f1)

if [ -n "$line" ]; then
  # Create a temporary file.
  tmpfile2=$(mktemp)

  # Write the lines up to (and including) the matching line.
  head -n "$line" db/frontEndmobileraw.html > "$tmpfile2"

  # Append the contents of db/activealerts.txt.
  cat db/activealerts.txt >> "$tmpfile2"

  # Append the remainder of the file.
  tail -n +$((line + 1)) db/frontEndmobileraw.html >> "$tmpfile2"

  # Replace the original file with the updated file.
  mv "$tmpfile2" db/frontEndmobileraw.html
fi

fi








	# microversion engage
	bash db/micro.sh

	# fix the words
	awk '{if (gsub("Cloudy", "Cloudsy")) print; else print $0}' db/frontEndraw.html > db/frontEnd1.html
	awk '{if (gsub("cloudy", "cloudsy")) print; else print $0}' db/frontEnd1.html > db/frontEnd.html

		# fix the words mobile
	awk '{if (gsub("Cloudy", "Cloudsy")) print; else print $0}' db/frontEndmobileraw.html > db/frontEndmobile1.html
	awk '{if (gsub("cloudy", "cloudsy")) print; else print $0}' db/frontEndmobile1.html > db/frontEndmobile.html

	# cleanup
	rm db/frontEndraw.html
	rm db/frontEnd1.html
	rm db/frontEndmobileraw.html
	rm db/frontEndmobile1.html

	# wait for 600 seconds (10 minutes) before fetching data again
	echo "  will refresh in 10 minutes..."
    sleep 600
done