import UIKit

final class ScreenshotsViewController: UIViewController {

    var onClose: (() -> Void)?
    override var navigationItem: UINavigationItem {
        let item = UINavigationItem(title: "Details")
        item.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapClose)
        )
        return item
    }

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    private lazy var dataSource = DataSource(collectionView: collectionView) { [cellRegistration] collectionView, indexPath, item in
        collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
    }
    private let cellRegistration = UICollectionView.CellRegistration<Cell, URL> { cell, indexPath, item in
        cell.image = UIImage(contentsOfFile: item.path)
        cell.fileName = item.lastPathComponent
    }
    private let collectionViewLayout: UICollectionViewLayout = {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let layoutGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [layoutItem]
        )

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .paging
        let config = UICollectionViewCompositionalLayoutConfiguration()
        return UICollectionViewCompositionalLayout(section: layoutSection, configuration: config)
    }()
    private let slider: UISlider = {
        let subview = UISlider()
        return subview
    }()
    private let screenshotURLs: [URL]

    init(screenshotsURL: URL) {
        do {
            var screenshots = try FileManager.default.contentsOfDirectory(
                at: screenshotsURL,
                includingPropertiesForKeys: nil
            )
            screenshots.sort(by: { $0.path < $1.path })
            self.screenshotURLs = screenshots
        } catch {
            print("Error while reading screenshot URLs: \(error)")
            self.screenshotURLs = []
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    @available(*, unavailable)
    init() {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(collectionView)
        view.addSubview(slider)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            slider.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            collectionView.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -8)
        ])

        slider.minimumValue = 0
        slider.maximumValue = Float(screenshotURLs.count)
        slider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)

        var snapshot = NSDiffableDataSourceSnapshot<Int, URL>()
        snapshot.appendSections([0])
        snapshot.appendItems(screenshotURLs)
        dataSource.apply(snapshot)
    }

    @objc
    private func sliderDidChange(_ slider: UISlider) {
        let idx = Int(slider.value.rounded())
        guard idx >= 0 && idx < screenshotURLs.count else {
            return
        }
        collectionView.scrollToItem(at: .init(item: idx, section: 0), at: .centeredHorizontally, animated: false)
    }

    @objc
    private func didTapClose() {
        onClose?()
    }
}

private extension ScreenshotsViewController {

    private typealias DataSource = UICollectionViewDiffableDataSource<Int, URL>

    private class Cell: UICollectionViewCell {
        static let reuseIdentifier = "Cell"

        var image: UIImage? {
            get { imageView.image }
            set { imageView.image = newValue }
        }

        var fileName: String? {
            get { fileNameLabel.text }
            set { fileNameLabel.text = newValue }
        }

        private let imageView: UIImageView = {
            let subview = UIImageView()
            subview.contentMode = .scaleAspectFit
            subview.backgroundColor = .lightGray
            return subview
        }()

        private let fileNameLabel: UILabel = {
            let subview = UILabel()
            subview.textAlignment = .center
            subview.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            return subview
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        private func commonInit() {
            contentView.addSubview(imageView)
            contentView.addSubview(fileNameLabel)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: fileNameLabel.topAnchor),
                fileNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                fileNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                fileNameLabel.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
    }
}
