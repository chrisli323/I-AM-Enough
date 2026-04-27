//
//  PageCurlView.swift
//  I AM Sober
//
//  Bridges UIPageViewController (.pageCurl) into SwiftUI so the teaching
//  pages turn like a real book. Pages are created lazily by the data
//  source — only the current and one adjacent page are held in memory.
//

import SwiftUI
import UIKit

struct PageCurlView: UIViewControllerRepresentable {

    let pageRange: [Int]
    @Binding var selectedIndex: Int
    /// Factory called by the coordinator to build each page on demand.
    let makeContent: (Int) -> TeachingPage

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        pvc.dataSource = context.coordinator
        pvc.delegate   = context.coordinator
        pvc.isDoubleSided = false
        // Slow the snap-to-completion animation after the user lifts their finger.
        // 1.0 = system default; 0.6 = roughly 40 % slower curl snap.
        pvc.view.layer.speed = 0.6
        // Match the parchment background so the page-curl shadow looks right.
        pvc.view.backgroundColor = UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.08, blue: 0.04, alpha: 1)
                : UIColor(red: 0.969, green: 0.937, blue: 0.851, alpha: 1)
        }

        let initial = context.coordinator.makeVC(for: selectedIndex)
        pvc.setViewControllers([initial], direction: .forward, animated: false)
        context.coordinator.currentIndex = selectedIndex
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        let coord = context.coordinator
        coord.parent = self

        // Push updated props (initialAnimReady, snapToTodaySignal, …) into
        // the currently visible page without recreating it.
        if let current = pvc.viewControllers?.first as? PageHostingController {
            current.rootView = makeContent(current.pageIndex)
        }

        // Programmatic navigation — snap-to-today or any other external change.
        guard coord.currentIndex != selectedIndex else { return }
        let dir: UIPageViewController.NavigationDirection =
            selectedIndex > coord.currentIndex ? .forward : .reverse
        let vc = coord.makeVC(for: selectedIndex)
        pvc.setViewControllers([vc], direction: dir, animated: true)
        coord.currentIndex = selectedIndex
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject,
                             UIPageViewControllerDataSource,
                             UIPageViewControllerDelegate {
        var parent: PageCurlView
        var currentIndex: Int = 0

        init(_ parent: PageCurlView) { self.parent = parent }

        func makeVC(for index: Int) -> PageHostingController {
            PageHostingController(rootView: parent.makeContent(index), index: index)
        }

        // MARK: DataSource

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let hc = vc as? PageHostingController,
                  hc.pageIndex > (parent.pageRange.first ?? 0) else { return nil }
            return makeVC(for: hc.pageIndex - 1)
        }

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let hc = vc as? PageHostingController,
                  hc.pageIndex < (parent.pageRange.last ?? 0) else { return nil }
            return makeVC(for: hc.pageIndex + 1)
        }

        // MARK: Delegate

        /// Fires only when the curl animation fully completes — unlike TabView
        /// which updates selectedIndex at the 50 % swipe mark.
        func pageViewController(_ pvc: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed,
                  let hc = pvc.viewControllers?.first as? PageHostingController else { return }
            currentIndex     = hc.pageIndex
            parent.selectedIndex = hc.pageIndex
        }
    }
}

// MARK: - PageHostingController

/// UIHostingController that carries its page index so the coordinator
/// can identify which page is currently on screen.
final class PageHostingController: UIHostingController<TeachingPage> {
    let pageIndex: Int

    init(rootView: TeachingPage, index: Int) {
        self.pageIndex = index
        super.init(rootView: rootView)
        view.backgroundColor = .clear
    }

    @MainActor required init?(coder: NSCoder) { fatalError() }
}
