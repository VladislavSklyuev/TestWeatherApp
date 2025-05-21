import UIKit
import SwiftUI

final class WeatherForecastCell: UITableViewCell {
        
    @Autolayout private var label: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        $0.textAlignment = .left
        $0.textColor = .black
        $0.text = "Test"
        return $0
    }(UILabel())
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setConstraints()
    }
    
    private func setConstraints() {
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configureCell(text: String) {
        label.text = text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    let view = WeatherForecastCell()
    return view
}
