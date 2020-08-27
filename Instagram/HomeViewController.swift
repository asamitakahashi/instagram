//
//  HomeViewController.swift
//  Instagram
//
//  Created by user on 2020/08/11.
//  Copyright © 2020 asamin.t. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    
    // 投稿データを格納する配列
    var postArray: [PostData] = []

    // Firestoreのリスナー
    var listener: ListenerRegistration!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        // カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")

        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.map { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let postData = PostData(document: document)
                        return postData
                    }
                    // TableViewの表示を更新する
                    self.tableView.reloadData()
                }
            }
        } else {
            // ログイン未(またはログアウト済み)
            if listener != nil {
                // listener登録済みなら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                tableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])

        // セル内のボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
        
        // セル内のボタンのアクションをソースコードで設定する2
        cell.comentButton.addTarget(self, action:#selector(handleButton2(_:forEvent:)), for: .touchUpInside)
        
        return cell
    }

    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")

        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)

        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]

        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
       
            }
    }
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton2(_ sender: UIButton, forEvent event: UIEvent) {
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)

        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        var alertTextField: UITextField?
       
        //アラートを構成するボタンやテキストボックスを入れる入れ物を構築します
        let alert = UIAlertController(
            title: "コメント",
            message: "入力してください",
            preferredStyle: UIAlertController.Style.alert)
        alert.addTextField(
            configurationHandler: {(textField: UITextField!) in
                alertTextField = textField
                if let comments = alertTextField?.text {
                textField.text = comments
                }
        
    })
    //部品をUIAlertControllerに追加
    alert.addAction(
    UIAlertAction(
    //Cancelボタン
    title: "Cancel",
    style: UIAlertAction.Style.cancel,
    handler: nil))
    alert.addAction(
    //OKボタン
    UIAlertAction(
    title: "OK",
    style: UIAlertAction.Style.default) { _ in
    //以下はボタンがクリックされた時の処理
        if (alertTextField?.text) != nil {
    // commentsを更新する
    if let comments = alertTextField?.text {
            // 更新データを作成する
                let updateValue: FieldValue
    //commentsを追加する更新データを作成
            updateValue = FieldValue.arrayUnion([comments])
    print(FieldValue.arrayUnion([comments]))
    //更新データを書き込む
    let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
    postRef.updateData(["comments": updateValue])
    }
        }
        }
)
self.present(alert, animated: true, completion: nil)
    }
}
/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */
