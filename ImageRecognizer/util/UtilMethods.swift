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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),{
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    })
}
