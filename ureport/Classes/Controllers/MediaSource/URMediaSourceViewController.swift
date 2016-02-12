//
//  URMediaSourceViewController.swift
//  ureport
//
//  Created by Daniel Amaral on 21/01/16.
//  Copyright © 2016 ilhasoft. All rights reserved.
//

import UIKit
import SDWebImage
import MobileCoreServices

protocol URMediaSourceViewControllerDelegate {
    func newMediaAdded(mediaSourceViewController:URMediaSourceViewController, media:URMedia)
}

class URMediaSourceViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var btCamera: ISCircleButton!
    @IBOutlet weak var btGallery: ISCircleButton!
    @IBOutlet weak var btVideo: ISCircleButton!
    @IBOutlet weak var btFile: ISCircleButton!
    @IBOutlet weak var btAudio: ISCircleButton!
    @IBOutlet weak var btYoutube: ISCircleButton!
    
    @IBOutlet weak var btDismiss: UIButton!
    
    @IBOutlet weak var lbCamera: UILabel!
    @IBOutlet weak var lbGallery: UILabel!
    @IBOutlet weak var lbVideo: UILabel!
    @IBOutlet weak var lbFile: UILabel!
    @IBOutlet weak var lbAudio: UILabel!
    @IBOutlet weak var lbYoutube: UILabel!
    
    var media:URMedia!
    var image:UIImage!
    
    var isVisible:Bool!
    
    var delegate:URMediaSourceViewControllerDelegate?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: "URMediaSourceViewController", bundle: nil)
        isVisible = false
        
        let frame = CGRect(x: 0, y: UIScreen.mainScreen().bounds.size.height, width: UIScreen.mainScreen().bounds.size.width, height: self.view.frame.size.height)
        self.view.frame = frame
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    //MARK: Class Methods
    
    func toggleView() {

        if !isVisible {
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                let frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.height)
                self.view.frame = frame
                }) { (finish) -> Void in
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        self.btDismiss.layer.opacity = 0.3
                    })
            }
            isVisible = true
        }else{

            UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.btDismiss.layer.opacity = 0
                }) { (finish) -> Void in
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        let frame = CGRect(x: 0, y: UIScreen.mainScreen().bounds.size.height, width: UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.height)
                        self.view.frame = frame
                    })
            }
            isVisible = false
        }
        
    }
    
    
    //MARK: ImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if let delegate = delegate {
        
            if mediaType == kUTTypeMovie {
                let mediaURL = (info[UIImagePickerControllerMediaURL] as! NSURL)
                let path = mediaURL.path
                
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path!) {}
                
                let media = URVideoPhoneMedia()
                media.path = path
                media.thumbnailImage = URVideoUtil.generateThumbnail(mediaURL)
                
                delegate.newMediaAdded(self, media: media)
                
            }else {
                
                if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    
                    let media = URImageMedia()
                    media.image = pickedImage
                    
                    delegate.newMediaAdded(self, media: media)
                }
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: Button Events
    
    @IBAction func btDismissTapped(sender: AnyObject) {
        self.toggleView()
    }
    
    @IBAction func btMediaSourceTapped(sender: AnyObject) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        switch sender as! ISCircleButton {
         
        case btCamera:
            
            imagePicker.sourceType = .Camera
            imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.Photo
            imagePicker.showsCameraControls = true
            imagePicker.allowsEditing = true
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
            break
            
        case btGallery:
            
            imagePicker.allowsEditing = false;
            imagePicker.sourceType = .PhotoLibrary
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
            break
            
        case btVideo:
            imagePicker.sourceType = .Camera
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.videoQuality = .Type640x480
            imagePicker.videoMaximumDuration = 20
            
            imagePicker.allowsEditing = false
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
            break
            
        case btFile:
            break
            
        case btAudio:
            break
            
        case btYoutube:
            
            let alertControllerTextField = UIAlertController(title: nil, message: "message_youtube_link".localized, preferredStyle: UIAlertControllerStyle.Alert)
            
            alertControllerTextField.addTextFieldWithConfigurationHandler(nil)
            alertControllerTextField.addAction(UIAlertAction(title: "cancel_dialog_button".localized, style: .Cancel, handler: nil))
            alertControllerTextField.addAction(UIAlertAction(title: "sign_up_confirm".localized, style: .Default, handler: { (alertAction) -> Void in
                
                let urlVideo = alertControllerTextField.textFields![0].text!
                
                if urlVideo.isEmpty {
                    UIAlertView(title: nil, message: "error_empty_link".localized, delegate: self, cancelButtonTitle: "OK").show()
                    return
                }
                
                let media = URVideoMedia()
                media.id = URYoutubeUtil.getYoutubeVideoID(urlVideo)
                media.url = URConstant.Youtube.COVERIMAGE.stringByReplacingOccurrencesOfString("%@", withString: media.id)
                
                if let delegate = self.delegate {
                    delegate.newMediaAdded(self, media: media)
                }
                
            }))
            
            self.presentViewController(alertControllerTextField, animated: true, completion: nil)
            
            break
            
        default:
            break
            
        }
        
    }
    
}
