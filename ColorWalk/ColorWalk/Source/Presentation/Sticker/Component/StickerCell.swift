import UIKit
import SnapKit

final class StickerCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "StickerCell"

    private enum Constants {
        static let imageHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 16
        static let infoVerticalPadding: CGFloat = 10
        static let infoHorizontalPadding: CGFloat = 12
        static let nameFontSize: CGFloat = 13
        static let dateFontSize: CGFloat = 11
        static let checkerSize: CGFloat = 10
    }

    // MARK: - UI

    private let checkerBgView = CheckerboardView()

    private let stickerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: Constants.nameFontSize)
            ?? .systemFont(ofSize: Constants.nameFontSize, weight: .semibold)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: Constants.dateFontSize)
            ?? .systemFont(ofSize: Constants.dateFontSize)
        l.textColor = UIColor(hex: "#B0B8C1")
        return l
    }()

    private lazy var infoStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        s.axis = .vertical
        s.spacing = 2
        return s
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupAppearance() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = Constants.cornerRadius
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(hex: "#E5E8EB").cgColor
        contentView.clipsToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false
        layer.cornerRadius = Constants.cornerRadius
    }

    private func setupViews() {
        contentView.addSubview(checkerBgView)
        checkerBgView.addSubview(stickerImageView)
        contentView.addSubview(infoStack)
    }

    private func setupConstraints() {
        checkerBgView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.imageHeight)
        }
        stickerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(checkerBgView.snp.bottom).offset(Constants.infoVerticalPadding)
            make.leading.trailing.equalToSuperview().inset(Constants.infoHorizontalPadding)
            make.bottom.equalToSuperview().inset(Constants.infoVerticalPadding)
        }
    }

    // MARK: - Configure

    func configure(with sticker: Sticker) {
        nameLabel.text = sticker.colorName
        dateLabel.text = formatDate(sticker.createdAt)
        let url = StickerManager.shared.stickerURL(for: sticker.imagePath)
        if let data = try? Data(contentsOf: url) {
            stickerImageView.image = UIImage(data: data)
        } else {
            stickerImageView.image = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stickerImageView.image = nil
        nameLabel.text = nil
        dateLabel.text = nil
    }

    // MARK: - Helper

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - CheckerboardView

private final class CheckerboardView: UIView {

    private enum Constants {
        static let tileSize: CGFloat = 10
        static let lightColor = UIColor(hex: "#F7F8FA")
        static let darkColor = UIColor(hex: "#EBEBEB")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let tileSize = Constants.tileSize
        let cols = Int(ceil(rect.width / tileSize))
        let rows = Int(ceil(rect.height / tileSize))
        for row in 0..<rows {
            for col in 0..<cols {
                let isLight = (row + col) % 2 == 0
                (isLight ? Constants.lightColor : Constants.darkColor).setFill()
                context.fill(CGRect(x: CGFloat(col) * tileSize, y: CGFloat(row) * tileSize,
                                    width: tileSize, height: tileSize))
            }
        }
    }
}
