import XCTest
import SwiftUI
@testable import ViewInspector

@MainActor
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class TupleViewTests: XCTestCase {
    
    func testSimpleTupleView() throws {
        let view = SimpleTupleView().padding()
        let sut = try view.inspect().view(SimpleTupleView.self).implicitAnyView()
        XCTAssertThrows(try sut.emptyView(),
                        "Unable to extract EmptyView: please specify its index inside parent view")
        XCTAssertNoThrow(try sut.emptyView(0))
        XCTAssertNoThrow(try sut.text(1))
    }
    
    func testTupleInsideTupleView() throws {
        let view = TupleInsideTupleView(flag: true)
        let string1 = try view.inspect().implicitAnyView().hStack().text(0).string()
        XCTAssertEqual(string1, "xyz")
        XCTAssertThrows(try view.inspect().implicitAnyView().hStack().text(1),
                        "Please insert .tupleView(1) after HStack for inspecting its children at index 1")
        let string2 = try view.inspect().implicitAnyView().hStack().tupleView(1).text(0).string()
        XCTAssertEqual(string2, "abc")
        let string3 = try view.inspect().implicitAnyView().hStack().tupleView(1).text(1).string()
        XCTAssertEqual(string3, "def")
    }
    
    func testSearch() throws {
        let view1 = TupleInsideTupleView(flag: true)
        let view2 = TupleInsideTupleView(flag: false)
        #if compiler(<6)
        XCTAssertEqual(try view1.inspect().find(text: "xyz").pathToRoot,
                       "view(TupleInsideTupleView.self).hStack().text(0)")
        XCTAssertEqual(try view1.inspect().find(text: "abc").pathToRoot,
                       "view(TupleInsideTupleView.self).hStack().tupleView(1).text(0)")
        XCTAssertEqual(try view1.inspect().find(text: "def").pathToRoot,
                       "view(TupleInsideTupleView.self).hStack().tupleView(1).text(1)")
        XCTAssertEqual(try view2.inspect().find(text: "xyz").pathToRoot,
                       "view(TupleInsideTupleView.self).hStack().text(0)")
        #else
        XCTAssertEqual(try view1.inspect().find(text: "xyz").pathToRoot,
                       "view(TupleInsideTupleView.self).anyView().hStack().text(0)")
        XCTAssertEqual(try view1.inspect().find(text: "abc").pathToRoot,
                       "view(TupleInsideTupleView.self).anyView().hStack().tupleView(1).text(0)")
        XCTAssertEqual(try view1.inspect().find(text: "def").pathToRoot,
                       "view(TupleInsideTupleView.self).anyView().hStack().tupleView(1).text(1)")
        XCTAssertEqual(try view2.inspect().find(text: "xyz").pathToRoot,
                       "view(TupleInsideTupleView.self).anyView().hStack().text(0)")
        #endif
        XCTAssertThrows(try view2.inspect().find(text: "abc"), "Search did not find a match")
        XCTAssertThrows(try view2.inspect().find(text: "def"), "Search did not find a match")
    }
    
    func testResetsModifiers() throws {
        let view = TupleInsideTupleView(flag: true)
        let sut = try view.inspect().implicitAnyView().hStack().tupleView(1).text(0)
        XCTAssertEqual(sut.content.medium.viewModifiers.count, 2)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
private struct SimpleTupleView: View {
    var body: some View {
        EmptyView()
        Text("abc")
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
private struct TupleInsideTupleView: View {
    
    let flag: Bool
    var body: some View {
        HStack {
            Text("xyz")
            if flag {
                Text("abc").offset().blur(radius: 1)
                Text("def")
            }
        }.padding()
    }
}
