import UIKit
import SnapKit

final class InstagramShareCardView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cellGap: CGFloat = 2
        static let cardCornerRadius: CGFloat = 20
        static let dotSize: CGFloat = 8
        static let colorRowSpacing: CGFloat = 6
        static let titleRowSpacing: CGFloat = 10
        static let headerStackSpacing: CGFloat = 8
        static let infoStackSpacing: CGFloat = 16
        static let badgeCornerRadius: CGFloat = 11
        static let badgePaddingV: CGFloat = 4
        static let badgePaddingH: CGFloat = 8
        static let infoPaddingH: CGFloat = 16
        static let infoPaddingBottom: CGFloat = 24
        static let thumbnailSize: CGFloat = 400
        static let hexLabelAlpha: CGFloat = 0.67
        static let dateLabelAlpha: CGFloat = 0.27
        static let badgeBgAlpha: CGFloat = 0.19
        static let letterSpacing: CGFloat = 1.0
    }

    // MARK: - UI: Grid

    private let gridContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private var gridImageViews: [UIImageView] = []
    private var currentLayout: GridLayoutType = .threeByThree

    // MARK: - UI: Info

    private let colorDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.dotSize / 2
        return view
    }()

    private let hexLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Medium", size: 12) ?? .systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(Constants.hexLabelAlpha)
        return label
    }()

    private let colorRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.colorRowSpacing
        stack.alignment = .center
        return stack
    }()

    private let missionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Mission Complete!"
        label.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.text = "9/9"
        label.font = UIFont(name: "Pretendard-SemiBold", size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.badgeCornerRadius
        return view
    }()

    private let titleRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.titleRowSpacing
        stack.alignment = .center
        return stack
    }()

    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.headerStackSpacing
        return stack
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Medium", size: 10) ?? .systemFont(ofSize: 10)
        label.textColor = UIColor.white.withAlphaComponent(Constants.dateLabelAlpha)
        return label
    }()

    private let infoContentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.infoStackSpacing
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = UIColor(hex: "#0A0A0A")
        layer.cornerRadius = Constants.cardCornerRadius
        clipsToBounds = true

        addSubview(gridContainer)

        colorRowStack.addArrangedSubview(colorDot)
        colorRowStack.addArrangedSubview(hexLabel)

        badgeView.addSubview(badgeLabel)
        titleRowStack.addArrangedSubview(missionTitleLabel)
        titleRowStack.addArrangedSubview(badgeView)

        headerStack.addArrangedSubview(colorRowStack)
        headerStack.addArrangedSubview(titleRowStack)

        infoContentStack.addArrangedSubview(headerStack)
        infoContentStack.addArrangedSubview(dateLabel)

        addSubview(infoContentStack)
    }

    private func setupGridCells(for layout: GridLayoutType) {
        switch layout {
        case .twoByTwo:
            buildEqualGrid(rows: 2, cols: 2)
        case .threeByThree:
            buildEqualGrid(rows: 3, cols: 3)
        case .twoByThree:
            buildTwoThreeGrid()
        case .filmStrip:
            buildFilmStripGrid()
        }
    }

    private func buildEqualGrid(rows: Int, cols: Int) {
        let outerStack = makeGridStack(axis: .vertical)
        for _ in 0..<rows {
            let rowStack = makeGridStack(axis: .horizontal)
            for _ in 0..<cols {
                let cell = makeGridCell()
                gridImageViews.append(cell)
                rowStack.addArrangedSubview(cell)
            }
            outerStack.addArrangedSubview(rowStack)
        }
        pinGridStack(outerStack)
    }

    private func buildTwoThreeGrid() {
        let outerStack = makeGridStack(axis: .horizontal)

        let leftStack = makeGridStack(axis: .vertical)
        for _ in 0..<2 {
            let cell = makeGridCell()
            gridImageViews.append(cell)
            leftStack.addArrangedSubview(cell)
        }

        let rightStack = makeGridStack(axis: .vertical)
        for _ in 0..<3 {
            let cell = makeGridCell()
            gridImageViews.append(cell)
            rightStack.addArrangedSubview(cell)
        }

        outerStack.addArrangedSubview(leftStack)
        outerStack.addArrangedSubview(rightStack)
        pinGridStack(outerStack)
    }

    private func buildFilmStripGrid() {
        let stack = makeGridStack(axis: .vertical)
        for _ in 0..<3 {
            let cell = makeGridCell()
            gridImageViews.append(cell)
            stack.addArrangedSubview(cell)
        }
        pinGridStack(stack)
    }

    private func makeGridStack(axis: NSLayoutConstraint.Axis) -> UIStackView {
        let stack = UIStackView()
        stack.axis = axis
        stack.spacing = Constants.cellGap
        stack.distribution = .fillEqually
        return stack
    }

    private func makeGridCell() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.App.bgSecondary
        return imageView
    }

    private func pinGridStack(_ stack: UIView) {
        gridContainer.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Constraints

    private func setupConstraints() {
        gridContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(gridContainer.snp.width)
        }

        infoContentStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.infoPaddingH)
            make.trailing.equalToSuperview().offset(-Constants.infoPaddingH)
            make.bottom.equalToSuperview().offset(-Constants.infoPaddingBottom)
        }

        colorDot.snp.makeConstraints { make in
            make.width.height.equalTo(Constants.dotSize)
        }

        badgeView.setContentHuggingPriority(.required, for: .horizontal)
        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        badgeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Constants.badgePaddingV)
            make.leading.trailing.equalToSuperview().inset(Constants.badgePaddingH)
        }
    }

    // MARK: - Configure

    func configure(slots: [SlotDisplayInfo], missionHex: String, dateText: String, layout: GridLayoutType) {
        let missionColor = UIColor(hex: missionHex)

        colorDot.backgroundColor = missionColor
        hexLabel.text = missionHex

        dateLabel.attributedText = NSAttributedString(
            string: dateText,
            attributes: [.kern: Constants.letterSpacing]
        )

        badgeView.backgroundColor = missionColor.withAlphaComponent(Constants.badgeBgAlpha)
        badgeLabel.textColor = missionColor

        let capturedCount = slots.filter { $0.isCaptured }.count
        badgeLabel.text = "\(capturedCount)/\(layout.slotCount)"

        rebuildGrid(for: layout)
        loadGridImages(from: slots)
    }

    // MARK: - Private

    private func rebuildGrid(for layout: GridLayoutType) {
        gridContainer.subviews.forEach { $0.removeFromSuperview() }
        gridImageViews.removeAll()
        currentLayout = layout
        setupGridCells(for: layout)
    }

    private func loadGridImages(from slots: [SlotDisplayInfo]) {
        let size = CGSize(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
        slots.enumerated().forEach { index, slot in
            guard index < gridImageViews.count else { return }
            let imageView = gridImageViews[index]
            guard slot.isCaptured, let fileName = slot.imagePath else {
                imageView.image = nil
                imageView.backgroundColor = UIColor.App.bgSecondary
                return
            }
            imageView.image = ImageFileManager.shared.loadThumbnail(fileName: fileName, size: size)
            if let hex = slot.capturedHex {
                imageView.backgroundColor = UIColor(hex: hex)
            }
        }
    }
}
