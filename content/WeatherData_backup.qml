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
    
    // Geolocation properties
    property real latitude: 0.0
    property real longitude: 0.0
    property bool locationAvailable: false
    property bool isLoadingWeather: false
    
    // Timer properties for manual control
    property int updateInterval: 300000 // 5 minutes
    property bool timerRunning: false
    
    // Function to fetch weather data from Open-Meteo API
    function fetchWeatherData() {
        if (!locationAvailable && latitude === 0.0 && longitude === 0.0) {
            console.log("No location available for weather fetch")
            return
        }
        
        isLoadingWeather = true
        
        var url = "https://api.open-meteo.com/v1/forecast?" +
                  "latitude=" + latitude +
                  "&longitude=" + longitude +
                  "&current=temperature_2m,weather_code,is_day" +
                  "&timezone=auto"
        
        console.log("Fetching weather from:", url)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingWeather = false
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        console.log("Weather response:", JSON.stringify(response))
                        
                        if (response.current) {
                            currentTemperature = Math.round(response.current.temperature_2m * 10) / 10
                            weatherCode = response.current.weather_code
                            isDay = response.current.is_day === 1
                            
                            // Update weather description and icon
                            updateWeatherDescription()
                            updateWeatherIcon()
                        }
                    } catch (e) {
                        console.log("Error parsing weather response:", e)
                        weatherDescription = "Error loading weather"
                    }
                } else {
                    console.log("Weather API error:", xhr.status, xhr.statusText)
                    weatherDescription = "Failed to load weather"
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }
    
    // Function to fetch city name from coordinates (reverse geocoding)
    function fetchCityName() {
        var url = "https://api.bigdatacloud.net/data/reverse-geocode-client?" +
                  "latitude=" + latitude +
                  "&longitude=" + longitude +
                  "&localityLanguage=en"
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.city) {
                            currentLocation = response.city
                        } else if (response.locality) {
                            currentLocation = response.locality
                        } else if (response.principalSubdivision) {
                            currentLocation = response.principalSubdivision
                        } else {
                            currentLocation = "Unknown Location"
                        }
                        console.log("Location updated:", currentLocation)
                    } catch (e) {
                        console.log("Error parsing location response:", e)
                        currentLocation = "Unknown Location"
                    }
                } else {
                    console.log("Geocoding API error:", xhr.status)
                    currentLocation = "Unknown Location"
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
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
        
        weatherDescription = descriptions[weatherCode] || "Unknown weather"
    }
    
    // Function to update weather icon based on weather code and day/night
    function updateWeatherIcon() {
        updateDayNight()
        
        var codeStr = weatherCode.toString()
        if (weatherIcons[codeStr]) {
            var iconData = weatherIcons[codeStr]
            if (isDay && iconData.day && iconData.day.image) {
                weatherIconUrl = iconData.day.image
            } else if (!isDay && iconData.night && iconData.night.image) {
                weatherIconUrl = iconData.night.image
            } else {
                // Fallback to sunny/clear
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/01d@2x.png" : 
                    "http://openweathermap.org/img/wn/01n@2x.png"
            }
        } else {
            // Fallback based on weather code ranges
            if (weatherCode === 0 || weatherCode === 1) {
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/01d@2x.png" : 
                    "http://openweathermap.org/img/wn/01n@2x.png"
            } else if (weatherCode === 2) {
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/02d@2x.png" : 
                    "http://openweathermap.org/img/wn/02n@2x.png"
            } else if (weatherCode === 3) {
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/03d@2x.png" : 
                    "http://openweathermap.org/img/wn/03n@2x.png"
            } else if (weatherCode >= 51 && weatherCode <= 67) {
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/10d@2x.png" : 
                    "http://openweathermap.org/img/wn/10n@2x.png"
            } else if (weatherCode >= 71 && weatherCode <= 86) {
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/13d@2x.png" : 
                    "http://openweathermap.org/img/wn/13n@2x.png"
            } else if (weatherCode >= 95) {
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/11d@2x.png" : 
                    "http://openweathermap.org/img/wn/11n@2x.png"
            } else {
                // Default fallback
                weatherIconUrl = isDay ? 
                    "http://openweathermap.org/img/wn/01d@2x.png" : 
                    "http://openweathermap.org/img/wn/01n@2x.png"
            }
        }
    }
    
    // Function to load weather icons from JSON file
    function loadWeatherIcons() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        weatherIcons = JSON.parse(xhr.responseText)
                        console.log("Weather icons loaded successfully")
                        // Update weather icon if we already have weather data
                        if (weatherCode !== 0 || currentTemperature !== 22.0) {
                            updateWeatherIcon()
                        }
                    } catch (e) {
                        console.log("Error parsing weather_icon.json:", e)
                        // Use fallback icons
                        initializeFallbackIcons()
                    }
                } else {
                    console.log("Error loading weather_icon.json, using fallback")
                    initializeFallbackIcons()
                }
            }
        }
        xhr.open("GET", "weather_icon.json")
        xhr.send()
    }
    
    // Fallback weather icons in case JSON loading fails
    function initializeFallbackIcons() {
        weatherIcons = {
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
        if (weatherCode !== 0 || currentTemperature !== 22.0) {
            updateWeatherIcon()
        }
    }
    
    // Function to check if it's day or night based on current time (fallback if API doesn't provide this)
    function updateDayNight() {
        var currentHour = new Date().getHours()
        isDay = currentHour >= 6 && currentHour < 18 // Consider day from 6 AM to 6 PM
    }
    
    // Function to refresh weather data manually
    function refreshWeather() {
        if (locationAvailable) {
            fetchWeatherData()
        } else {
            // Use fallback location and fetch data
            latitude = 40.7128
            longitude = -74.0060
            currentLocation = "New York (Default)"
            locationAvailable = true
            fetchWeatherData()
        }
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
        
        // Start with a fallback location for immediate data
        refreshWeather()
    }
}
