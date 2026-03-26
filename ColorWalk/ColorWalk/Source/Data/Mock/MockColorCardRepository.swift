import UIKit

final class MockColorCardRepository: ColorCardRepositoryProtocol {

    // MARK: - ColorCardRepositoryProtocol

    func fetchColorCards() -> [ColorCard] {
        ColorCard.mockCards
    }
}
