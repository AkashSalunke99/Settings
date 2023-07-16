import Foundation
import UIKit

struct Section: Hashable {
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: Section, rhs: Section) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

struct Item: Hashable {
    let identifier = UUID()
    var model: Model
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func contains(_ searchString: String?) -> Bool {
        guard let search = searchString else { return true }
        if search.isEmpty { return true }
        let lowercasedSearch = search.lowercased()
        return model.title.lowercased().contains(lowercasedSearch)
    }
}

struct Model {
    var title: String
    var image: UIImage?
}
