import UIKit
import SnapKit

final class MissionPhotoGridView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cellGap: CGFloat = 2
        static let containerCornerRadius: CGFloat = 8
    }

    // MARK: - Properties

    private var imageViews: [UIImageView] = []
    private var currentSlots: [SlotDisplayInfo] = []
    private(set) var currentLayout: GridLayoutType = .threeByThree

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildGrid(for: .threeByThree)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildGrid(for: .threeByThree)
    }

    // MARK: - Setup

    private func buildGrid(for layout: GridLayoutType) {
        clipsToBounds = true
        layer.cornerRadius = Constants.containerCornerRadius

        switch layout {
        case .twoByTwo:
            buildEqualGrid(rows: 2, cols: 2)
        case .threeByThree:
            buildEqualGrid(rows: 3, cols: 3)
        case .twoByThree:
            buildTwoThreeGrid()
        case .filmStrip:
            buildFilmStripGrid()
        }
    }

    /// 균일한 rows × cols 그리드
    private func buildEqualGrid(rows: Int, cols: Int) {
        let outerStack = makeStack(axis: .vertical)
        for _ in 0..<rows {
            let rowStack = makeStack(axis: .horizontal)
            for _ in 0..<cols {
                let cell = makeCell()
                imageViews.append(cell)
                rowStack.addArrangedSubview(cell)
            }
            outerStack.addArrangedSubview(rowStack)
        }
        pin(outerStack)
    }

    /// gI9h3 디자인: 왼쪽 컬럼 2셀 + 오른쪽 컬럼 3셀 (총 5슬롯)
    private func buildTwoThreeGrid() {
        let outerStack = makeStack(axis: .horizontal)

        let leftStack = makeStack(axis: .vertical)
        for _ in 0..<2 {
            let cell = makeCell()
            imageViews.append(cell)
            leftStack.addArrangedSubview(cell)
        }

        let rightStack = makeStack(axis: .vertical)
        for _ in 0..<3 {
            let cell = makeCell()
            imageViews.append(cell)
            rightStack.addArrangedSubview(cell)
        }

        outerStack.addArrangedSubview(leftStack)
        outerStack.addArrangedSubview(rightStack)
        pin(outerStack)
    }

    /// fn4k1 디자인: 1컬럼 × 3행, 가로형 셀 (총 3슬롯)
    private func buildFilmStripGrid() {
        let stack = makeStack(axis: .vertical)
        for _ in 0..<3 {
            let cell = makeCell()
            imageViews.append(cell)
            stack.addArrangedSubview(cell)
        }
        pin(stack)
    }

    private func makeStack(axis: NSLayoutConstraint.Axis) -> UIStackView {
        let stack = UIStackView()
        stack.axis = axis
        stack.spacing = Constants.cellGap
        stack.distribution = .fillEqually
        return stack
    }

    private func makeCell() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.App.bgSecondary
        return imageView
    }

    private func pin(_ view: UIView) {
        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Public

    func setLayout(_ layout: GridLayoutType) {
        guard layout != currentLayout else { return }
        currentLayout = layout
        subviews.forEach { $0.removeFromSuperview() }
        imageViews = []
        buildGrid(for: layout)
        configure(with: currentSlots)
    }

    func configure(with slots: [SlotDisplayInfo]) {
        currentSlots = slots
        slots.enumerated().forEach { index, slot in
            guard index < imageViews.count else { return }
            updateCell(at: index, with: slot)
        }
    }

    func clearSlots() {
        currentSlots = []
        imageViews.forEach { imageView in
            imageView.image = nil
            imageView.backgroundColor = UIColor.App.bgSecondary
        }
    }

    // MARK: - Private

    private func updateCell(at index: Int, with slot: SlotDisplayInfo) {
        let imageView = imageViews[index]
        guard slot.isCaptured, let fileName = slot.imagePath else {
            imageView.image = nil
            imageView.backgroundColor = UIColor.App.bgSecondary
            return
        }

        imageView.image = ImageFileManager.shared.loadThumbnail(
            fileName: fileName,
            size: thumbnailCellSize
        )

        if let hex = slot.capturedHex {
            imageView.backgroundColor = UIColor(hex: hex)
        }
    }

    /// 레이아웃별 실제 셀 표시 크기에 맞춘 썸네일 요청 사이즈
    /// loadThumbnail은 max(w, h) × scale 로 최장변을 제한하므로 셀 최대 변을 전달
    private var thumbnailCellSize: CGSize {
        switch currentLayout {
        case .threeByThree:
            return CGSize(width: 160, height: 160)
        case .twoByTwo, .twoByThree:
            return CGSize(width: 220, height: 220)
        case .filmStrip:
            return CGSize(width: 380, height: 380)
        }
    }
}
