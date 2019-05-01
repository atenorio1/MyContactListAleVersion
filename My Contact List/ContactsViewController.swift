//
//  ContactsViewController.swift
//  My Contact List
//
//  Created by Alejandro Tenorio on 4/7/19.
//  Copyright © 2019 Learning Mobile Apps. All rights reserved.
//

import UIKit
import CoreData

class ContactsViewController: UIViewController, UITextFieldDelegate, DateControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var currentContact: Contact?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sgmtEditMode: UISegmentedControl!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var txtState: UITextField!
    @IBOutlet weak var txtZip: UITextField!
    @IBOutlet weak var txtCell: UITextField!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var lblBirthdate: UILabel!
    @IBOutlet weak var btnChange: UIButton!
    @IBOutlet weak var imgContactPicture: UIImageView!
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var txtPriority: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if currentContact != nil {
            txtName.text = currentContact!.title
            txtPriority.text = currentContact!.priority
            
         
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let currentDate = df.string(from:currentContact!.dateCreated! as Date)
            if currentDate != nil{
                lblBirthdate.text = currentDate
            } else {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                lblBirthdate.text = df.string(from:Date())
            }
        }
        
        changeEditMode(self)
        
        let textFields: [UITextField] = [txtName, txtPriority]
        
        for textField in textFields {
            textField.addTarget(self, action: #selector(UITextFieldDelegate.textFieldShouldEndEditing(_:)), for: UIControlEvents.editingDidEnd)
        }
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
      
        currentContact?.title = txtName.text
        currentContact?.priority = txtPriority.text
        currentContact?.dateCreated = Date() as NSDate
        
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeEditMode(_ sender: Any) {
        let textFields: [UITextField] = [txtName, txtPriority]
        
        if sgmtEditMode.selectedSegmentIndex == 0 {
            for textField in textFields {
                textField.isEnabled = false
                textField.borderStyle = UITextBorderStyle.roundedRect
            }
            navigationItem.rightBarButtonItem = nil
        }
        
        else if sgmtEditMode.selectedSegmentIndex == 1 {
            for textField in textFields {
                textField.isEnabled = true
                textField.borderStyle = UITextBorderStyle.roundedRect
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveContact))
        }
    }
    
    func saveContact() {
        
        if currentContact == nil {
            currentContact?.dateCreated = Date() as NSDate
            let context = appDelegate.persistentContainer.viewContext
            currentContact = Contact(context: context)
        }
        
        appDelegate.saveContext()
        sgmtEditMode.selectedSegmentIndex = 0
        changeEditMode(self)
    }
    
    func dateChanged(date: Date) {
        if currentContact != nil {
            currentContact?.dateCreated = date as NSDate?
            appDelegate.saveContext()
            let formatter  = DateFormatter()
            formatter.dateStyle = .short
            self.lblBirthdate.text = formatter.string(from: date)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueContactDate") {
            let dateController = segue.destination as! DateViewController
            dateController.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterKeyboardNotifications()
    }
    
    @IBAction func changePicture(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraController = UIImagePickerController()
            cameraController.sourceType = .camera
            cameraController.cameraCaptureMode = .photo
            cameraController.delegate = self
            cameraController.allowsEditing = true
            self.present(cameraController, animated: true, completion: nil)
            print("ChangePicture function ran but does not do anything because of simulator limitations!")
        }
        else {
            print("ChangePicture function did not run because of simulator limitations!")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imgContactPicture.contentMode = .scaleAspectFit
            imgContactPicture.image = image
            
            if currentContact == nil {
                let context = appDelegate.persistentContainer.viewContext
                currentContact = Contact(context: context)
            }
            currentContact?.image = NSData(data: UIImageJPEGRepresentation(image, 1.0)!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func callPhone(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let number = txtPhone.text
            if number!.characters.count > 0 { //Don't call blank numbers
                let url = NSURL(string: "telprompt://\(number!)")
                UIApplication.shared.open(url as! URL, options: [:], completionHandler: nil)
                print("Calling Phone Number: \(url!)")
            }
        }
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ContactsViewController.keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContactsViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        
        // Get the existing contentInset for the scrollView and set th bottom property to be the height of the keybaord
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = keyboardSize.height
        
        self.scrollView.contentInset = contentInset
        self.scrollView.scrollIndicatorInsets = contentInset
    }
    
    func keyboardWillHide(notification: NSNotification) {
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = 0
        
        self.scrollView.contentInset = contentInset
        self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
}
