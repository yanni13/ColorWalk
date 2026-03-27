import UIKit
import SnapKit

final class MissionPhotoGridView: UIView {

    // MARK: - Properties

    private enum Constants {
        static let cellGap: CGFloat = 2
        static let cellCornerRadius: CGFloat = 8
    }

    private var imageViews: [UIImageView] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGrid()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGrid()
    }

    // MARK: - Setup

    private func setupGrid() {
        clipsToBounds = true
        let verticalStack = makeVerticalStack()
        addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeVerticalStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.cellGap
        stack.distribution = .fillEqually
        for row in 0..<3 {
            stack.addArrangedSubview(makeRowStack(row: row))
        }
        return stack
    }

    private func makeRowStack(row: Int) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.cellGap
        stack.distribution = .fillEqually
        for col in 0..<3 {
            let cell = makeCell(row: row, col: col)
            imageViews.append(cell)
            stack.addArrangedSubview(cell)
        }
        return stack
    }

    private func makeCell(row: Int, col: Int) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.App.bgSecondary
        applyCellCornerRadius(to: imageView, row: row, col: col)
        return imageView
    }

    private func applyCellCornerRadius(to view: UIImageView, row: Int, col: Int) {
        var corners: CACornerMask = []
        if row == 0 && col == 0 { corners.insert(.layerMinXMinYCorner) }
        if row == 0 && col == 2 { corners.insert(.layerMaxXMinYCorner) }
        if row == 2 && col == 0 { corners.insert(.layerMinXMaxYCorner) }
        if row == 2 && col == 2 { corners.insert(.layerMaxXMaxYCorner) }
        guard !corners.isEmpty else { return }
        view.layer.cornerRadius = Constants.cellCornerRadius
        view.layer.maskedCorners = corners
    }

    // MARK: - Public

    func configure(with slots: [SlotDisplayInfo]) {
        slots.enumerated().forEach { index, slot in
            guard index < imageViews.count else { return }
            updateCell(at: index, with: slot)
        }
    }

    func clearSlots() {
        imageViews.forEach { imageView in
            imageView.image = nil
            imageView.backgroundColor = UIColor.App.bgSecondary
        }
    }

    // MARK: - Private

    private func updateCell(at index: Int, with slot: SlotDisplayInfo) {
        let imageView = imageViews[index]
        guard slot.isCaptured, let path = slot.imagePath else {
            imageView.image = nil
            imageView.backgroundColor = UIColor.App.bgSecondary
            return
        }
        imageView.image = UIImage(contentsOfFile: path)
        if let hex = slot.capturedHex {
            imageView.backgroundColor = UIColor(hex: hex)
        }
    }
}
