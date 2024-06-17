//
//  RecordingListVC.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class RecordingListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLbl: UILabel!
    @IBOutlet weak var recordingView: UIView!
    
    
    
    let viewModel = RecordingListViewModel()
    var rightButtonItem : UIBarButtonItem!
    var isEditingTable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Recorded List"
        viewModel.loadPreviousRecording()
        tableView?.reloadData()
        
        addNavRightBtn()
        
        makeRecodingCardView()
        
    }
    
    func addNavRightBtn()  {
        rightButtonItem = UIBarButtonItem.init(
              title: "Edit",
              style: .done,
              target: self,
              action: #selector(rightButtonAction(sender:))
        )

        self.navigationItem.rightBarButtonItem = rightButtonItem
    }
    
    @objc func rightButtonAction(sender: UIBarButtonItem) {
        isEditingTable.toggle()
        rightButtonItem.title = isEditingTable ? "Done" : "Edit"
        tableView.setEditing(isEditingTable, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView?.reloadData()
        
        updateView()
    }
    
    func updateView() {
        
        tableView?.isHidden = viewModel.recordingList.count > 0 ? false : true
        emptyLbl?.isHidden = !(tableView?.isHidden ?? true)
        
    }
    
    @IBAction func startNewrecordingBtnAction(_ sender: Any) {
        
        getFileNameFromUser()
    }
    
    func getFileNameFromUser()  {
        //Create the alert controller for file name.
        let alert = UIAlertController(title: "New Recording Title", message: nil, preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.placeholder = "Enter title"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if let fileName = textField?.text {
                self.openNewRecording(fileName: fileName)
            }
        }))
        
       

        self.present(alert, animated: true, completion: nil)
    }
    
    func openNewRecording(fileName : String)  {
        // Setup new recording
        let model = ReordingModel(title: fileName)
        self.viewModel.recordingList.append(model)
        let storyboard: UIStoryboard = UIStoryboard(name: "NewRecordingSB", bundle: nil)
        if let recordingVC : NewRecordingVC = storyboard.instantiateInitialViewController() {
            let viewModel = NewRecordingViewModel(recordingObj: model)
            recordingVC.setViewModel(viewModel: viewModel)
            self.navigationController?.pushViewController(recordingVC, animated: true)
        }
        
    }


}

extension RecordingListVC : UITableViewDelegate , UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return viewModel.recordingList.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let recoding = self.viewModel.recordingList[indexPath.row]
        let cell : RecordingTableCell = tableView.dequeueReusableCell(withIdentifier: "RecordingTableCellIdentifier", for: indexPath) as! RecordingTableCell
        cell.setData(recoding: recoding)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt")
        let storyboard: UIStoryboard = UIStoryboard(name: "RecordingPlayerSB", bundle: nil)
        if let recordingVC : RecodingPlayerVC = storyboard.instantiateInitialViewController() {
            let recoding = self.viewModel.recordingList[indexPath.row]
            let playerViewModel = RecordingPlayerViewModel(recordingObj: recoding)
            recordingVC.setViewModel(viewModel: playerViewModel)
            self.navigationController?.pushViewController(recordingVC, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
       
        return isEditingTable
        
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            presentDeletionAlert(index: indexPath)
        }
    }


    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // add the action button you want to show when swiping on tableView's cell , in this case add the delete button.
          let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action , indexPath) -> Void in
              self.presentDeletionAlert(index: indexPath)
        })


        deleteAction.backgroundColor = UIColor.red

        return [deleteAction]
    }



    func presentDeletionAlert(index: IndexPath) {
        let alert = UIAlertController(title: nil, message: "Are you sure you'd like to Delete?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (action) in
            
            let recoding = self.viewModel.recordingList[index.row]
            
            let fileURL = FileManagerHelper.getFileURL(for: recoding.title)
            FileManagerHelper.removeFile(from: fileURL)
            self.viewModel.recordingList.remove(at: index.row)
            self.tableView.reloadData()
            self.updateView()
        }))
        alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { (action) in
            print("")
            
        }))

        present(alert, animated: true, completion: nil)
    }
    
    func makeRecodingCardView()  {
        recordingView.backgroundColor = .white
        recordingView.layer.cornerRadius = 10.0
        recordingView.layer.shadowColor = UIColor.gray.cgColor
        recordingView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        recordingView.layer.shadowRadius = 6.0
        recordingView.layer.shadowOpacity = 0.7
    }
}

