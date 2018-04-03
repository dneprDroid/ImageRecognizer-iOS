//
//  UtilMethods.swift
//  ImageRecognizer
//
//  Created by user on 12/26/16.
//  Copyright © 2016 alex.o. All rights reserved.
//

import Foundation
import UIKit


//debug
func saveImageToGallery(image: UIImage) {
    DispatchQueue.global().async {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}
