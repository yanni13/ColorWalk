import UIKit
import SnapKit

final class NearbyPhotosSheetViewController: UIViewController {

    // MARK: - Properties

    private let photos: [Photo]

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "이 근처 사진"
        l.textColor = UIColor.App.textPrimary
        l.font = UIFont(name: "Pretendard-SemiBold", size: 17) ?? .boldSystemFont(ofSize: 17)
        return l
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.textSecondary
        l.font = UIFont(name: "Pretendard-Regular", size: 14) ?? .systemFont(ofSize: 14)
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(NearbyPhotoCell.self, forCellWithReuseIdentifier: NearbyPhotoCell.reuseId)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

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
        countLabel.text = "총 \(photos.count)장"
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(countLabel)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(20)
        }

        countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension NearbyPhotosSheetViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
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

// MARK: - UICollectionViewDelegateFlowLayout

extension NearbyPhotosSheetViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let spacing: CGFloat = 4
        let width = (collectionView.bounds.width - spacing) / 2
        return CGSize(width: width, height: width)
    }
}
