//
//  MapsViewController.swift
//  MapKitApp
//
//  Created by selinay ceylan on 15.03.2024.
//

import UIKit
import MapKit
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var saveClicked: UIButton!
    @IBOutlet weak var countryField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    var chosenLatitude = Double()
    var chosenLongtitude = Double()
    
    var selectedName = ""
    var selectedID : UUID?
    var selectedCountry = ""
    var selectedImage : UIImage?
    
    var annotationTitle = ""
    var annotationCountry = ""
    var annotationLongtitude = Double()
    var annotationLatitude = Double()
    var annotationImage : UIImage?
    
    
    let search = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        search.searchBar.delegate = self
        navigationItem.searchController = search
        
        if selectedName != "" {
            saveClicked.isHidden = true
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedID!.uuidString
            fetchRequest.predicate = NSPredicate(format:"id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "name") as? String{
                            annotationTitle = title
                            if let country = result.value(forKey: "country") as? String{
                                annotationCountry = country
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longtitude = result.value(forKey: "longtitude") as? Double{
                                        annotationLongtitude = longtitude
                                        if let imageData = result.value(forKey: "image") as? Data {
                                            let image = UIImage(data: imageData)
                                            imageView.image = image
                                        
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.title = annotationCountry
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongtitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameField.text = annotationTitle
                                        countryField.text = annotationCountry
                                        

                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print(error)
            }
            
        } else {
            saveClicked.isHidden = false
            saveClicked.isEnabled = false
            
            nameField.text = ""
            countryField.text = ""
        }
        
        imageView.isUserInteractionEnabled = true
        let imageTopRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(imageTopRecognizer)
        
            
    }
    

    
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameField.text, forKey: "name")
        newPlace.setValue(countryField.text, forKey: "country")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongtitude, forKey: "longtitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        let data = imageView.image?.jpegData(compressionQuality: 0.5)
        newPlace.setValue(data, forKey: "image")
        
        do{
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        let text = search.searchBar.text ?? "Ankara"
        
        search(text: text)
        
    }
    
    func search(text : String) {
        let indicator = UIActivityIndicatorView()
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.center = self.view.center
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        
        self.view.addSubview(indicator)
        
        let searchRequest = MKLocalSearch.Request()
                searchRequest.naturalLanguageQuery = text
                
                let activeSearch = MKLocalSearch(request: searchRequest)
                
                activeSearch.start{ (response, error) in
                    
                    indicator.stopAnimating()
                    
                    if (response == nil) {
                        print("error")
                    }else {
                        
                        let annotations = self.mapView.annotations
                        self.mapView.removeAnnotations(annotations)
                        
                        let lat = response?.boundingRegion.center.latitude
                        let long = response?.boundingRegion.center.longitude
                        
              
                        let cordinate = CLLocationCoordinate2DMake(lat!, long!)
                        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        let region = MKCoordinateRegion(center: cordinate, span: span)
                        self.mapView.setRegion(region, animated: true)
                        
                        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.clickPlace(gestureRecognizer:)))
                        gestureRecognizer.minimumPressDuration = 2
                        self.mapView.addGestureRecognizer(gestureRecognizer)
                        
                    }
                    
                    
                }
                
            }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    @objc func clickPlace(gestureRecognizer : UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
           
            chosenLatitude = touchedCoordinates.latitude
            chosenLongtitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameField.text
            annotation.subtitle = countryField.text
            self.mapView.addAnnotation(annotation)
            
            
        }
    }
    
    @objc func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        saveClicked.isEnabled = true
        self.dismiss(animated: true, completion: nil)
    }

    
}
