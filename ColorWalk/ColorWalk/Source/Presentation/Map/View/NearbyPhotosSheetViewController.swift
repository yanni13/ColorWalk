import UIKit
import SnapKit
import CoreLocation
import Kingfisher

final class NearbyPhotosSheetViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let horizontalInset: CGFloat = 23
    }

    // MARK: - Properties

    private let photos: [Photo]
    private var currentPage: Int = 0
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

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.clipsToBounds = true
        cv.alwaysBounceVertical = false
        return cv
    }()

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.82),
            heightDimension: .fractionalHeight(1.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 12
        
        section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, offset, env) in
            guard let self = self else { return }
            let width = env.container.contentSize.width
            let groupWidth = width * 0.82 + 12
            let page = Int(round(offset.x / groupWidth))
            
            if page != self.currentPage, page >= 0, page < self.photos.count {
                self.currentPage = page
                DispatchQueue.main.async {
                    self.paginationDotsView.configure(count: self.photos.count, currentIndex: page)
                    self.updateColorCard(for: self.photos[page])
                    self.fetchWeather(for: self.photos[page])
                }
            }
        }

        return UICollectionViewCompositionalLayout(section: section)
    }

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

    deinit {
        weatherTask?.cancel()
        geocoder.cancelGeocode()
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .white
        
        view.addSubview(collectionView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        collectionView.dataSource = self
        collectionView.register(NearbyPhotoCell.self, forCellWithReuseIdentifier: NearbyPhotoCell.reuseId)
        collectionView.reloadData()
        
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

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(view.snp.width).multipliedBy(0.82)
        }

        paginationDotsView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
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
            guard let data = try? await WeatherCacheManager.shared.fetch(for: location) else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                weatherInfoCard.iconImageView.image = UIImage(systemName: data.symbolName)
                weatherInfoCard.subtitleLabel.text = "\(data.celsius) · 습도 \(data.humidity)"
                weatherInfoCard.rightLabel.text = "현재"
                UIView.animate(withDuration: 0.3) {
                    self.weatherInfoCard.alpha = 1
                }
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

// MARK: - UICollectionViewDataSource

extension NearbyPhotosSheetViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NearbyPhotoCell.reuseId,
            for: indexPath
        ) as? NearbyPhotoCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: photos[indexPath.item])
        return cell
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
