import Foundation

final class MLCategoryPredictor {
    static let shared = MLCategoryPredictor()
    private init() {}

    // Generic to avoid coupling to a specific Transaction type
    func trainWithUserData<T>(transactions: [T]) {
        guard !transactions.isEmpty else { return }
        // Placeholder training routine. Replace with Core ML training if needed.
        #if DEBUG
        print("[MLCategoryPredictor] Training started with \(transactions.count) transactions…")
        #endif
        // Simulate lightweight background work; any heavy lifting should already be dispatched by the caller.
        // Insert your real training logic here.
        #if DEBUG
        print("[MLCategoryPredictor] Training completed.")
        #endif
    }
}
