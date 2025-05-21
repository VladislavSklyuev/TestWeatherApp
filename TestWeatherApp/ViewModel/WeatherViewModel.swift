import Combine
import Foundation

final class WeatherViewModel {
    @Published var isLoading = false
    @Published var weather: Weather?
    @Published var error: NetworkError?
    
    private let locationManager = LocationManager.shared
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol = WeatherService()) {
        self.networkService = networkService
        startRequest()
    }
    
     func startRequest() {
        isLoading = true
        error = nil
        
        locationManager.onLocationUpdate = { [weak self] coordinate in
            guard let lat = coordinate?.coordinate.latitude,
                  let long = coordinate?.coordinate.longitude else {
                self?.makeRequest(latitude: nil, longitude: nil)
                return
            }
            
            self?.makeRequest(latitude: lat, longitude: long)
        }
        
        locationManager.requestLocation()
    }
    
    private func makeRequest(latitude: Double?, longitude: Double?) {
        
        networkService.request(latitude: latitude, longitude: longitude)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] weather in
                self?.weather = weather
            }
            .store(in: &cancellables)
    }
    
    func getDayOfWeek(from dateString: String) -> String? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = dateFormatter.date(from: dateString) else {
            print("Некорректная дата")
            return nil
        }
        
        let currentDate = Date.now
        let stringCurrentDate = dateFormatter.string(from: currentDate)
        
        let formatterCurrentDate = dateFormatter.date(from: stringCurrentDate)
        let stringToDate = dateFormatter.date(from: dateString)
        
        if formatterCurrentDate == stringToDate { return "Сегодня" }
        
        dateFormatter.dateFormat = "E"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        return dateFormatter.string(from: date).capitalized
    }
    
    func generate24HourSequence(_ weather: Weather) -> [[String:Int]]? {
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        
        guard let currentHour = Int(dateFormatter.string(from: now).components(separatedBy: " ").last ?? "") else { return nil }
        
        guard let arrayOfDictionariesCurrentSequenceHourTemp = generateDaySequenceHourTemp(with: weather, currentHour, 0),
              let arrayOfDictionariesNextDaySequenceHourTemp = generateDaySequenceHourTemp(with: weather, currentHour, 1) else { return nil }
        
        let transformedArrayCurrentSequenceHourTemp = transformArrayOfDictionaries(arrayOfDictionariesCurrentSequenceHourTemp)
        let transformedArrayNextDaySequenceHourTemp = transformArrayOfDictionaries(arrayOfDictionariesNextDaySequenceHourTemp)
        
        let result = transformedArrayCurrentSequenceHourTemp + transformedArrayNextDaySequenceHourTemp
        
        return result
    }
    
    func generateDaySequenceHourTemp(with weather: Weather, _ currentHour: Int, _ index: Int) -> [[Int:Int]]? {
        let hourDataDictionaryArray = weather.forecast.forecastday[index].hours
        
        var dictHourTemp = [String:Double]()
        
        for hour in hourDataDictionaryArray {
            dictHourTemp[hour.time] = hour.tempC
        }
        
        let intDictHourTemp = Dictionary(
            uniqueKeysWithValues: dictHourTemp.map {
                (Int(($0
                    .key
                    .components(separatedBy: " ")
                    .last ?? "")
                    .prefix(2)),
                 Int($0.value)) })

        if index == 0 {
            guard let currentTemp = intDictHourTemp[currentHour] else { return nil }
            
            var hour = currentHour
            
            var currentSequenceHourTemp = [hour : currentTemp]
            
            while hour + 1 < 24 {
                hour += 1
                currentSequenceHourTemp[hour] = intDictHourTemp[hour]
            }
            
            return currentSequenceHourTemp.map { [$0.key: $0.value] }.sortedByKey()
        }
        
        var nextDaySequenceHourTemp = [Int:Int]()

        for num in 0...currentHour {
            nextDaySequenceHourTemp[num] = intDictHourTemp[num]
        }
        
        return nextDaySequenceHourTemp.map { [$0.key: $0.value] }.sortedByKey()
    }
    
    func transformArrayOfDictionaries(_ array: [[Int: Int]]) -> [[String: Int]] {
        return array.map { dict in
            dict.reduce(into: [String: Int]()) { result, pair in
                let (key, value) = pair
                result[key < 10 ? "0\(key)" : "\(key)"] = value
            }
        }
    }
}
