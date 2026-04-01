import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CollectionEditViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: CollectionEditViewModel
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "그리드 편집"
        label.font = UIFont(name: "Pretendard-Bold", size: 18)
        label.textColor = UIColor(hex: "#191F28")
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "사진을 길게 눌러서 위치를 변경해보세요."
        label.font = UIFont(name: "Pretendard-Medium", size: 14)
        label.textColor = UIColor(hex: "#6B7684")
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(EditPhotoCell.self, forCellWithReuseIdentifier: "EditPhotoCell")
        return cv
    }()

    private let saveButton = AppButton(style: .primary, title: "저장하기")

    // MARK: - Init

    init(viewModel: CollectionEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "그리드 편집"
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        closeButton.tintColor = UIColor(hex: "#191F28")
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func setupViews() {
        view.backgroundColor = UIColor(hex: "#F7F8FA")
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(collectionView)
        view.addSubview(saveButton)
    }

    override func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(collectionView.snp.width)
        }
        
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
    }

    override func bind() {
        let output = viewModel.transform(input: CollectionEditViewModel.Input(
            saveTap: saveButton.rx.tap.asObservable()
        ))
        
        output.slots
            .drive(collectionView.rx.items(cellIdentifier: "EditPhotoCell", cellType: EditPhotoCell.self)) { _, slot, cell in
                cell.configure(with: slot)
            }
            .disposed(by: disposeBag)
            
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        
        output.saveCompleted
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension CollectionEditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 4) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: - Cell

final class EditPhotoCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hex: "#F2F4F6")
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with slot: SlotDisplayInfo) {
        if let path = slot.imagePath {
            imageView.image = ImageFileManager.shared.loadThumbnail(fileName: path, size: CGSize(width: 200, height: 200))
        } else if let hex = slot.capturedHex {
            imageView.backgroundColor = UIColor(hex: hex)
        }
    }
}
