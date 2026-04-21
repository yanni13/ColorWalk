import UIKit

final class StickerManager {

    // MARK: - Properties

    static let shared = StickerManager()

    private enum Constants {
        static let folderName = "stickers"
    }

    private var stickersDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(Constants.folderName)
    }

    private init() {
        try? FileManager.default.createDirectory(at: stickersDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public

    func save(image: UIImage, colorName: String, hex: String) -> Sticker? {
        guard let data = image.pngData() else { return nil }
        let fileName = UUID().uuidString + ".png"
        let fileURL = stickersDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
        } catch {
            print("[StickerManager] 파일 저장 실패: \(error)")
            return nil
        }
        let sticker = Sticker()
        sticker.imagePath = fileName
        sticker.colorName = colorName
        sticker.hexColor = hex
        sticker.createdAt = Date()
        RealmManager.shared.saveSticker(sticker)
        return sticker
    }

    func stickerURL(for fileName: String) -> URL {
        stickersDirectory.appendingPathComponent(fileName)
    }

    func delete(_ sticker: Sticker) {
        let fileURL = stickerURL(for: sticker.imagePath)
        try? FileManager.default.removeItem(at: fileURL)
        RealmManager.shared.deleteSticker(sticker)
    }

    func fetchAll() -> [Sticker] {
        RealmManager.shared.fetchAllStickers()
    }

    func updateName(_ newName: String, for sticker: Sticker) {
        RealmManager.shared.updateStickerName(sticker, name: newName)
    }
}
