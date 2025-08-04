import QtQuick 6.4
import QtPositioning 6.4

Item {
    id: weatherData
    
    // Properties for weather information
    property string currentLocation: "Unknown Location"
    property real currentTemperature: 22.0
    property int weatherCode: 0 // Weather code from open-meteo API
    property bool isDay: true
    property string weatherDescription: "Loading..."
    property string weatherIconUrl: "http://openweathermap.org/img/wn/02d@2x.png" // Default partly cloudy icon
    property var weatherIcons: ({}) // Will be loaded from JSON
    
    // Time properties
    property string currentTime: "12:00 PM"
    property string currentDate: "January 1"
    
    // Geolocation properties
    property real latitude: 40.7128 // Default to New York
    property real longitude: -74.0060
    property bool locationAvailable: true
    property bool isLoadingWeather: false
    
    // Geolocation source (optional - can be enabled when geolocation is needed)
    PositionSource {
        id: positionSource
        updateInterval: 60000 // Update every minute
        active: false // Start disabled to avoid SSL issues, can be enabled by user
        
        onPositionChanged: {
            weatherData.latitude = position.coordinate.latitude
            weatherData.longitude = position.coordinate.longitude
            weatherData.locationAvailable = true
            console.log("Position updated:", weatherData.latitude, weatherData.longitude)
            
            // Fetch weather data when position is available
            weatherData.fetchWeatherData()
            
            // Get city name from coordinates (reverse geocoding)
            weatherData.fetchCityName()
        }
        
        onSourceErrorChanged: {
            if (sourceError !== PositionSource.NoError) {
                console.log("Position source error:", sourceError)
                weatherData.locationAvailable = false
                // Use fallback location (e.g., New York)
                weatherData.latitude = 40.7128
                weatherData.longitude = -74.0060
                weatherData.currentLocation = "New York (Default)"
                weatherData.fetchWeatherData()
            }
        }
    }
    
    // Function to enable geolocation
    function enableGeolocation() {
        positionSource.active = true
        console.log("GPS geolocation enabled")
    }
    
    // Function to disable geolocation
    function disableGeolocation() {
        positionSource.active = false
        console.log("GPS geolocation disabled")
    }
    
    // Function to use IP-based geolocation instead of GPS
    function useIPGeolocation() {
        disableGeolocation() // Disable GPS
        fetchLocationByIP()
        console.log("Switched to IP-based geolocation")
    }
    
    // Timer to update current time every second
    Timer {
        id: timeUpdateTimer
        interval: 1000 // Update every second
        running: true
        repeat: true
        onTriggered: weatherData.updateCurrentTime()
    }
    
    // Function to update current time
    function updateCurrentTime() {
        var now = new Date()
        var hours = now.getHours()
        var minutes = now.getMinutes()
        var ampm = hours >= 12 ? 'PM' : 'AM'
        
        // Convert to 12-hour format
        hours = hours % 12
        hours = hours ? hours : 12 // the hour '0' should be '12'
        
        // Pad minutes with leading zero if needed
        minutes = minutes < 10 ? '0' + minutes : minutes
        
        currentTime = hours + ':' + minutes + ' ' + ampm
        
        // Update date
        var months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        currentDate = months[now.getMonth()] + " " + now.getDate()
    }
    
    // Function to fetch weather data from Open-Meteo API
    function fetchWeatherData() {
        if (!weatherData.locationAvailable && weatherData.latitude === 0.0 && weatherData.longitude === 0.0) {
            console.log("No location available for weather fetch")
            return
        }
        
        weatherData.isLoadingWeather = true
        
        var url = "http://api.open-meteo.com/v1/forecast?" +
                  "latitude=" + weatherData.latitude +
                  "&longitude=" + weatherData.longitude +
                  "&current=temperature_2m,weather_code,is_day" +
                  "&timezone=auto"
        
        console.log("Fetching weather from:", url)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                weatherData.isLoadingWeather = false
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        console.log("Weather response:", JSON.stringify(response))
                        
                        if (response.current) {
                            weatherData.currentTemperature = Math.round(response.current.temperature_2m * 10) / 10
                            weatherData.weatherCode = response.current.weather_code
                            weatherData.isDay = response.current.is_day === 1
                            
                            // Update weather description and icon
                            updateWeatherDescription()
                            updateWeatherIcon()
                        }
                    } catch (e) {
                        console.log("Error parsing weather response:", e)
                        weatherData.weatherDescription = "Error loading weather"
                    }
                } else {
                    console.log("Weather API error:", xhr.status, xhr.statusText)
                    weatherData.weatherDescription = "Failed to load weather"
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }
    
    // Function to fetch city name from coordinates (reverse geocoding)
    function fetchCityName() {
        // For now, set a default name based on coordinates
        // Real geocoding would require HTTPS which has SSL issues in this environment
        if (Math.abs(weatherData.latitude - 40.7128) < 1 && Math.abs(weatherData.longitude - (-74.0060)) < 1) {
            weatherData.currentLocation = "New York"
        } else if (Math.abs(weatherData.latitude - 51.5074) < 1 && Math.abs(weatherData.longitude - (-0.1278)) < 1) {
            weatherData.currentLocation = "London"
        } else if (Math.abs(weatherData.latitude - 35.6762) < 1 && Math.abs(weatherData.longitude - 139.6503) < 1) {
            weatherData.currentLocation = "Tokyo"
        } else {
            weatherData.currentLocation = "Location (" + weatherData.latitude.toFixed(2) + ", " + weatherData.longitude.toFixed(2) + ")"
        }
        console.log("Location set to:", weatherData.currentLocation)
    }
    
    // Function to get location by IP address
    function fetchLocationByIP() {
        console.log("Fetching location by IP address...")
        
        // Try ip-api.com first (free service with HTTP support)
        var url = "http://ip-api.com/json/"
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        console.log("IP location response:", JSON.stringify(response))
                        
                        if (response.status === "success") {
                            weatherData.latitude = response.lat
                            weatherData.longitude = response.lon
                            weatherData.currentLocation = response.city + ", " + response.region
                            weatherData.locationAvailable = true
                            
                            console.log("Location by IP:", weatherData.currentLocation)
                            console.log("Coordinates:", weatherData.latitude, weatherData.longitude)
                            
                            // Fetch weather data for the detected location
                            fetchWeatherData()
                        } else {
                            console.log("IP location failed:", response.message)
                            fallbackToDefaultLocation()
                        }
                    } catch (e) {
                        console.log("Error parsing IP location response:", e)
                        fallbackToDefaultLocation()
                    }
                } else {
                    console.log("IP location API error:", xhr.status)
                    fallbackToDefaultLocation()
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }
    
    // Fallback to default location when IP geolocation fails
    function fallbackToDefaultLocation() {
        console.log("Using fallback location")
        weatherData.latitude = 40.7128
        weatherData.longitude = -74.0060
        weatherData.currentLocation = "New York (Default)"
        weatherData.locationAvailable = true
        fetchWeatherData()
    }
    
    // Function to update weather description based on weather code
    function updateWeatherDescription() {
        var descriptions = {
            0: "Clear sky",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",
            45: "Fog",
            48: "Depositing rime fog",
            51: "Light drizzle",
            53: "Moderate drizzle",
            55: "Dense drizzle",
            56: "Light freezing drizzle",
            57: "Dense freezing drizzle",
            61: "Slight rain",
            63: "Moderate rain",
            65: "Heavy rain",
            66: "Light freezing rain",
            67: "Heavy freezing rain",
            71: "Slight snow fall",
            73: "Moderate snow fall",
            75: "Heavy snow fall",
            77: "Snow grains",
            80: "Slight rain showers",
            81: "Moderate rain showers",
            82: "Violent rain showers",
            85: "Slight snow showers",
            86: "Heavy snow showers",
            95: "Thunderstorm",
            96: "Thunderstorm with slight hail",
            99: "Thunderstorm with heavy hail"
        }
        
        weatherData.weatherDescription = descriptions[weatherData.weatherCode] || "Unknown weather"
    }
    
    // Function to update weather icon based on weather code and day/night
    function updateWeatherIcon() {
        updateDayNight()
        
        var codeStr = weatherData.weatherCode.toString()
        if (weatherData.weatherIcons[codeStr]) {
            var iconData = weatherData.weatherIcons[codeStr]
            if (weatherData.isDay && iconData.day && iconData.day.image) {
                weatherData.weatherIconUrl = iconData.day.image
            } else if (!weatherData.isDay && iconData.night && iconData.night.image) {
                weatherData.weatherIconUrl = iconData.night.image
            } else {
                // Fallback to sunny/clear
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/01d@2x.png" : 
                    "http://openweathermap.org/img/wn/01n@2x.png"
            }
        } else {
            // Fallback based on weather code ranges
            if (weatherData.weatherCode === 0 || weatherData.weatherCode === 1) {
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/01d@2x.png" : 
                    "http://openweathermap.org/img/wn/01n@2x.png"
            } else if (weatherData.weatherCode === 2) {
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/02d@2x.png" : 
                    "http://openweathermap.org/img/wn/02n@2x.png"
            } else if (weatherData.weatherCode === 3) {
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/03d@2x.png" : 
                    "http://openweathermap.org/img/wn/03n@2x.png"
            } else if (weatherData.weatherCode >= 51 && weatherData.weatherCode <= 67) {
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/10d@2x.png" : 
                    "http://openweathermap.org/img/wn/10n@2x.png"
            } else if (weatherData.weatherCode >= 71 && weatherData.weatherCode <= 86) {
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/13d@2x.png" : 
                    "http://openweathermap.org/img/wn/13n@2x.png"
            } else if (weatherData.weatherCode >= 95) {
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/11d@2x.png" : 
                    "http://openweathermap.org/img/wn/11n@2x.png"
            } else {
                // Default fallback
                weatherData.weatherIconUrl = weatherData.isDay ? 
                    "http://openweathermap.org/img/wn/01d@2x.png" : 
                    "http://openweathermap.org/img/wn/01n@2x.png"
            }
        }
    }
    
    // Function to load weather icons from JSON file
    function loadWeatherIcons() {
        // For now, use fallback icons directly since local file loading has restrictions
        console.log("Initializing weather icons...")
        initializeFallbackIcons()
    }
    // Fallback weather icons in case JSON loading fails
    function initializeFallbackIcons() {
        weatherData.weatherIcons = {
            "0": { day: { image: "http://openweathermap.org/img/wn/01d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/01n@2x.png" } },
            "1": { day: { image: "http://openweathermap.org/img/wn/01d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/01n@2x.png" } },
            "2": { day: { image: "http://openweathermap.org/img/wn/02d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/02n@2x.png" } },
            "3": { day: { image: "http://openweathermap.org/img/wn/03d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/03n@2x.png" } },
            "61": { day: { image: "http://openweathermap.org/img/wn/10d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/10n@2x.png" } },
            "71": { day: { image: "http://openweathermap.org/img/wn/13d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/13n@2x.png" } },
            "95": { day: { image: "http://openweathermap.org/img/wn/11d@2x.png" }, night: { image: "http://openweathermap.org/img/wn/11n@2x.png" } }
        }
        console.log("Using fallback weather icons")
        // Update weather icon if we already have weather data
        if (weatherData.weatherCode !== 0 || weatherData.currentTemperature !== 22.0) {
            updateWeatherIcon()
        }
    }
    
    // Function to check if it's day or night based on current time (fallback if API doesn't provide this)
    function updateDayNight() {
        var currentHour = new Date().getHours()
        weatherData.isDay = currentHour >= 6 && currentHour < 18 // Consider day from 6 AM to 6 PM
    }
    
    // Function to refresh weather data manually
    function refreshWeather() {
        fetchLocationByIP() // This will also fetch weather data
    }
    
    // Function to cycle through locations (for demo purposes) - now refreshes real data
    function nextLocation() {
        refreshWeather()
    }
    
    // Manual location setter for testing
    function setLocation(lat, lon) {
        latitude = lat
        longitude = lon
        locationAvailable = true
        fetchWeatherData()
        fetchCityName()
    }
    
    // Initialize weather data
    Component.onCompleted: {
        loadWeatherIcons() // Load icons from JSON first
        updateCurrentTime() // Set initial time
        
        // Try to get location by IP first, fallback to default if it fails
        fetchLocationByIP()
    }
}
