//
//  PurchaseManager.swift
//  I AM Enough
//
//  Manages the one-time $4.99 "Unlock I AM Enough" in-app purchase
//  using StoreKit 2. Persists unlock status to UserDefaults so the
//  UI is instant on relaunch without an async verification round-trip.
//

import StoreKit
import Foundation

@Observable
final class PurchaseManager {

    /// Product ID registered in App Store Connect — and mirrored in
    /// StoreKit.storekit for local simulator testing.
    static let productID = "com.chrisli323.iamenough.unlock"

    /// True once the purchase is verified. Persisted to UserDefaults
    /// so the paywall never flashes on relaunch.
    private(set) var isUnlocked: Bool

    /// Loaded asynchronously at init — used to show the localised price.
    private(set) var product: Product?

    /// True while a purchase network call is in flight.
    private(set) var isPurchasing = false

    private var listenerTask: Task<Void, Never>?

    init() {
        // Restore cached state immediately — no async needed.
        self.isUnlocked = UserDefaults.standard.bool(forKey: "isAppUnlocked")
        self.product    = nil

        // Listen for transactions delivered outside the app (e.g. ask-to-buy
        // approvals, cross-device restores, subscription renewals).
        listenerTask = Task {
            for await result in Transaction.updates {
                guard case .verified(let tx) = result,
                      tx.productID == Self.productID else { continue }
                self.markUnlocked()
                await tx.finish()
            }
        }

        // Load product metadata and re-verify entitlements on every launch.
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    deinit { listenerTask?.cancel() }

    // MARK: - Product

    func loadProduct() async {
        guard let p = try? await Product.products(for: [Self.productID]).first else { return }
        product = p
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()
        guard case .success(let verification) = result else { return }

        let tx = try checkVerified(verification)
        markUnlocked()
        await tx.finish()
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Entitlement check

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == Self.productID else { continue }
            markUnlocked()
            return
        }
    }

    // MARK: - Helpers

    private func markUnlocked() {
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: "isAppUnlocked")
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value):      return value
        }
    }
}
