import UIKit
import SnapKit
import CoreLocation
import Kingfisher
import WeatherKit

final class NearbyPhotosSheetViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let horizontalInset: CGFloat = 23
        static let photoCardStroke: CGFloat = 3
        static let photoContainerCornerRadius: CGFloat = 23
        static let photoImageCornerRadius: CGFloat = 20
    }

    // MARK: - Properties

    private let photos: [Photo]
    private var currentPage: Int = 0
    private var lastLayoutWidth: CGFloat = 0
    private let geocoder = CLGeocoder()
    private var weatherTask: Task<Void, Never>?

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "이 근처 사진"
        l.textColor = .black
        l.font = UIFont(name: "Inter-Bold", size: 22) ?? .boldSystemFont(ofSize: 22)
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "#A0A0A0")
        l.font = UIFont(name: "Inter-Regular", size: 11) ?? .systemFont(ofSize: 11)
        return l
    }()

    private let photoScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.clipsToBounds = false
        return sv
    }()

    private let paginationDotsView = PaginationDotsView()
    private let colorInfoCard = InfoCardView()
    private let weatherInfoCard = InfoCardView()

    // MARK: - Init

    init(photos: [Photo]) {
        self.photos = photos
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureContent()
        reverseGeocodeLocation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = photoScrollView.bounds.width
        guard width > 0, width != lastLayoutWidth else { return }
        lastLayoutWidth = width
        layoutPhotoCards()
    }

    deinit {
        weatherTask?.cancel()
        geocoder.cancelGeocode()
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(photoScrollView)
        photoScrollView.delegate = self
        view.addSubview(paginationDotsView)
        view.addSubview(colorInfoCard)
        view.addSubview(weatherInfoCard)

        colorInfoCard.titleLabel.text = "색상 정보"

        weatherInfoCard.titleLabel.text = "날씨"
        weatherInfoCard.iconView.backgroundColor = UIColor(hex: "#F5F5F5")
        weatherInfoCard.iconImageView.isHidden = false
        weatherInfoCard.iconImageView.tintColor = UIColor(hex: "#3A3A3A")
        weatherInfoCard.alpha = 0
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().inset(26)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().inset(26)
        }

        photoScrollView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(Constants.horizontalInset)
            make.trailing.equalToSuperview().inset(Constants.horizontalInset)
            make.height.equalTo(photoScrollView.snp.width)
        }

        paginationDotsView.snp.makeConstraints { make in
            make.top.equalTo(photoScrollView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(12)
        }

        colorInfoCard.snp.makeConstraints { make in
            make.top.equalTo(paginationDotsView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        weatherInfoCard.snp.makeConstraints { make in
            make.top.equalTo(colorInfoCard.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
    }

    // MARK: - Helper

    private func configureContent() {
        guard let first = photos.first else { return }
        subtitleLabel.text = "사진 \(photos.count)장"
        updateColorCard(for: first)
        paginationDotsView.configure(count: photos.count, currentIndex: 0)
        fetchWeather(for: first)
    }

    private func updateColorCard(for photo: Photo) {
        colorInfoCard.iconView.backgroundColor = UIColor(hex: photo.capturedHex)
        colorInfoCard.iconImageView.isHidden = true
        let matchText = photo.matchRate > 0 ? " • 매칭율 \(Int(photo.matchRate))%" : ""
        colorInfoCard.subtitleLabel.text = "\(photo.capturedHex)\(matchText)"
        colorInfoCard.rightLabel.text = relativeTime(from: photo.createdAt)
    }

    private func layoutPhotoCards() {
        photoScrollView.subviews.forEach { $0.removeFromSuperview() }

        let cardWidth = photoScrollView.bounds.width
        let cardHeight = photoScrollView.bounds.height

        for (index, photo) in photos.enumerated() {
            let card = makePhotoCard(for: photo, cardWidth: cardWidth, cardHeight: cardHeight)
            photoScrollView.addSubview(card)
            card.frame = CGRect(
                x: CGFloat(index) * cardWidth,
                y: 0,
                width: cardWidth,
                height: cardHeight
            )
        }

        photoScrollView.contentSize = CGSize(
            width: cardWidth * CGFloat(photos.count),
            height: cardHeight
        )
    }

    private func makePhotoCard(for photo: Photo, cardWidth: CGFloat, cardHeight: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = Constants.photoContainerCornerRadius
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.12
        container.layer.shadowRadius = 12
        container.layer.shadowOffset = CGSize(width: 0, height: 4)

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(hex: photo.capturedHex)
        imageView.layer.cornerRadius = Constants.photoImageCornerRadius
        imageView.clipsToBounds = true
        imageView.frame = CGRect(
            x: Constants.photoCardStroke,
            y: Constants.photoCardStroke,
            width: cardWidth - Constants.photoCardStroke * 2,
            height: cardHeight - Constants.photoCardStroke * 2
        )
        container.addSubview(imageView)

        guard !photo.imagePath.isEmpty else { return container }

        if photo.imagePath.hasPrefix("http"), let url = URL(string: photo.imagePath) {
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            imageView.image = ImageFileManager.shared.loadImage(fileName: photo.imagePath)
            imageView.backgroundColor = nil
        }

        return container
    }

    private func reverseGeocodeLocation() {
        guard let first = photos.first,
              first.latitude != 0 || first.longitude != 0 else { return }

        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                self.titleLabel.text = placemark.name
                    ?? placemark.subLocality
                    ?? placemark.locality
                    ?? "이 근처 사진"

                let addressParts = [
                    placemark.administrativeArea,
                    placemark.locality,
                    placemark.subLocality,
                    placemark.thoroughfare,
                    placemark.subThoroughfare
                ].compactMap { $0 }

                self.subtitleLabel.text = addressParts.isEmpty
                    ? "주소 정보 없음"
                    : addressParts.joined(separator: " ")
            }
        }
    }

    private func fetchWeather(for photo: Photo) {
        guard photo.latitude != 0 || photo.longitude != 0 else { return }

        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            guard let self else { return }
            let location = CLLocation(latitude: photo.latitude, longitude: photo.longitude)
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                let current = weather.currentWeather
                let celsius = String(format: "%.0f°C", current.temperature.converted(to: .celsius).value)
                let humidity = "\(Int(current.humidity * 100))%"
                let symbolName = current.symbolName

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.weatherInfoCard.iconImageView.image = UIImage(systemName: symbolName)
                    self.weatherInfoCard.subtitleLabel.text = "\(celsius) · 습도 \(humidity)"
                    self.weatherInfoCard.rightLabel.text = "현재"
                    UIView.animate(withDuration: 0.3) {
                        self.weatherInfoCard.alpha = 1
                    }
                }
            } catch {
                // 날씨 정보 미제공 시 카드 유지 숨김
            }
        }
    }

    private func relativeTime(from date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        switch diff {
        case ..<60:         return "방금 전"
        case 60..<3600:     return "\(diff / 60)분 전"
        case 3600..<86400:  return "\(diff / 3600)시간 전"
        default:            return "\(diff / 86400)일 전"
        }
    }
}

