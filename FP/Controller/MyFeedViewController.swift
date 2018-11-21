//
//  MyFeedViewController.swift
//  FP
//
//  Created by Allan Zhang on 16/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseDatabase

class MyFeedViewController: UIViewController {

    @IBOutlet weak var feedCollectionView: UICollectionView!
    
    var feedArray = [[String : Any]]()
    var refHandleForFeedAdded: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        feedArray.removeAll()
        feedCollectionView.reloadData()
        addObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeObserver()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func addObserver() {
        if let userId = FPDataModel.userId {
            //.queryOrderedByValue().queryEqual(toValue: userId)
            refHandleForFeedAdded = ref.child(kChild).child(kRegistration).child(userId).child(kFeeds).queryOrderedByValue().queryEqual(toValue: userId).observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    self.getFeedInfo(of: snapshot.key, creator: snapshot.value as! String)
                }
            })
        }
    }
    
    private func removeObserver() {
        if let userId = FPDataModel.userId {
            ref.child(kChild).child(kRegistration).child(userId).child(kFeeds).removeObserver(withHandle: refHandleForFeedAdded!)
            ref.removeAllObservers()
        }
    }
    
    fileprivate func getFeedInfo(of feedId: String, creator: String) {
        ref.child(kChild).child(kFeeds).child(feedId).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                var feedInfoDict = [String : Any]()
                feedInfoDict["feedInfo"] = snapshot.value as! [String : Any]
                if let userInfo = FPDataModel.userInfo {
                    feedInfoDict[kUserInfo] = userInfo
                }
                if let index = self.feedArray.index(where: { (feedDict) -> Bool in
                    return ((feedDict["feedInfo"] as! [String : Any])[kcFeedId] as! String == feedId)
                }) {
                    self.feedArray[index] = feedInfoDict
                }else {
                    self.feedArray.append(feedInfoDict)
                }
                
                if self.feedArray.count > 0 {
                    let sortedArray = FPSingleton.sharedInstance.getSortedFeeds(self.feedArray)
                    self.feedArray.removeAll()
                    self.feedArray.append(contentsOf: sortedArray)
                    DispatchQueue.main.async {
                        self.feedCollectionView.reloadData()
                    }
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MyFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK: - CollectionView FlowLayout Delegate
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: ((collectionView.bounds.size.width/2) - 4), height: ((collectionView.bounds.size.width/2) - 4))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 4.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return 4.0
    }
    
    //MARK: - CollectionView Delegate & DataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return feedArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "feedCell", for: indexPath) as UICollectionViewCell
        
        let cellImageView = cell.contentView.viewWithTag(1)! as! UIImageView
        let feedUrlString = (feedArray[indexPath.row]["feedInfo"] as! [String : Any])[kcFeedImageUrl] as! String
        cellImageView.layer.cornerRadius = 4.0
        cellImageView.clipsToBounds = true
        cellImageView.sd_setImage(with: URL(string: feedUrlString), placeholderImage: #imageLiteral(resourceName: "round-help-button"), options: .highPriority) { (image, error, cacheType, url) in
            
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        moveToFeedScreen(at: indexPath.row)
    }
    
    fileprivate func moveToFeedScreen(at index: Int) {
        var feedViewController = self.storyboard?.instantiateViewController(withIdentifier: "FeedViewController") as? FeedViewController
        feedViewController!.isViewingSelfFeed = true
        feedViewController!.feedArray = [feedArray[index]]
        feedViewController?.friendId = nil
        self.navigationController?.pushViewController(feedViewController!, animated: true)
        feedViewController = nil
    }
}
