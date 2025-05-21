import Combine
import Foundation

enum WeatherError: Error {
    case noInternet
    case serverError(String)
}

final class WeatherViewModel {
    @Published var weather: Weather?
    @Published var isLoading = false
    @Published var error: NetworkError?
    
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol = WeatherService()) {
        self.networkService = networkService
    }
    
    func fetchWeather() {
        
        isLoading = true
        error = nil
        
        networkService.request()
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
}
