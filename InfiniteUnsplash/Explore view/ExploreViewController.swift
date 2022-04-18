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
    
    // DiffableDataSource에서 사용하는 섹션 enum
    enum Section: Int, CaseIterable {
        case main
    }
    
    // 에러 표시용 Alert
    lazy var alert: UIAlertController = {
        let alert =  UIAlertController(title: "Error!", message: "데이터를 불러오는 데 실패했습니다. 잠시 후 다시 시도해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

        return alert
    }()
    
    // 드래그 리프레시 컨트롤러
    lazy var refreshControll: UIRefreshControl = {
        let refreshControll = UIRefreshControl()
        refreshControll.tintColor = .white
        refreshControll.addTarget(self, action: #selector(refresh(_:)), for: .allEvents)
        
        return refreshControll
    }()
    
    // 콜렉션 뷰 설정
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
        
        // 바 무조건 보이게
        self.navigationController?.setNavigationBarHidden(false, animated: false)

        // 네비게이션 바 타이틀 바꾸기
        self.navigationController?.navigationBar.topItem?.title = "Unsplash"
        
        // 네비게이션 바 배경 투명하게
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        // 네비게이션 바 타이틀 색 바꾸기
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    @objc func refresh(_ sender: Any) {
        viewModel.fetchImageMetaData(page: 1)
    }

    // MARK: UI 레이아웃
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
    
    // MARK: 데이터 소스 설정
    func setupDataSource() {
        self.dataSource =
        UICollectionViewDiffableDataSource<Section, ImageMetaData>(collectionView: self.collectionView) {
            (collectionView, indexPath, source) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as? ImageCell
            else { preconditionFailure() }
    
            cell.setUp(viewModel: ImageCellViewModel(source: source))
            return cell
        }
        
        // 뷰모델 이미지 관련 데이터 & 데이터 소스 바인딩
        self.viewModel.imageMetaData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedData in
                guard let self = self else { return }
                // 빈 스냅샷에
                var snapshot = NSDiffableDataSourceSnapshot<Section, ImageMetaData>()
                // 섹션 추가(안 하면 에러 발생)
                snapshot.appendSections([.main])
                // 업데이트 된 데이터 어펜드
                snapshot.appendItems(updatedData)
                // 스냅샷 이용해 데이터소스 업데이트
                self.dataSource?.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &subscriptions)
        
        // 네트워크 요청 진행 상황따라 뷰 처리
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
        
        // 무한스크롤을 위한 데이터 로딩
        let dataSources = self.viewModel.imageMetaData.value
        let source = dataSources[row]
        
        // 이미지를 프리캐싱함. 스펙에 따라 한 번에 캐시할 이미지 개수는 조정 필요(현재 바로 다음 1개 셀만 캐싱)
        self.viewModel.preCaching(source: source)
        
        // 끝에서 3번째 셀에서 추가 이미지 메타 데이터 로딩
        if row == dataSources.count - 3 {
            DispatchQueue.main.async {
                let loadedPage = self.viewModel.loadedPage
                
                self.viewModel.fetchImageMetaData(page: loadedPage + 1)
                self.viewModel.loadedPage += 1
            }
        }
    }
}
