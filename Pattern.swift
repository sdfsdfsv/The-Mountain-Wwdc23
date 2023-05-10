import SwiftUI

//some parameters to adjust the view randomly
class Pattern: Codable,Equatable{
    
    var id=UUID()
    var imageX:Int=100
    var imageY:Int=100
    var texture:String="texture"
    var lightness:Float=0.75
    var height:Float=0.2
    var xLocation:Float=0
    var renderCnt:Float=1
    
    var saveTime:Float
    static func ==(lhs: Pattern,rhs:Pattern)->Bool{
        return lhs.id==rhs.id
    }
    init(){

        let scale=Int(arc4random_uniform(UInt32(200)))
        imageX=100-Int(arc4random_uniform(UInt32(200)))+scale*3+600
        imageY=100-Int(arc4random_uniform(UInt32(200)))+scale*4+800
        
        texture=StaticTextures.textureDict.keys.randomElement()!
        
        lightness = Float(arc4random_uniform(UInt32(1000)))/8000+0.76
        
        height = Float(arc4random_uniform(UInt32(1000)))/3600+0.25
        
        xLocation=Float(arc4random_uniform(UInt32(10000)))
        renderCnt=Float(arc4random_uniform(UInt32(1000)))/8100+0.9
        
        saveTime=0
        
    }
    // Encode the pattern to Data for storage
    func encode() -> Data? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            return data
        } catch {
            print("Error encoding pattern: \(error)")
            return nil
        }
    }
    
    // Decode a pattern from Data
    class func decode(data: Data) -> Pattern? {
        let decoder = JSONDecoder()
        do {
            let pattern = try decoder.decode(self, from: data)
            return pattern
        } catch {
            print("Error decoding pattern: \(error)")
            return nil
        }
    }
}




class PatternStorage {
    static let shared = PatternStorage()
    private let userDefaults = UserDefaults.standard
    
    func storePattern(_ pattern: Pattern) {
        var patterns = loadPatterns()
        patterns.append( pattern)
        save(patterns: patterns)
    }
    
    func loadPattern(atIndex index: Int) -> Pattern? {
        let patterns = loadPatterns()
        return patterns[index]
    }
    func getCnt()->Int{
        return loadPatterns().count
    }
    
    func loadPatterns() -> [Pattern] {
        guard let data = userDefaults.data(forKey: "patterns") else {
            return []
        }
        return try! JSONDecoder().decode([Pattern].self, from: data)
    }
    
    func save(patterns: [Pattern]) {
        
         patterns.map { if $0.saveTime==0{ $0.saveTime=Float(CACurrentMediaTime())}  }
        
        let data = try! JSONEncoder().encode(patterns)
        userDefaults.set(data, forKey: "patterns")
    }
    func clear(){
        userDefaults.removeObject(forKey: "patterns")
    }
}