// MARK: - UIScrollViewDelegate

extension NearbyPhotosSheetViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        let page = max(0, min(Int(round(scrollView.contentOffset.x / width)), photos.count - 1))
        guard page != currentPage else { return }
        currentPage = page
        paginationDotsView.configure(count: photos.count, currentIndex: page)
        updateColorCard(for: photos[page])
        fetchWeather(for: photos[page])
    }
}

// MARK: - InfoCardView

private final class InfoCardView: UIView {

    private enum Constants {
        static let cornerRadius: CGFloat = 24
        static let iconSize: CGFloat = 44
        static let iconImageSize: CGFloat = 22
    }

    let iconView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = Constants.iconSize / 2
        v.clipsToBounds = true
        return v
    }()

    let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.textPrimary
        l.font = UIFont(name: "Pretendard-SemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        return l
    }()

    let subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.textSecondary
        l.font = UIFont(name: "Pretendard-Regular", size: 12) ?? .systemFont(ofSize: 12)
        l.numberOfLines = 2
        return l
    }()

    let rightLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.textSecondary
        l.font = UIFont(name: "Pretendard-Regular", size: 12) ?? .systemFont(ofSize: 12)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = Constants.cornerRadius
        layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        layer.borderWidth = 1

        addSubview(iconView)
        iconView.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(rightLabel)
    }

    private func setupConstraints() {
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.iconSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Constants.iconImageSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(rightLabel.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().inset(14)
            make.trailing.lessThanOrEqualTo(rightLabel.snp.leading).offset(-8)
        }

        rightLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }
}

// MARK: - PaginationDotsView

private final class PaginationDotsView: UIView {

    private enum Constants {
        static let activeDotSize: CGFloat = 8
        static let inactiveDotSize: CGFloat = 6
        static let gap: CGFloat = 8
    }

    private var dotViews: [UIView] = []

    func configure(count: Int, currentIndex: Int) {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        guard count > 1 else { return }

        var previousDot: UIView?

        for i in 0..<count {
            let isActive = i == currentIndex
            let size: CGFloat = isActive ? Constants.activeDotSize : Constants.inactiveDotSize
            let dot = UIView()
            dot.backgroundColor = isActive ? UIColor.App.textPrimary : UIColor.App.textTertiary
            dot.layer.cornerRadius = size / 2
            addSubview(dot)

            dot.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.height.equalTo(size)
                if let prev = previousDot {
                    make.leading.equalTo(prev.snp.trailing).offset(Constants.gap)
                } else {
                    make.leading.equalToSuperview()
                }
                if i == count - 1 {
                    make.trailing.equalToSuperview()
                }
            }

            dotViews.append(dot)
            previousDot = dot
        }
    }
}
