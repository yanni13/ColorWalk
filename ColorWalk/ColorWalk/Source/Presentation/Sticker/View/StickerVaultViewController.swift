import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LinkPresentation

final class StickerVaultViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: StickerVaultViewModel
    private let viewWillAppearSubject = PublishSubject<Void>()
    private let deleteStickerSubject = PublishSubject<Sticker>()
    private let renameStickerSubject = PublishSubject<(Sticker, String)>()

    private enum Constants {
        static let columns: CGFloat = 2
        static let horizontalInset: CGFloat = 20
        static let interItemSpacing: CGFloat = 12
        static let cellImageHeight: CGFloat = 160
        static let cellInfoHeight: CGFloat = 56
        static let headerHeight: CGFloat = 52
        static let emptyIconSize: CGFloat = 48
        static let accentPink = UIColor(hex: "#FF7EB3")
    }

    // MARK: - UI: Header

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        b.tintColor = UIColor(hex: "#191F28")
        b.accessibilityLabel = "뒤로 가기"
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "스티커 보관함"
        l.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("편집", for: .normal)
        b.setTitleColor(Constants.accentPink, for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Medium", size: 15) ?? .systemFont(ofSize: 15, weight: .medium)
        b.accessibilityLabel = "편집"
        b.isHidden = true
        return b
    }()

    private let headerView = UIView()

    // MARK: - UI: Scroll

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    // MARK: - UI: Count Bar

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let countBarView = UIView()

    // MARK: - UI: Grid

    private let gridView = UIView()

    // MARK: - UI: Empty State

    private let emptyStateView: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    private let emptyIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "sparkles")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 32, weight: .light))
        iv.tintColor = UIColor(hex: "#B0B8C1")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "아직 저장된 스티커가 없어요"
        l.font = UIFont(name: "Pretendard-Regular", size: 14) ?? .systemFont(ofSize: 14)
        l.textColor = UIColor(hex: "#B0B8C1")
        l.textAlignment = .center
        return l
    }()

    // Keeps track of rendered cells for grid layout
    private var stickerCells: [UIView] = []

    // MARK: - Init

    init(viewModel: StickerVaultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewWillAppearSubject.onNext(())
    }

    // MARK: - Setup

    override func setupViews() {
        view.backgroundColor = UIColor(hex: "#F7F8FA")

        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(editButton)

        countBarView.addSubview(countLabel)

        emptyStateView.addSubview(emptyIconView)
        emptyStateView.addSubview(emptyLabel)

        contentView.addSubview(countBarView)
        contentView.addSubview(gridView)
        contentView.addSubview(emptyStateView)

        scrollView.addSubview(contentView)

        view.addSubview(headerView)
        view.addSubview(scrollView)

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    override func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.headerHeight)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        countBarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            make.height.equalTo(36)
        }
        countLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        gridView.snp.makeConstraints { make in
            make.top.equalTo(countBarView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            make.bottom.equalToSuperview().inset(20)
        }

        emptyStateView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scrollView).offset(160)
        }
        emptyIconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(Constants.emptyIconSize)
        }
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyIconView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bind() {
        let input = StickerVaultViewModel.Input(
            viewWillAppear: viewWillAppearSubject.asObservable(),
            deleteSticker: deleteStickerSubject.asObservable(),
            renameSticker: renameStickerSubject.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.stickers
            .drive(onNext: { [weak self] stickers in
                self?.renderGrid(stickers: stickers)
            })
            .disposed(by: disposeBag)

        output.isEmpty
            .drive(onNext: { [weak self] isEmpty in
                guard let self else { return }
                self.emptyStateView.isHidden = !isEmpty
                self.gridView.isHidden = isEmpty
                self.countBarView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)

        output.stickers
            .map { "총 \($0.count)개의 스티커" }
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Grid Rendering

    private func renderGrid(stickers: [Sticker]) {
        gridView.subviews.forEach { $0.removeFromSuperview() }
        stickerCells = []

        guard !stickers.isEmpty else { return }

        let totalWidth = UIScreen.main.bounds.width - Constants.horizontalInset * 2
        let cellWidth = (totalWidth - Constants.interItemSpacing) / 2
        let cellHeight = Constants.cellImageHeight + Constants.cellInfoHeight

        var rows: [[Sticker]] = []
        var index = 0
        while index < stickers.count {
            let end = min(index + 2, stickers.count)
            rows.append(Array(stickers[index..<end]))
            index += 2
        }

        var previousRow: UIView? = nil
        for (rowIndex, row) in rows.enumerated() {
            let rowView = UIView()
            gridView.addSubview(rowView)

            rowView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let prev = previousRow {
                    make.top.equalTo(prev.snp.bottom).offset(Constants.interItemSpacing)
                } else {
                    make.top.equalToSuperview()
                }
                if rowIndex == rows.count - 1 {
                    make.bottom.equalToSuperview()
                }
                make.height.equalTo(cellHeight)
            }

            var previousCell: UIView? = nil
            for (colIndex, sticker) in row.enumerated() {
                let cell = makeStickerCardView(sticker: sticker)
                rowView.addSubview(cell)

                cell.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.width.equalTo(cellWidth)
                    if let prev = previousCell {
                        make.leading.equalTo(prev.snp.trailing).offset(Constants.interItemSpacing)
                    } else {
                        make.leading.equalToSuperview()
                    }
                }

                addTapGesture(to: cell, sticker: sticker)
                previousCell = cell
                stickerCells.append(cell)
                _ = colIndex
            }

            previousRow = rowView
        }
    }

    private func makeStickerCardView(sticker: Sticker) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: "#E5E8EB").cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.masksToBounds = false
        card.clipsToBounds = false

        let inner = UIView()
        inner.layer.cornerRadius = 16
        inner.layer.masksToBounds = true
        card.addSubview(inner)
        inner.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let checker = CheckerboardCardView()
        inner.addSubview(checker)
        checker.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.cellImageHeight)
        }

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        let url = StickerManager.shared.stickerURL(for: sticker.imagePath)
        if let data = try? Data(contentsOf: url) {
            imageView.image = UIImage(data: data)
        }
        checker.addSubview(imageView)
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview().inset(12) }

        let nameLabel = UILabel()
        nameLabel.text = sticker.colorName
        nameLabel.font = UIFont(name: "Pretendard-SemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = UIColor(hex: "#191F28")
        nameLabel.numberOfLines = 2

        let dateLabel = UILabel()
        dateLabel.text = formatDate(sticker.createdAt)
        dateLabel.font = UIFont(name: "Pretendard-Regular", size: 11) ?? .systemFont(ofSize: 11)
        dateLabel.textColor = UIColor(hex: "#B0B8C1")

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        inner.addSubview(infoStack)
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(checker.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(10)
        }

        return card
    }

    private func addTapGesture(to view: UIView, sticker: Sticker) {
        let tap = UITapGestureRecognizer()
        tap.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.presentActionSheet(for: sticker)
            })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
    }

    private func presentActionSheet(for sticker: Sticker) {
        let sheet = StickerActionSheetViewController(sticker: sticker)
        sheet.onRename = { [weak self] in
            self?.presentRenameAlert(for: sticker)
        }
        sheet.onCopy = { [weak self] in
            self?.copySticker(sticker)
        }
        sheet.onShare = { [weak self] in
            self?.shareSticker(sticker)
        }
        sheet.onDelete = { [weak self] in
            self?.confirmDelete(sticker: sticker)
        }
        present(sheet, animated: false)
    }

    private func presentRenameAlert(for sticker: Sticker) {
        let alert = UIAlertController(title: "이름 변경", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = sticker.colorName
            tf.placeholder = "스티커 이름"
            tf.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "변경", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.renameStickerSubject.onNext((sticker, name))
        })
        present(alert, animated: true)
    }

    private func copySticker(_ sticker: Sticker) {
        let url = StickerManager.shared.stickerURL(for: sticker.imagePath)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        UIPasteboard.general.image = image
    }

    private func shareSticker(_ sticker: Sticker) {
        let url = StickerManager.shared.stickerURL(for: sticker.imagePath)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        let itemSource = StickerShareItemSource(image: image, name: sticker.colorName)
        let activity = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
        present(activity, animated: true)
    }

    private func confirmDelete(sticker: Sticker) {
        let alert = UIAlertController(
            title: "스티커 삭제",
            message: "이 스티커를 삭제하시겠어요?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteStickerSubject.onNext(sticker)
        })
        present(alert, animated: true)
    }

    // MARK: - Helper

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - StickerShareItemSource

private final class StickerShareItemSource: NSObject, UIActivityItemSource {

    private let image: UIImage
    private let name: String

    init(image: UIImage, name: String) {
        self.image = image
        self.name = name
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = name
        metadata.imageProvider = NSItemProvider(object: image)
        if let icon = appIcon() {
            metadata.iconProvider = NSItemProvider(object: icon)
        }
        return metadata
    }

    private func appIcon() -> UIImage? {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let lastName = files.last
        else { return nil }
        return UIImage(named: lastName)
    }
}

// MARK: - CheckerboardCardView

private final class CheckerboardCardView: UIView {

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
