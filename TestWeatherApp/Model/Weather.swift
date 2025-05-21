import Foundation

struct Weather: Codable {
    let location: Location
    let current: Current
    let forecast: Forecast
}

extension Weather {
    struct Location: Codable {
        let name: String
    }
    
    struct Current: Codable {
        let tempC: Double
        let condition: Condition
        
        enum CodingKeys: String, CodingKey {
            case tempC = "temp_c"
            case condition = "condition"
        }
    }
    
    struct Condition: Codable {
        let text: String
    }
    
    struct Forecast: Codable {
        let forecastday: [Forecastday]
    }
    
    struct Forecastday: Codable {
        let date: String
        let day: Day
        let hours: [Hours]
        
        enum CodingKeys: String, CodingKey {
            case date = "date"
            case day = "day"
            case hours = "hour"
        }
    }
    
    struct Hours: Codable {
        let time: String
        let tempC: Double
        let condition: Condition
        
        enum CodingKeys: String, CodingKey {
            case time = "time"
            case tempC = "temp_c"
            case condition = "condition"
        }
    }
    
    struct Day: Codable {
        let maxTempC: Double
        let minTempC: Double
        //let temp: Double
        
        enum CodingKeys: String, CodingKey {
            case maxTempC = "maxtemp_c"
            case minTempC = "mintemp_c"
            //case temp = "avgtemp_c"
        }
    }
}

extension Weather {
    static var mock: Weather {
        Weather(location: Location(name: "Москва"),
                current:
                    Current(tempC: 24,
                            condition: Condition(text: "Ясно")),
                forecast: Forecast(forecastday: [Forecastday(date: String(describing: Date.now),
                                                             day: Day(maxTempC: 20,
                                                                      minTempC: 11),
                                                             hours: [Hours(time: String(describing: Date.now),
                                                                           tempC: 11,
                                                                           condition: Condition(text: "Ясно"))])]))
    }
}
