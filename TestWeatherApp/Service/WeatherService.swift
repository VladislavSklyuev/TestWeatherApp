import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Decodable>() -> AnyPublisher<T, NetworkError>
}

struct WeatherService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    func request<T: Decodable>() -> AnyPublisher<T, NetworkError> {
        guard let urlString = URL(string: "https://api.weatherapi.com/v1/forecast.json?key=fa8b3df74d4042b9aa7135114252304&q=LAT,LON&days=7") else {
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
            .decode(type: T.self, decoder: decoder)
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
