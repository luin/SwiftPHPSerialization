import Foundation

private extension String {
  var unescapingUnicodeCharacters: String {
    let mutableString = NSMutableString(string: self)
    CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)
    
    return mutableString as String
  }
}

enum SwiftPHPSerializationError: Error, Equatable {
  case expected(_ chars: [String])
  case objectUnsupported
  case unsupportedType(_ type: String)
  case unterminatedString
  case unterminatedUnicodeEncode
  case unmatchedLength
  case syntaxError
}

private let NUMBER_CHARS = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "e", "E", ".", "+"]

private func consumeWhitespaces(_ iter: ArrayIterator<String.Element>) {
  while iter.hasNext {
    if iter.peekNext()?.isWhitespace ?? false {
      iter.next()
    } else {
      break
    }
  }
}

private func consumeString(_ iter: ArrayIterator<String.Element>) throws -> String {
  var string = "\""
  var escaping = false
  while true {
    if let char = iter.next() {
      if char.isNewline {
        throw SwiftPHPSerializationError.unterminatedString
      }
      
      if escaping {
        switch char {
        case "n": string.append("\n")
        case "r": string.append("\r")
        case "t": string.append("\t")
        case "\\": string.append("\\")
        case "u":
          if let char1 = iter.next(), let char2 = iter.next(), let char3 = iter.next(), let char4 = iter.next() {
            string.append("\\u\(char1)\(char2)\(char3)\(char4)".unescapingUnicodeCharacters)
          } else {
            throw SwiftPHPSerializationError.unterminatedUnicodeEncode
          }
        default: string.append(char)
        }
        escaping = false
      } else {
        if char == "\\" {
          escaping = true
        } else {
          string.append(char)
          if char == "\"" {
            return string
          }
        }
      }
    } else {
      break
    }
  }
  
  throw SwiftPHPSerializationError.unterminatedString
}

public struct SwiftPHPSerialization {
  public private(set) var text = "Hello, World!"
  
  private static func performSerialize(iter: ArrayIterator<String.Element>, preferInt: Bool = false, rootLevel: Bool) throws -> String {
    consumeWhitespaces(iter)
    
    func expectEOL() throws {
      if !rootLevel {
        return
      }
      consumeWhitespaces(iter)
      if iter.hasNext {
        throw SwiftPHPSerializationError.syntaxError
      }
    }
    
    let peeked = iter.peekNext()
    if peeked == "\"" {
      iter.next()
      let string = try consumeString(iter)
      if preferInt {
        let dropped = String(string.dropFirst().dropLast())
        let characterset = CharacterSet(charactersIn: "0123456789")
        
        if dropped.rangeOfCharacter(from: characterset.inverted) == nil {
          return "i:\(dropped);"
        }
      }
      return "s:\(string.utf8.count - 2):\(string);"
    }
    
    if peeked == "t" {
      iter.next()
      if iter.next() == "r" && iter.next() == "u" && iter.next() == "e" {
        try expectEOL()
        return "b:1;"
      }
      throw SwiftPHPSerializationError.syntaxError
    }
    if peeked == "f" {
      iter.next()
      if iter.next() == "a" && iter.next() == "l" && iter.next() == "s" && iter.next() == "e" {
        try expectEOL()
        return "b:0;"
      }
      throw SwiftPHPSerializationError.syntaxError
    }
    if peeked == "n" {
      iter.next()
      if iter.next() == "u" && iter.next() == "l" && iter.next() == "l" {
        try expectEOL()
        return "N;"
      }
      throw SwiftPHPSerializationError.syntaxError
    }
    if peeked == "[" {
      iter.next()
      var items: [String] = []
      while true {
        consumeWhitespaces(iter)
        if !iter.hasNext || iter.peekNext() == "]" {
          iter.next()
          try expectEOL()
          return "a:\(items.count / 2):{\(items.joined(separator: ""))}"
        } else {
          if iter.peekNext() == "," {
            iter.next()
          }
          items.append("i:\(items.count / 2);")
          items.append(try performSerialize(iter: iter, preferInt: false, rootLevel: false))
        }
      }
    }
    
    if peeked == "{" {
      iter.next()
      var items: [String] = []
      var preferInt = true
      while true {
        consumeWhitespaces(iter)
        if !iter.hasNext || iter.peekNext() == "}" {
          iter.next()
          try expectEOL()
          return "a:\(items.count / 2):{\(items.joined(separator: ""))}"
        } else {
          if iter.peekNext() == "," {
            iter.next()
          }
          if iter.peekNext() == ":" {
            iter.next()
          }
          items.append(try performSerialize(iter: iter, preferInt: preferInt, rootLevel: false))
          preferInt = !preferInt
        }
      }
    }
    
    if let char = peeked, NUMBER_CHARS.contains(String(char)) {
      var numberString = ""
      while let nextChar = iter.next() {
        numberString += String(nextChar)
        if let nextPeekedChar = iter.peekNext() {
          if !NUMBER_CHARS.contains(String(nextPeekedChar)) {
            break
          }
        } else {
          break
        }
      }
      let scientific = numberString.contains("e") || numberString.contains("E")
      let flag = scientific || numberString.contains(".") ? "d" : "i"
      if !["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].contains(numberString.last) {
        throw SwiftPHPSerializationError.syntaxError
      }
      return "\(flag):\(numberString);"
    }
    
    if !iter.hasNext {
      return "s:0:\"\""
    }
    
    throw SwiftPHPSerializationError.syntaxError
  }
  
