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
    private let locationManager = CLLocationManager()

    // MARK: - UI

    private let mapView: MKMapView = {
        let m = MKMapView()
        m.showsUserLocation = true
        m.showsCompass = false
        return m
    }()

    private let myLocationButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        b.setImage(UIImage(systemName: "location.fill", withConfiguration: config), for: .normal)
        b.tintColor = UIColor.App.accentBlue
        
        // Glassmorphism
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.layer.cornerRadius = 24
        blur.clipsToBounds = true
        blur.isUserInteractionEnabled = false
        
        let dim = UIView()
        dim.backgroundColor = UIColor.white.withAlphaComponent(0.65)
        dim.layer.cornerRadius = 24
        dim.clipsToBounds = true
        dim.isUserInteractionEnabled = false

        b.addSubview(blur)
        b.addSubview(dim)
        blur.snp.makeConstraints { $0.edges.equalToSuperview() }
        dim.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.12
        b.layer.shadowRadius = 8
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.accessibilityLabel = "내 위치로 이동"
        return b
    }()

    // MARK: - Init

    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func setupViews() {
        view.addSubview(mapView)
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
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        myLocationButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.width.height.equalTo(48)
        }
    }

    override func bind() {
        let output = viewModel.transform(input: MapViewModel.Input(
            viewDidLoad: rx.viewDidLoad.asObservable(),
            viewWillAppear: rx.viewWillAppear.asObservable().map { _ in },
            clusterTapped: clusterTappedRelay.asObservable()
        ))

        output.annotations
            .drive(onNext: { [weak self] annotations in
                guard let self = self else { return }
                // 기존 어노테이션(사용자 위치 제외) 삭제 후 새로운 어노테이션 추가
                let existing = self.mapView.annotations.filter { !($0 is MKUserLocation) }
                self.mapView.removeAnnotations(existing)
                self.mapView.addAnnotations(annotations)
            })
            .disposed(by: disposeBag)

        output.selectedPhotos
            .drive(onNext: { [weak self] photos in
                self?.presentNearbyPhotosSheet(with: photos)
            })
            .disposed(by: disposeBag)

        myLocationButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.mapView.setUserTrackingMode(.follow, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helper

    private func presentNearbyPhotosSheet(with photos: [Photo]) {
        let sheetVC = NearbyPhotosSheetViewController(photos: photos)
        sheetVC.modalPresentationStyle = .pageSheet
        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        (tabBarController ?? self).present(sheetVC, animated: true)
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
                .flatMap { $0.photos }
        } else if let single = view.annotation as? PhotoAnnotation {
            photos = single.photos
        } else {
            return
        }

        clusterTappedRelay.accept(photos)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {}
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
