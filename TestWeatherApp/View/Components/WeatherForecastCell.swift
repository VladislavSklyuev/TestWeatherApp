import UIKit
import SwiftUI

final class WeatherForecastCell: UITableViewCell {
    
    @Autolayout private var labelDay: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        $0.textAlignment = .left
        $0.textColor = .white
        return $0
    }(UILabel())
    
    @Autolayout private var minTempLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        $0.textAlignment = .center
        $0.textColor = .black
        return $0
    }(UILabel())
    
    @Autolayout private var maxTempLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        $0.textAlignment = .center
        $0.textColor = .black
        return $0
    }(UILabel())
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setConstraints()
    }
    
    private func setConstraints() {
        let hStack = UIStackView(views: [minTempLabel, maxTempLabel], axis: .horizontal, spacing: 12)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(hStack)
        contentView.addSubview(labelDay)
        
        NSLayoutConstraint.activate([
            labelDay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            labelDay.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            hStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            hStack.widthAnchor.constraint(equalToConstant: 260)
        ])
    }
    
    func configureCell(text: String, minTemp: Double, maxTemp: Double) {
        labelDay.text = text
        minTempLabel.text = "мин.: \(String(Int(minTemp)))"
        maxTempLabel.text = "макс.: \(String(Int(maxTemp)))"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