  public static func serialize(_ json: String) throws -> String {
    return try performSerialize(iter: ArrayIterator(Array(json)), preferInt: false, rootLevel: true)
  }
  
  private static func performUnserialize(iter: ArrayIterator<String.Element>, rootLevel: Bool) throws -> String {
    @discardableResult
    func expectNext(_ expected: [String]) throws -> String {
      let next = iter.next()
      guard let next = next else {
        throw SwiftPHPSerializationError.expected(expected)
      }
      if !expected.contains(String(next)) {
        throw SwiftPHPSerializationError.expected(expected)
      }
      return String(next)
    }

    func expectEOL() throws {
      if !rootLevel {
        return
      }
      consumeWhitespaces(iter)
      if iter.hasNext {
        throw SwiftPHPSerializationError.syntaxError
      }
    }

    func expectLength() throws -> Int {
      var lengthString = ""
      while true {
        let next = try expectNext(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":"])
        if next == ":" {
          return Int(lengthString) ?? 0
        }
        
        lengthString = lengthString + next
      }
    }
    
    if let type = iter.next() {
      switch type {
      case "N":
        try expectNext([";"])
        try expectEOL()
        return "null"
      case "b":
        try expectNext([":"])
        
        switch iter.next() {
        case "1":
          try expectNext([";"])
          try expectEOL()
          return "true"
        case "0":
          try expectNext([";"])
          try expectEOL()
          return "false"
        default:
          throw SwiftPHPSerializationError.expected(["1", "0"])
        }
      case "i", "d":
        try expectNext([":"])
        
        var result = ""
        while true {
          let next = try expectNext(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ";", "."])
          if next == ";" {
            try expectEOL()
            return result
          }
          result = result + next
        }
      case "s":
        try expectNext([":"])
        var length = try expectLength()
        try expectNext(["\""])
        var result = "\""
        
        if length < 0 {
          throw SwiftPHPSerializationError.unmatchedLength
        }
        
        if length == 0 {
          try expectNext(["\""])
          try expectNext([";"])
          try expectEOL()
          return "\"\""
        }
        
        while true {
          guard let nextChar = iter.next() else {
            throw SwiftPHPSerializationError.expected(["String"])
          }
          var escapedChar = String(nextChar)
          if nextChar == "\n" {
            escapedChar = "\\n"
          } else if nextChar == "\r" {
            escapedChar = #"\r"#
          } else if nextChar == "\t" {
            escapedChar = #"\t"#
          } else if nextChar == "\"" {
            escapedChar = #"\""#
          } else if nextChar == "\\" {
            escapedChar = #"\\"#
          }
          result = result + escapedChar
          length -= nextChar.utf8.count
          
          if length == 0 {
            try expectNext(["\""])
            try expectNext([";"])
            try expectEOL()
            return result + "\""
          } else if length < 0 {
            throw SwiftPHPSerializationError.unmatchedLength
          }
        }
      case "a":
        try expectNext([":"])
        var length = try expectLength()
        
        try expectNext(["{"])
        
        var items: [String] = []
        while length > 0 {
          length -= 1
          var key = try performUnserialize(iter: iter, rootLevel: false)
          if key.first != "\"" {
            key = "\"\(key)\""
          }
          let value = try performUnserialize(iter: iter, rootLevel: false)
          items.append("\(key):\(value)")
        }
        try expectNext(["}"])
        try expectEOL()
        return "{\(items.joined(separator: ","))}"
      case "O":
        throw SwiftPHPSerializationError.objectUnsupported
      default:
        throw SwiftPHPSerializationError.unsupportedType(String(type))
      }
    }
    
    throw SwiftPHPSerializationError.syntaxError
  }
  
  public static func unserialize(_ data: String) throws -> String {
    try performUnserialize(iter: ArrayIterator(Array(data)), rootLevel: true)
  }
}
