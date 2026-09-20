import Foundation

/// Restrained radii. Photography can go edge-to-edge; controls stay slightly rounded, never pill-like.
enum Radius {
    static let none: CGFloat = 0
    static let pack: CGFloat = 2
    static let tile: CGFloat = 4
    static let object: CGFloat = 4
    static let panel: CGFloat = 4
    static let control: CGFloat = 4
}
