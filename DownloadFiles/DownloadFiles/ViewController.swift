//
//  ViewController.swift
//  DownloadFiles
//
//  Created by Kyle Wilson on 2020-04-07.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var dogImageView: UIImageView!
    
    var imageURLForDownload: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //MARK: Random Image Response
    
    func handleRandomImageResponse(imageData: DogImage?) {
        guard let imageURL = URL(string: imageData?.message ?? "") else {
            return
        }
        DogAPI.requestImageFile(url: imageURL, completionHandler: handleImageFileResponse(image:error:))
        imageURLForDownload = imageURL
    }
    
    //MARK: Handle Image File Response
    func handleImageFileResponse(image: UIImage?, error: Error?) {
        DispatchQueue.main.async { //put on main thread
            self.dogImageView.image = image //add image
        }
    }
    
    //MARK: Button Tapped
    
    @IBAction func randomDogTapped(_ sender: Any) {
        
        DogAPI.requestRandomImage { (imageData, success, error)  in
            
            if error != nil {
                DispatchQueue.main.async { //put on main thread
                    let alert = UIAlertController(title: "Error", message: "There was an error: \(error?.localizedDescription ?? "")", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true) //present alerts
                }
                return
            }
            
            guard imageData != nil else {
                DispatchQueue.main.async { //put on main thread
                    let alert = UIAlertController(title: "No Image", message: "Could not load image", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
                return
            }
            
            if success { //if it succeeds getting the request
                self.handleRandomImageResponse(imageData: imageData)
            }
        }
    }
    
    //MARK: DOWNLOAD IMAGE
    
    func downloadImage(imageURL: URL) {
        let url = imageURL
        let fileName = String((url.lastPathComponent)) as NSString
        let documentsURL: URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        let destinationFileURL = documentsURL.appendingPathComponent("\(fileName)")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileURL)
                    do {
                        let contents  = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        for indexx in 0..<contents.count {
                            if contents[indexx].lastPathComponent == destinationFileURL.lastPathComponent {
                                let activityViewController = UIActivityViewController(activityItems: [contents[indexx]], applicationActivities: nil)
                                DispatchQueue.main.async {
                                    self.present(activityViewController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                    catch (let err) {
                        print("error: \(err)")
                    }
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileURL) : \(writeError)")
                }
            } else {
                print("Error took place while downloading a file. Error description: \(error?.localizedDescription ?? "")")
            }
        }
        task.resume()
    }
    
    @IBAction func downloadImageTapped(_ sender: Any) {
        guard let imageURLDownload = imageURLForDownload else {
            return
        }
        DispatchQueue.main.async {
            self.downloadImage(imageURL: imageURLDownload)
        }
    }


}

