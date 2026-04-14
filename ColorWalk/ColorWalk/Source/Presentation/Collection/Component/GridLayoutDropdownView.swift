import UIKit
import SnapKit

final class GridLayoutDropdownView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let dropdownWidth: CGFloat = 200
        static let optionHeight: CGFloat = 48
        static let iconSize: CGFloat = 18
        static let horizontalPadding: CGFloat = 16
        static let iconTextGap: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let selectedCornerRadius: CGFloat = 10
        static let selectedBg = UIColor(hex: "#F0F2F5")
        static let unselectedIconColor = UIColor(hex: "#8B95A1")
        static let selectedIconColor = UIColor(hex: "#191F28")
        static let unselectedTextColor = UIColor(hex: "#333D4B")
        static let selectedTextColor = UIColor(hex: "#191F28")
    }

    static var totalHeight: CGFloat {
        Constants.verticalPadding * 2 + CGFloat(GridLayoutType.allCases.count) * Constants.optionHeight
    }

    // MARK: - Properties

    var onSelect: ((GridLayoutType) -> Void)?

    private var selectedLayout: GridLayoutType = .threeByThree
    private var rowViews: [(layout: GridLayoutType, container: UIView, icon: UIImageView, label: UILabel, checkmark: UIImageView)] = []

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 14
        layer.shadowOpacity = 1.0

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Constants.verticalPadding)
            make.leading.trailing.equalToSuperview()
        }

        GridLayoutType.allCases.enumerated().forEach { index, layout in
            let rowData = makeOptionRow(for: layout, tag: index)
            rowViews.append(rowData)
            stack.addArrangedSubview(rowData.container)
        }
    }

    private func makeOptionRow(
        for layout: GridLayoutType,
        tag: Int
    ) -> (layout: GridLayoutType, container: UIView, icon: UIImageView, label: UILabel, checkmark: UIImageView) {
        let container = UIView()
        container.tag = tag
        container.layer.cornerRadius = Constants.selectedCornerRadius
        container.clipsToBounds = true
        container.accessibilityLabel = layout.displayTitle
        container.isUserInteractionEnabled = true
        container.snp.makeConstraints { make in
            make.height.equalTo(Constants.optionHeight)
        }

        let iconConfig = UIImage.SymbolConfiguration(pointSize: Constants.iconSize - 2, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: layout.iconSystemName, withConfiguration: iconConfig))
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Constants.unselectedIconColor

        let titleLabel = UILabel()
        titleLabel.text = layout.displayTitle
        titleLabel.font = UIFont(name: "Pretendard-Medium", size: 15)
        titleLabel.textColor = Constants.unselectedTextColor

        let checkIconConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: checkIconConfig))
        checkmarkView.tintColor = Constants.selectedIconColor
        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.isHidden = true

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(checkmarkView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.iconSize)
        }

        checkmarkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Constants.horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.iconTextGap)
            make.trailing.equalTo(checkmarkView.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:)))
        container.addGestureRecognizer(tap)

        return (layout: layout, container: container, icon: iconView, label: titleLabel, checkmark: checkmarkView)
    }

    // MARK: - Action

    @objc private func optionTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag,
              tag < GridLayoutType.allCases.count else { return }
        let layout = GridLayoutType.allCases[tag]
        setSelectedLayout(layout)
        onSelect?(layout)
    }

    // MARK: - Public

    func setSelectedLayout(_ layout: GridLayoutType) {
        selectedLayout = layout
        rowViews.forEach { row in
            let isSelected = row.layout == layout
            row.container.backgroundColor = isSelected ? Constants.selectedBg : .clear
            row.icon.tintColor = isSelected ? Constants.selectedIconColor : Constants.unselectedIconColor
            row.label.textColor = isSelected ? Constants.selectedTextColor : Constants.unselectedTextColor
            row.label.font = UIFont(
                name: isSelected ? "Pretendard-SemiBold" : "Pretendard-Medium",
                size: 15
            )
            row.checkmark.isHidden = !isSelected
        }
    }

    func show(anchoredTo button: UIView, in parentView: UIView) {
        let buttonFrame = button.convert(button.bounds, to: parentView)
        let height = GridLayoutDropdownView.totalHeight
        let safeTopInset = parentView.safeAreaInsets.top
        let rawY = buttonFrame.minY - height - 8
        let clampedY = max(safeTopInset + 8, rawY)

        frame = CGRect(
            x: buttonFrame.maxX - Constants.dropdownWidth,
            y: clampedY,
            width: Constants.dropdownWidth,
            height: height
        )

        alpha = 0
        transform = CGAffineTransform(scaleX: 0.95, y: 0.95).translatedBy(x: 0, y: 8)
        parentView.addSubview(self)

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95).translatedBy(x: 0, y: 8)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
