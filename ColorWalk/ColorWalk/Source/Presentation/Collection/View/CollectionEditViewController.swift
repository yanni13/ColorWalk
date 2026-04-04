import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CollectionEditViewController: BaseViewController {

    // MARK: - Constants

    private enum Constants {
        static let maxSelection: Int = 9
        static let columnCount: CGFloat = 3
        static let cellGap: CGFloat = 2
        static let navHeight: CGFloat = 60
        static let instructionBarHeight: CGFloat = 38
        static let bottomBarTopPadding: CGFloat = 16
        static let bottomBarBottomPadding: CGFloat = 40
        static let completeButtonHeight: CGFloat = 56
        static let selectionBadgeSize: CGFloat = 22
    }

    // MARK: - Properties

    private let viewModel: CollectionEditViewModel
    private let photoTapRelay = PublishRelay<Int>()

    // MARK: - UI: Navigation

    private let navContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(hex: "#191F28")
        button.backgroundColor = UIColor(hex: "#F5F7FA")
        button.layer.cornerRadius = 18
        button.accessibilityLabel = "닫기"
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "사진 선택"
        label.font = UIFont(name: "Pretendard-Bold", size: 16)
        label.textColor = UIColor(hex: "#191F28")
        return label
    }()

    private let selectionCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 / 9"
        label.font = UIFont(name: "Pretendard-Medium", size: 14)
        label.textColor = UIColor(hex: "#8E95A2")
        return label
    }()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전체 해제", for: .normal)
        button.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 14)
        button.setTitleColor(UIColor(hex: "#6B7684"), for: .normal)
        button.backgroundColor = UIColor(hex: "#F5F7FA")
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        button.accessibilityLabel = "전체 해제"
        return button
    }()

    // MARK: - UI: Instruction Bar

    private let instructionBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F5F7FA")
        return view
    }()

    private let instructionIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let imageView = UIImageView(image: UIImage(systemName: "info.circle", withConfiguration: config))
        imageView.tintColor = UIColor(hex: "#8E95A2")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "그리드에 담을 사진 9장을 선택하세요"
        label.font = UIFont(name: "Pretendard-Medium", size: 12)
        label.textColor = UIColor(hex: "#8E95A2")
        return label
    }()

    // MARK: - UI: Collection

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Constants.cellGap
        layout.minimumInteritemSpacing = Constants.cellGap
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.register(PhotoPickerCell.self, forCellWithReuseIdentifier: PhotoPickerCell.reuseIdentifier)
        return cv
    }()

    // MARK: - UI: Bottom Bar

    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let bottomBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#ECEEF2")
        return view
    }()

    private let selectedTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "선택한 사진"
        label.font = UIFont(name: "Pretendard-Medium", size: 13)
        label.textColor = UIColor(hex: "#8E95A2")
        return label
    }()

    private let countBadge: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UIFont(name: "Pretendard-SemiBold", size: 13)
        label.textColor = UIColor(hex: "#191F28")
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex: "#F5F7FA")
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()

    private let completeButton = AppButton(style: .primary, title: "완료하기")

    // MARK: - Init

    init(viewModel: CollectionEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func setupViews() {
        view.backgroundColor = .white

        view.addSubview(navContainer)
        navContainer.addSubview(closeButton)
        navContainer.addSubview(titleLabel)
        navContainer.addSubview(selectionCountLabel)
        navContainer.addSubview(doneButton)

        view.addSubview(instructionBar)
        instructionBar.addSubview(instructionIcon)
        instructionBar.addSubview(instructionLabel)

        view.addSubview(collectionView)
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)

        view.addSubview(bottomBar)
        bottomBar.addSubview(bottomBorderView)
        bottomBar.addSubview(selectedTitleLabel)
        bottomBar.addSubview(countBadge)
        bottomBar.addSubview(completeButton)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    override func setupConstraints() {
        navContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.navHeight)
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(selectionCountLabel.snp.top).offset(-2)
        }

        selectionCountLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(8)
        }

        doneButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
        }

        instructionBar.snp.makeConstraints { make in
            make.top.equalTo(navContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.instructionBarHeight)
        }

        instructionIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(13)
        }

        instructionLabel.snp.makeConstraints { make in
            make.leading.equalTo(instructionIcon.snp.trailing).offset(5)
            make.centerY.equalToSuperview()
        }

        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        bottomBorderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        selectedTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(bottomBorderView.snp.bottom).offset(Constants.bottomBarTopPadding)
            make.leading.equalToSuperview().offset(20)
        }

        countBadge.snp.makeConstraints { make in
            make.centerY.equalTo(selectedTitleLabel)
            make.leading.equalTo(selectedTitleLabel.snp.trailing).offset(8)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(32)
        }

        completeButton.snp.makeConstraints { make in
            make.top.equalTo(selectedTitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(Constants.completeButtonHeight)
            make.bottom.equalToSuperview().inset(34)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(instructionBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
    }

    // MARK: - Bind

    override func bind() {
        let output = viewModel.transform(input: CollectionEditViewModel.Input(
            photoTap: photoTapRelay.asObservable(),
            doneTap: completeButton.rx.tap.asObservable(),
            deselectAllTap: doneButton.rx.tap.asObservable()
        ))

        output.photoItems
            .drive(collectionView.rx.items(
                cellIdentifier: PhotoPickerCell.reuseIdentifier,
                cellType: PhotoPickerCell.self
            )) { [weak self] index, item, cell in
                guard let self else { return }
                cell.configure(with: item)
                cell.onTap = { self.photoTapRelay.accept(index) }
            }
            .disposed(by: disposeBag)

        output.selectedCount
            .drive(onNext: { [weak self] count in
                guard let self else { return }
                self.selectionCountLabel.text = "\(count) / \(Constants.maxSelection)"
                self.countBadge.text = "\(count)"
            })
            .disposed(by: disposeBag)

        output.saveCompleted
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Action

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CollectionEditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalGap = Constants.cellGap * (Constants.columnCount - 1)
        let width = (collectionView.frame.width - totalGap) / Constants.columnCount
        return CGSize(width: width, height: width)
    }
}

// MARK: - PhotoPickerCell

final class PhotoPickerCell: UICollectionViewCell {

    static let reuseIdentifier = "PhotoPickerCell"

    var onTap: (() -> Void)?

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#F2F4F6")
        return iv
    }()

    private let dimOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        view.isHidden = true
        return view
    }()

    private let selectionBadge: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Bold", size: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex: "#191F28")
        label.layer.cornerRadius = 11
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(dimOverlay)
        contentView.addSubview(selectionBadge)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        dimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        selectionBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().inset(6)
            make.width.height.equalTo(22)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tapGesture)
        contentView.accessibilityLabel = "사진"
        contentView.isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        dimOverlay.isHidden = true
        selectionBadge.isHidden = true
        selectionBadge.text = nil
    }

    func configure(with item: PhotoPickerItem) {
        imageView.image = ImageFileManager.shared.loadThumbnail(
            fileName: item.imagePath,
            size: CGSize(width: 200, height: 200)
        )
        if item.isSelected, let order = item.selectionOrder {
            dimOverlay.isHidden = false
            selectionBadge.isHidden = false
            selectionBadge.text = "\(order)"
        } else {
            dimOverlay.isHidden = true
            selectionBadge.isHidden = true
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
