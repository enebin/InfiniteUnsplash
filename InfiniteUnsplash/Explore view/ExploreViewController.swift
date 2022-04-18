//
//  ExploreViewController.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import UIKit
import Combine

class ExploreViewController: UIViewController {
    private var viewModel = ExploreViewModel()
    private var subscriptions = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Section, ImageMetaData>?
    
    // Section used in diffableDataSource
    enum Section: Int, CaseIterable {
        case main
    }
    
    lazy var alert: UIAlertController = {
        let alert =  UIAlertController(title: "Error!", message: "데이터를 불러오는 데 실패했습니다. 잠시 후 다시 시도해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

        return alert
    }()
    
    // Drag refresh controller
    lazy var refreshControll: UIRefreshControl = {
        let refreshControll = UIRefreshControl()
        refreshControll.tintColor = .white
        refreshControll.addTarget(self, action: #selector(refresh(_:)), for: .allEvents)
        
        return refreshControll
    }()
    
    // Set collection view
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 0
        layout.invalidateLayout()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageViewCell")
        collectionView.backgroundColor = .black
        collectionView.isPrefetchingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.delegate = self
        collectionView.prefetchDataSource = self

        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setLayout()
        setupDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.topItem?.title = "Unsplash"
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    @objc func refresh(_ sender: Any) {
        viewModel.fetchImageMetaData(page: 1)
    }

    // Layout UI
    func setLayout() {
        view.addSubview(collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: self.collectionView,
                                                   attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top,
                                                   multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.collectionView,
                                                   attribute: .bottom, relatedBy: .equal, toItem: self.view,
                                                   attribute: .bottom, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.collectionView,
                                                   attribute: .leading, relatedBy: .equal, toItem: self.view,
                                                   attribute: .leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.collectionView,
                                                   attribute: .trailing, relatedBy: .equal, toItem: self.view,
                                                   attribute: .trailing, multiplier: 1.0, constant: 0))
        
        self.collectionView.refreshControl = refreshControll
    }
    
    // Set datasource
    func setupDataSource() {
        self.dataSource =
        UICollectionViewDiffableDataSource<Section, ImageMetaData>(collectionView: self.collectionView) {
            (collectionView, indexPath, source) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as? ImageCell
            else { preconditionFailure() }
    
            cell.setUp(viewModel: ImageCellViewModel(source: source))
            return cell
        }
        
        // Bind image data
        self.viewModel.imageMetaData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedData in
                guard let self = self else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<Section, ImageMetaData>()
                snapshot.appendSections([.main])
                snapshot.appendItems(updatedData)
                self.dataSource?.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &subscriptions)
        
        self.viewModel.process
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    switch status {
                    case .finished:
                        self.refreshControll.endRefreshing()
                    case .failedWithError:
                        self.present(self.alert, animated: true, completion: nil)
                        break
                    default:
                        break
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

extension ExploreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let imageRelatedData = viewModel.imageMetaData.value[indexPath.row]
        let cellWidth = collectionView.frame.width
        let cellHeight = imageRelatedData.imageRatio * cellWidth
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}


extension ExploreViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let row = indexPaths.first?.row else {
            return
        }
        
        let dataSources = self.viewModel.imageMetaData.value
        let source = dataSources[row]
        
        self.viewModel.preCaching(source: source)
        
        if row == dataSources.count - 3 {
            DispatchQueue.main.async {
                let loadedPage = self.viewModel.loadedPage
                
                self.viewModel.fetchImageMetaData(page: loadedPage + 1)
                self.viewModel.loadedPage += 1
            }
        }
    }
}
