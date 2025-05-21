import Foundation

extension Array where Element == [Int:Int] {
    func sortedByKey() -> [[Int: Int]] {
        return self.sorted { dict1, dict2 in
            guard let key1 = dict1.keys.first,
                  let key2 = dict2.keys.first else {
                return false
            }
            return key1 < key2
        }
    }
}
