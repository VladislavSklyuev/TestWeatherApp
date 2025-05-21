import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request(latitude: Double?, longitude: Double?) -> AnyPublisher<Weather, NetworkError>
}

struct WeatherService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    func getWeatherURL(latitude: Double?, longitude: Double?) -> URL? {
        let apiKey = "fa8b3df74d4042b9aa7135114252304"
        let baseURL = "https://api.weatherapi.com/v1/forecast.json"

        let urlString = "\(baseURL)?key=\(apiKey)&q=\(latitude ?? 55.7558),\(longitude ?? 37.6173)&days=7"

        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            print("Ошибка создания URL")
            return nil
        }
        
        return url
    }
    
    func request(latitude: Double?, longitude: Double?) -> AnyPublisher<Weather, NetworkError> {
        guard let urlString = getWeatherURL(latitude: latitude, longitude: longitude) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: urlString)
        urlRequest.timeoutInterval = 15
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: Weather.self, decoder: decoder)
            .mapError { error -> NetworkError in
                switch error {
                case is URLError:
                    return .noInternetConnection
                case is DecodingError:
                    return .decodingFailed
                default:
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case noInternetConnection
    case serverError(statusCode: Int)
    case decodingFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL"
        case .invalidRequest:
            return "Некорректный запрос"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .noInternetConnection:
            return "Отсутствует интернет-соединение"
        case .serverError(let code):
            return "Ошибка сервера (код \(code))"
        case .decodingFailed:
            return "Ошибка парсинга данных"
        case .unknown(let error):
            return "Неизвестная ошибка: \(error.localizedDescription)"
        }
    }
}
