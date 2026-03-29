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
        setupGridCells()

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

    private func setupGridCells() {
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = Constants.cellGap
        outerStack.distribution = .fillEqually

        for _ in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Constants.cellGap
            rowStack.distribution = .fillEqually

            for _ in 0..<3 {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.backgroundColor = UIColor.App.bgSecondary
                gridImageViews.append(imageView)
                rowStack.addArrangedSubview(imageView)
            }
            outerStack.addArrangedSubview(rowStack)
        }

        gridContainer.addSubview(outerStack)
        outerStack.snp.makeConstraints { make in
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

    func configure(slots: [SlotDisplayInfo], missionHex: String, dateText: String) {
        let missionColor = UIColor(hex: missionHex)

        colorDot.backgroundColor = missionColor
        hexLabel.text = missionHex

        dateLabel.attributedText = NSAttributedString(
            string: dateText,
            attributes: [.kern: Constants.letterSpacing]
        )

        badgeView.backgroundColor = missionColor.withAlphaComponent(Constants.badgeBgAlpha)
        badgeLabel.textColor = missionColor

        loadGridImages(from: slots)
    }

    // MARK: - Private

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
