import UIKit
import MapKit
import CoreLocation
import RxSwift
import RxCocoa
import SnapKit

final class MapViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: MapViewModel
    private let clusterTappedRelay = PublishRelay<[Photo]>()
    private var selectedPhotos: [Photo] = []
    private var isBottomCardVisible = false
    private let locationManager = CLLocationManager()

    // MARK: - UI

    private let mapView: MKMapView = {
        let m = MKMapView()
        m.showsUserLocation = true
        m.showsCompass = false
        return m
    }()

    // MARK: Map Controls

    private let myLocationButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        b.setImage(UIImage(systemName: "location.fill", withConfiguration: config), for: .normal)
        b.tintColor = UIColor.App.accentBlue
        b.backgroundColor = .white
        b.layer.cornerRadius = 24
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.12
        b.layer.shadowRadius = 8
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        return b
    }()

    // MARK: Bottom Card

    private let bottomCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.97)
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowRadius = 16
        v.layer.shadowOffset = CGSize(width: 0, height: -4)
        return v
    }()

    private let nearbyTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "이 근처 사진"
        l.textColor = UIColor.App.textPrimary
        l.font = UIFont(name: "Pretendard-SemiBold", size: 15) ?? .boldSystemFont(ofSize: 15)
        return l
    }()

    private let nearbySubtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.textSecondary
        l.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        return l
    }()

    private lazy var photoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(NearbyPhotoCell.self, forCellWithReuseIdentifier: NearbyPhotoCell.reuseId)
        cv.dataSource = self
        return cv
    }()

    private var bottomCardBottomConstraint: Constraint?
    private let bottomCardHeight: CGFloat = 156

    // MARK: - Init

    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func setupViews() {
        view.addSubview(mapView)
        view.addSubview(bottomCard)
        bottomCard.addSubview(nearbyTitleLabel)
        bottomCard.addSubview(nearbySubtitleLabel)
        bottomCard.addSubview(photoCollectionView)
        view.addSubview(myLocationButton)

        mapView.delegate = self
        mapView.register(
            PhotoAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PhotoAnnotationView.reuseId
        )
        mapView.register(
            PhotoClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.setUserTrackingMode(.follow, animated: false)
    }

    override func setupConstraints() {
        mapView.snp.makeConstraints { $0.edges.equalToSuperview() }

        bottomCard.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(bottomCardHeight)
            bottomCardBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(bottomCardHeight).constraint
        }

        myLocationButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(bottomCard.snp.top).offset(-16)
            $0.width.height.equalTo(48)
        }

        nearbyTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(20)
        }

        nearbySubtitleLabel.snp.makeConstraints {
            $0.centerY.equalTo(nearbyTitleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        photoCollectionView.snp.makeConstraints {
            $0.top.equalTo(nearbyTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }
    }

    override func bind() {
        let output = viewModel.transform(input: MapViewModel.Input(
            viewDidLoad: .just(()),
            clusterTapped: clusterTappedRelay.asObservable()
        ))

        output.annotations
            .drive(onNext: { [weak self] annotations in
                self?.mapView.addAnnotations(annotations)
            })
            .disposed(by: disposeBag)

        output.selectedPhotos
            .drive(onNext: { [weak self] photos in
                self?.showBottomCard(with: photos)
            })
            .disposed(by: disposeBag)

        output.nearbySubtitle
            .drive(nearbySubtitleLabel.rx.text)
            .disposed(by: disposeBag)

        myLocationButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.mapView.setUserTrackingMode(.follow, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Bottom Card Animation

    private func showBottomCard(with photos: [Photo]) {
        selectedPhotos = photos
        photoCollectionView.reloadData()

        guard !isBottomCardVisible else { return }
        isBottomCardVisible = true

        bottomCardBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    private func hideBottomCard() {
        guard isBottomCardVisible else { return }
        isBottomCardVisible = false

        bottomCardBottomConstraint?.update(offset: bottomCardHeight)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        if annotation is MKClusterAnnotation {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                for: annotation
            )
        }

        if annotation is PhotoAnnotation {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: PhotoAnnotationView.reuseId,
                for: annotation
            )
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photos: [Photo]

        if let cluster = view.annotation as? MKClusterAnnotation {
            photos = cluster.memberAnnotations
                .compactMap { $0 as? PhotoAnnotation }
                .map { $0.photo }
        } else if let single = view.annotation as? PhotoAnnotation {
            photos = [single.photo]
        } else {
            return
        }

        clusterTappedRelay.accept(photos)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        hideBottomCard()
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.setUserTrackingMode(.follow, animated: true)
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MapViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NearbyPhotoCell.reuseId,
            for: indexPath
        ) as! NearbyPhotoCell
        cell.configure(with: selectedPhotos[indexPath.item])
        return cell
    }
}
