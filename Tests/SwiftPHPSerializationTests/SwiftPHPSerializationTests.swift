import XCTest
@testable import SwiftPHPSerialization

final class SwiftPHPSerializationTests: XCTestCase {
  func testUnserialize() throws {
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("N;"), "null")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("d:42.378900000000002;"), "42.378900000000002")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("i:42;"), "42")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("b:1;"), "true")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("b:0;"), "false")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("b:0;"), "false")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("b:0;"), "false")
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("s:1:\"\r\";"), #""\r""#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize("s:1:\"\t\";"), #""\t""#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"s:1:"\";"#), #""\\""#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"s:1:"/";"#), #""/""#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"s:1:""";"#), #""\"""#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"a:0:{}"#), #"{}"#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"a:3:{i:0;i:10;i:1;i:11;i:2;i:12;}"#), #"{"0":10,"1":11,"2":12}"#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"a:2:{s:3:"foo";i:4;s:3:"bar";i:2;}"#), #"{"foo":4,"bar":2}"#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"a:2:{i:1;s:4:"😄";i:0;a:1:{i:1;s:4:"😄";}}"#), #"{"1":"😄","0":{"1":"😄"}}"#)
    XCTAssertEqual(try! SwiftPHPSerialization.unserialize(#"a:1:{i:0;a:12:{s:5:"index";i:0;s:8:"isActive";b:1;s:7:"balance";s:9:"$1,188.74";s:7:"picture";s:25:"http://placehold.it/32x32";s:3:"age";i:24;s:8:"eyeColor";s:5:"green";s:5:"phone";s:17:"+1 (933) 453-3472";s:10:"registered";s:26:"2014-04-25T02:31:22 -08:00";s:8:"latitude";d:60.196052999999999;s:9:"longitude";d:21.701187000000001;s:4:"tags";a:3:{i:0;s:9:"excepteur";i:1;s:2:"et";i:2;s:8:"pariatur";}s:7:"friends";a:3:{i:0;a:2:{s:2:"id";i:0;s:4:"name";s:16:"Alexander Graham";}i:1;a:2:{s:2:"id";i:1;s:4:"name";s:13:"Richmond Bean";}i:2;a:2:{s:2:"id";i:2;s:4:"name";s:12:"Ayers Burris";}}}}"#), #"{"0":{"index":0,"isActive":true,"balance":"$1,188.74","picture":"http://placehold.it/32x32","age":24,"eyeColor":"green","phone":"+1 (933) 453-3472","registered":"2014-04-25T02:31:22 -08:00","latitude":60.196052999999999,"longitude":21.701187000000001,"tags":{"0":"excepteur","1":"et","2":"pariatur"},"friends":{"0":{"id":0,"name":"Alexander Graham"},"1":{"id":1,"name":"Richmond Bean"},"2":{"id":2,"name":"Ayers Burris"}}}}"#)

  }

  func testSerialize() throws {
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("null"), "N;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("{}"), "a:0:{}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(" { }"), "a:0:{}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("[]"), "a:0:{}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("[ ] "), "a:0:{}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("[null, null  ,null]"), "a:3:{i:0;N;i:1;N;i:2;N;}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(" [  null, null  ,null] "), "a:3:{i:0;N;i:1;N;i:2;N;}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#"{ "1": 12, "2": 24  }"#), "a:2:{i:1;i:12;i:2;i:24;}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#" { "1" : 12,"2"  : 24  }"#), "a:2:{i:1;i:12;i:2;i:24;}")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#""\u90fd""#), #"s:3:"都";"#)
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#""\n""#), "s:1:\"\n\";")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#""\t""#), "s:1:\"\t\";")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(""), "s:0:\"\"")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#""😄""#), "s:4:\"😄\";")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("42.378900000000002"), "d:42.378900000000002;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("42"), "i:42;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("3.7E-5"), "d:3.7E-5;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("0e0"), "d:0e0;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("-2"), "i:-2;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("true"), "b:1;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize("false"), "b:0;")
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#""foobar""#), #"s:6:"foobar";"#)
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#"{"0":10,"1":11,"2":12}"#), #"a:3:{i:0;i:10;i:1;i:11;i:2;i:12;}"#)
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#"{"foo":4,"bar":2}"#), #"a:2:{s:3:"foo";i:4;s:3:"bar";i:2;}"#)
    XCTAssertEqual(try! SwiftPHPSerialization.serialize(#"{"friends": [ {"id":0,"name": "Alexander Graham" }, { "id": 1, "name":"Richmond Bean" }, { "id": 2, "name": "Ayers Burris"} ] }"#), #"a:1:{s:7:"friends";a:3:{i:0;a:2:{s:2:"id";i:0;s:4:"name";s:16:"Alexander Graham";}i:1;a:2:{s:2:"id";i:1;s:4:"name";s:13:"Richmond Bean";}i:2;a:2:{s:2:"id";i:2;s:4:"name";s:12:"Ayers Burris";}}}"#)
  }

  func testSerializeAndUnserialize() throws {
    func test(_ string: String) {
      XCTAssertEqual(string, try! SwiftPHPSerialization.serialize(SwiftPHPSerialization.unserialize(string)))
    }

    test(#"s:0:"";"#)
    test("N;")
    test("a:0:{}")
    test("s:1:\"\t\";")
    test(#"s:1:"\";"#)
    test("b:1;")
    test("b:0;")
    test("i:199;")
    test("d:1029.12321312123;")
    test(#"a:2:{i:0;s:0:"";i:1;b:0;}"#)
    test(#"a:4:{s:6:"_token";s:40:"nSh5GbbZplACOiAtPz13QVWqnANf8KEPhph4LDgX";s:11:"play_status";s:6:"queued";s:9:"_previous";a:1:{s:3:"url";s:27:"http://localhost:8081/login";}s:6:"_flash";a:2:{s:3:"old";a:0:{}s:3:"new";a:0:{}}}"#)
    test(#"a:1:{i:0;a:12:{s:5:"index";i:0;s:8:"isActive";b:1;s:7:"balance";s:9:"$1,188.74";s:7:"picture";s:25:"http://placehold.it/32x32";s:3:"age";i:24;s:8:"eyeColor";s:5:"green";s:5:"phone";s:17:"+1 (933) 453-3472";s:10:"registered";s:26:"2014-04-25T02:31:22 -08:00";s:8:"latitude";d:60.196052999999999;s:9:"longitude";d:21.701187000000001;s:4:"tags";a:3:{i:0;s:9:"excepteur";i:1;s:2:"et";i:2;s:8:"pariatur";}s:7:"friends";a:3:{i:0;a:2:{s:2:"id";i:0;s:4:"name";s:16:"Alexander Graham";}i:1;a:2:{s:2:"id";i:1;s:4:"name";s:13:"Richmond Bean";}i:2;a:2:{s:2:"id";i:2;s:4:"name";s:12:"Ayers Burris";}}}}"#)
  }
  
  func testFailedCases() throws {
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"O:4:"Test":3:{s:6:"public";i:1;s:12:"\0*\0protected";i:2;s:13:"\0Test\0private";i:3;};"#)) {
      XCTAssertEqual($0 as? SwiftPHPSerializationError, SwiftPHPSerializationError.objectUnsupported)
    }
    
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#""#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"s:0:"";;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"s:-1:"";"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"N"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"s:1:"a";;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#";"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"N;;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"s:1"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"s:1:"abc";"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"s:10:"abc";"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"i:100"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"i:100;;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"d:100"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"d:100;;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"abc"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"😄"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"a:3:{};"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"a:4:{i:0;i:10;i:1;i:11;i:2;i:12;}"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"a:2:{i:0;i:10;i:1;i:11;i:2;i:12;}"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"a:3:{i:0;i:10;i:1;i:11;i:2;i:12;};"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"b:2;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.unserialize(#"b:1;;"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"fewfewfewe"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"truee"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"nulll"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"""#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"1."#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"[]a"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#"{}a"#))
    XCTAssertThrowsError(try SwiftPHPSerialization.serialize(#";"#))
  }
}
