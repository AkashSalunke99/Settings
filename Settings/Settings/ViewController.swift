import UIKit

class ViewController: UIViewController {
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var collectionData: [Section: [Item]] = [
        Section(): [
            Item(model: Model(title: "General", image: UIImage(named: "General"))),
            Item(model: Model(title: "About", image: UIImage(named: "About")))],
        Section(): [
            Item(model: Model(title: "Privacy and Security", image: UIImage(named: "Privacy and Security"))),
            Item(model: Model(title: "Health", image: UIImage(named: "Health")))]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: Configure Collection View

extension ViewController {
    func setupUI() {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        self.navigationItem.titleView = searchBar
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(menuButtonTapped))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(editButtonTapped))
        configureCollectionView()
        configureDataSource()
        applyInitialSnapshot()
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout {  section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.headerMode = .firstItemInSection
            config.showsSeparators = true
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }
    
    private func configureDataSource() {
        let expandableSectionHeaderRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Model> { (cell, indexPath, model) in
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = model.title
            contentConfiguration.textProperties.font = .boldSystemFont(ofSize: 20)
            contentConfiguration.image = model.image
            contentConfiguration.imageProperties.maximumSize = CGSizeMake(30, 30)
            contentConfiguration.imageToTextPadding = 20
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [
                .insert(actionHandler: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.showAlertController(title: "Place item in section", message: "Please give title to item", at: indexPath.section)
                }),
                .outlineDisclosure(), .delete(actionHandler: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.deleteSection(at: indexPath.section)
                })
            ]
        }
        let itemRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Model> { (cell, indexPath, model) in
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = model.title
            contentConfiguration.textProperties.font = .boldSystemFont(ofSize: 15)
            contentConfiguration.image = model.image
            contentConfiguration.imageProperties.maximumSize = CGSizeMake(30, 30)
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.delete(actionHandler: { [weak self] in
                guard let self = self else {
                    return
                }
                self.deleteItem(at: indexPath)
            })]
        }
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
            return collectionView.dequeueConfiguredReusableCell(using: indexPath.row == 0 ? expandableSectionHeaderRegistration: itemRegistration, for: indexPath, item: item.model)
        }
    }
}

// MARK: DataSource

extension ViewController {
    func applyInitialSnapshot() {
        for (section, items) in collectionData {
            addNewSection(section, with: items)
        }
    }
    
    func addNewSection(_ section: Section, with items: [Item]) {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        if items.count == 1 {
            sectionSnapshot.append(items)
        } else {
            sectionSnapshot.append([items[0]])
            sectionSnapshot.append(Array(items.dropFirst()), to: sectionSnapshot.items[0])
        }
        dataSource.apply(sectionSnapshot, to: section, animatingDifferences: true)
    }
    
    func addItem(_ items: [Item], at sectionIndex: Int) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[sectionIndex]
        var sectionSnapshot = dataSource.snapshot(for: section)
        sectionSnapshot.append(items, to: sectionSnapshot.items[0])
        dataSource.apply(sectionSnapshot, to: section, animatingDifferences: true)
        collectionData[section]?.append(contentsOf: items)
    }
    
    func deleteSection(at sectionIndex: Int) {
        var snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[sectionIndex]
        snapshot.deleteSections([section])
        dataSource.apply(snapshot)
        collectionView.reloadData()
        collectionData[section] = nil
    }
    
    func deleteItem(at indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        var sectionSnapshot = dataSource.snapshot(for: section)
        sectionSnapshot.delete([sectionSnapshot.items[indexPath.row]])
        dataSource.apply(sectionSnapshot, to: section, animatingDifferences: true)
        collectionView.reloadData()
        collectionData[section]?.remove(at: indexPath.row)
    }
}

// MARK: Helper Methods

extension ViewController {
    func showAlertController(title: String, message: String, at section: Int?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "(Required) Title"
            textField.textAlignment = .center
            textField.clearButtonMode = .whileEditing
            textField.autocorrectionType = .no
            textField.spellCheckingType = .no
            
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                alertController.actions.first?.isEnabled = textField.text!.count > 0
            }
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (action) in
            guard let self = self else {
                return
            }
            let textFields = alertController.textFields!
            guard let title = textFields[0].text, !title.isEmpty else {
                return
            }
            let image = UIImage(named: title) ?? UIImage(named: "iOS")
            let item = Item(model: Model(title: title, image: image))
            if let section = section {
                self.addItem([item], at: section)
            } else {
                let section = Section()
                collectionData[section] = [item]
                self.addNewSection(section, with: [item])
            }
        }
        okAction.isEnabled = false
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func menuButtonTapped() {
        showAlertController(title: "New section", message: "Add header title of section", at: nil)
    }
    
    @objc func editButtonTapped(_ button: UIBarButtonItem) {
        collectionView.isEditing = collectionView.isEditing ? false: true
        self.navigationItem.leftBarButtonItem?.title = collectionView.isEditing ? "Done": "Edit"
    }
}

// MARK: UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot)
        performQuery(with: searchText)
    }
    
    func performQuery(with filter: String?) {
        for (section, items) in collectionData {
            var filteredItems = items.filter {
                $0.contains(filter)
            }
            if filteredItems.count > 0 {
                addNewSection(section, with: filteredItems)
            }
        }
    }
}
