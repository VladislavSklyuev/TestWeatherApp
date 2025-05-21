import UIKit
import Combine

class WeatherViewController: UIViewController {
    private let viewModel = WeatherViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Основные элементы
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    
    private lazy var cityNameLabel = createLabel(fontSize: 44, alignment: .center)
    private lazy var currentTempLabel = createLabel(fontSize: 64, alignment: .center)
    private lazy var shortDescWeather = createLabel(fontSize: 20, color: .lightGray, alignment: .center)
    private lazy var maxAndMinimumTempValues = createLabel(fontSize: 24, alignment: .center)
    
    private lazy var tableView: UITableView = {
        $0.delegate = self
        $0.dataSource = self
        $0.backgroundColor = .lightGray
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.register(WeatherForecastCell.self, forCellReuseIdentifier: WeatherForecastCell.reuseIdentifier)
        $0.layer.cornerRadius = 12
        return $0
    }(UITableView())
    
    // Горизонтальный скролл
    private lazy var horizontalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .lightGray
        scrollView.layer.cornerRadius = 12
        return scrollView
    }()
    
    // Контейнер для горизонтального скролла
    private lazy var horizontalContentContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        //view.backgroundColor = .blue
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel.$weather
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in
                guard let self = self, 
                      let weather = weather else { return }
                updateUI(with: weather)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                isLoading ? self?.loadingIndicator.startAnimating() : self?.loadingIndicator.stopAnimating()
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorLabel.text = error.localizedDescription
                    self.errorLabel.isHidden = false
                    self.retryButton.isHidden = false
                    self.statusLabel.isHidden = true
                } else {
                    self.errorLabel.isHidden = true
                    self.retryButton.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UpdateUI
    
    private func updateUI(with weather: Weather) {
        view.backgroundColor = .lightGray.withAlphaComponent(0.5)
        statusLabel.isHidden = true
        setupScrollViews()
        
        updateMainLabels(with: weather)
        createWeatherColumns(with: weather)
        tableView.reloadData()
    }
    
    private func setupUI() {
        // Настройка loadingIndicator
        loadingIndicator.center = view.center
        loadingIndicator.color = .black
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        statusLabel.textColor = .black
        statusLabel.text = "Загружаем прогноз погоды.."
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Настройка errorLabel
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // Настройка retryButton
        retryButton.setTitle("Повторить", for: .normal)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.isHidden = true
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    private func updateMainLabels(with weather: Weather) {
        cityNameLabel.text = weather.location.name
        currentTempLabel.text = String(Int(weather.current.tempC))
        shortDescWeather.text = weather.current.condition.text
        maxAndMinimumTempValues.text = String("Макс.: \(Int(weather.forecast.forecastday.first?.day.maxTempC ?? 0)), мин.: \(Int(weather.forecast.forecastday.first?.day.minTempC ?? 0))")
    }
    
    // MARK: - Настройка скролла
    
    private func setupScrollViews() {
        let vStack = UIStackView(arrangedSubviews: [cityNameLabel,
                                                  currentTempLabel,
                                                  shortDescWeather,
                                                  maxAndMinimumTempValues])
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(vStack)
        view.addSubview(horizontalScrollView)
        horizontalScrollView.addSubview(horizontalContentContainer)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            
            // Вертикальный стек
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        
            // Горизонтальный скролл
            horizontalScrollView.topAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 12),
            horizontalScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            horizontalScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            horizontalScrollView.heightAnchor.constraint(equalToConstant: 120),
            
            // Контейнер горизонтального скролла
            horizontalContentContainer.topAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 12),
            horizontalContentContainer.leadingAnchor.constraint(equalTo: horizontalScrollView.leadingAnchor),
            horizontalContentContainer.trailingAnchor.constraint(equalTo: horizontalScrollView.trailingAnchor),
            horizontalContentContainer.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            horizontalContentContainer.heightAnchor.constraint(equalTo: horizontalScrollView.heightAnchor),
            
            tableView.topAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: horizontalScrollView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        horizontalContentContainer.widthAnchor.constraint(greaterThanOrEqualTo: horizontalScrollView.widthAnchor).isActive = true
    }
    
    // MARK: - Создание столбцов
    private func createWeatherColumns(with weather: Weather) {
        var columns = [UIView]()
        
        guard let hourSequence = viewModel.generate24HourSequence(weather) else { return }

        for (index, hour) in hourSequence.enumerated() {

            let column = createColumn(temp: hour.values.first!, hour: index == 0 ? "Сейчас" : hour.keys.first!)
            
            horizontalContentContainer.addSubview(column)
            
            columns.append(column)
            
            NSLayoutConstraint.activate([
                column.topAnchor.constraint(equalTo: horizontalContentContainer.topAnchor, constant: 12),
                column.bottomAnchor.constraint(equalTo: horizontalContentContainer.bottomAnchor, constant: -12),
                column.widthAnchor.constraint(equalToConstant: 60),
            ])
        }
        
        // Располагаем колонки горизонтально с отступами
        for (index, column) in columns.enumerated() {
            if index == 0 {
                // Первая колонка
                column.leadingAnchor.constraint(
                    equalTo: horizontalContentContainer.leadingAnchor,
                    constant: 16
                ).isActive = true
            } else {
                // Все последующие колонки
                column.leadingAnchor.constraint(
                    equalTo: columns[index-1].trailingAnchor,
                    constant: 0
                ).isActive = true
            }
        }
        
        // Последняя колонка
        if let lastColumn = columns.last {
            lastColumn.trailingAnchor.constraint(
                equalTo: horizontalContentContainer.trailingAnchor,
                constant: -16
            ).isActive = true
        }
    }
    
    // TODO: - Создание Ячеек
    private func createColumn(temp: Int, hour: String) -> UIView {
        let column = UIView()
        column.translatesAutoresizingMaskIntoConstraints = false
        
        let hourLabel = createLabel(text: hour, fontSize: 20, weight: .regular)
        let unitLabel = createLabel(text: "\(temp)", fontSize: 22, weight: .regular)
        
        column.addSubview(hourLabel)
        column.addSubview(unitLabel)
        
        NSLayoutConstraint.activate([
            hourLabel.topAnchor.constraint(equalTo: column.topAnchor, constant: 8),
            hourLabel.centerXAnchor.constraint(equalTo: column.centerXAnchor),
            
            unitLabel.topAnchor.constraint(equalTo: hourLabel.bottomAnchor, constant: 28),
            unitLabel.centerXAnchor.constraint(equalTo: hourLabel.centerXAnchor)
        ])
        
        return column
    }
    
    private func createLabel(text: String = "",
                             fontSize: CGFloat,
                             weight: UIFont.Weight = .regular,
                             color: UIColor = .white,
                             alignment: NSTextAlignment = .left) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        label.textAlignment = alignment
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    @objc private func retryTapped() {
        viewModel.startRequest()
    }
}

extension WeatherViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel.weather != nil else {
            return 0
        }
        return viewModel.weather!.forecast.forecastday.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WeatherForecastCell.reuseIdentifier, for: indexPath) as? WeatherForecastCell else {
            return UITableViewCell()
        }
        guard viewModel.weather != nil else {
            return UITableViewCell()
        }
        
        cell.configureCell(text: viewModel.getDayOfWeek(from: viewModel.weather!.forecast.forecastday[indexPath.row].date) ?? "", minTemp: viewModel.weather!.forecast.forecastday[indexPath.row].day.minTempC, maxTemp: viewModel.weather!.forecast.forecastday[indexPath.row].day.maxTempC)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate
extension WeatherViewController: UITableViewDelegate {
    // Высота ячейки
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
