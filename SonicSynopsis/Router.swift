//
//  Router.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 4/18/24.
//

import Foundation

class Router: ObservableObject {
    static let shared  = Router()
    
    @Published var selectedTab = 0
    
}
