import XCTest
import SwiftUI
@testable import ViewInspector

@MainActor
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class NavigationBarModifiersTests: XCTestCase {
    
    func testNavigationViewStyle() throws {
        guard #available(watchOS 7.0, *) else { throw XCTSkip() }
        let sut = EmptyView().navigationViewStyle(DefaultNavigationViewStyle())
        XCTAssertNoThrow(try sut.inspect().emptyView())
    }
    
    func testNavigationStyleInspection() throws {
        guard #available(watchOS 7.0, *) else { throw XCTSkip() }
        let sut = EmptyView().navigationViewStyle(DefaultNavigationViewStyle())
        XCTAssertTrue(try sut.inspect().navigationViewStyle() is DefaultNavigationViewStyle)
    }
    
    #if !os(macOS)
    func testNavigationBarHidden() throws {
        let sut1 = EmptyView().navigationBarHidden(false)
        let sut2 = EmptyView().navigationBarHidden(true)
        let sut3 = EmptyView().padding()
        XCTAssertFalse(try sut1.inspect().navigationBarHidden())
        XCTAssertTrue(try sut2.inspect().navigationBarHidden())
        XCTAssertThrows(try sut3.inspect().navigationBarHidden(),
            "EmptyView does not have 'navigationBarHidden' modifier")
    }
    
    func testNavigationBarBackButtonHidden() throws {
        let sut1 = try EmptyView().navigationBarBackButtonHidden(false).inspect()
        let sut2 = try EmptyView().navigationBarBackButtonHidden(true).inspect()
        let sut3 = try EmptyView().padding().inspect()
        XCTAssertFalse(try sut1.navigationBarBackButtonHidden())
        XCTAssertTrue(try sut2.navigationBarBackButtonHidden())
        XCTAssertThrows(try sut3.navigationBarBackButtonHidden(),
            "EmptyView does not have 'navigationBarBackButtonHidden' modifier")
    }
    #endif
}

#if os(iOS) || os(tvOS) || os(visionOS)
@MainActor
@available(iOS 13.0, tvOS 13.0, *)
final class NavigationBarItemsTests: XCTestCase {
    
    func skipForiOS15(file: StaticString = #file, line: UInt = #line) throws {
        if #available(iOS 15.0, tvOS 15.0, *) {
            throw XCTSkip("Not relevant for iOS 15", file: file, line: line)
        }
    }
    
    func testUnaryViewAdaptor() throws {
        guard #available(iOS 15.0, tvOS 15.0, *) else { throw XCTSkip() }
        let sut = EmptyView()
            .navigationBarItems(trailing: Text("abc"))
        XCTAssertNoThrow(try sut.inspect().emptyView())
    }

    func testIncorrectUnwrap() throws {
        try skipForiOS15()
        let view = NavigationView {
            List { Text("") }
                .navigationBarItems(trailing: Text(""))
        }
        XCTAssertThrows(
            try view.inspect().navigationView().list(0).text(0),
            "Please insert '.navigationBarItems()' before list(0) for unwrapping the underlying view hierarchy.")
    }

    func testUnknownHierarchyTypeUnwrap() throws {
        try skipForiOS15()
        let view = NavigationView {
            List { Text("") }
                .navigationBarItems(trailing: Text(""))
        }
        XCTAssertThrows(
            try view.inspect().navigationView().navigationBarItems().list(),
            "Please substitute 'List<Never, Text>.self' as the parameter for 'navigationBarItems()' inspection call")
    }

    func testKnownHierarchyTypeUnwrap() throws {
        try skipForiOS15()
        let string = "abc"
        let view = NavigationView {
            List { Text(string) }
                .navigationBarItems(trailing: Text(""))
        }
        let value = try view.inspect().navigationView()
            .navigationBarItems(List<Never, Text>.self)
            .list().text(0).string()
        XCTAssertEqual(value, string)
    }
    
    func testSearchBlocker() throws {
        try skipForiOS15()
        let view = AnyView(NavigationView {
            Text("abc")
                .navigationBarItems(trailing: Text(""))
        })
        XCTAssertThrows(try view.inspect().find(text: "abc"),
                        "Search did not find a match")
    }
    
    func testRetainsModifiers() throws {
        try skipForiOS15()
        let view = NavigationView {
            Text("")
                .padding()
                .navigationBarItems(trailing: Text(""))
                .padding().padding()
        }
        let sut = try view.inspect().navigationView()
            .navigationBarItems(ModifiedContent<Text, _PaddingLayout>.self)
            .text()
        XCTAssertEqual(sut.content.medium.viewModifiers.count, 4)
    }
    
    func testMissingModifier() throws {
        try skipForiOS15()
        let sut = EmptyView().padding()
        XCTAssertThrows(
            try sut.inspect().navigationBarItems(),
            "EmptyView does not have 'navigationBarItems' modifier")
    }

    func testCustomViewUnwrapStepOne() throws {
        try skipForiOS15()
        let sut = TestView()
        let exp = sut.inspection.inspect { view in
            XCTAssertThrows(try view.vStack(),
            "Please insert '.navigationBarItems()' before vStack() for unwrapping the underlying view hierarchy.")
        }
        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }
        wait(for: [exp], timeout: 1.0)
    }

    func testCustomViewUnwrapStepTwo() throws {
        try skipForiOS15()
        let sut = TestView()
        let exp = sut.inspection.inspect { view in
            XCTAssertThrows(try view.navigationBarItems().vStack(),
            "Please substitute 'VStack<Text>.self' as the parameter for 'navigationBarItems()' inspection call")
        }
        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }
        wait(for: [exp], timeout: 1.0)
    }

    func testCustomViewUnwrapStepThree() throws {
        try skipForiOS15()
        let sut = TestView()
        let exp = sut.inspection.inspect { view in
            typealias WrappedView = VStack<Text>
            let value = try view.navigationBarItems(WrappedView.self).vStack().text(0).string()
            XCTAssertEqual(value, "abc")
        }
        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }
        wait(for: [exp], timeout: 1.0)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
private struct TestView: View {
    
    let inspection = Inspection<Self>()
        
    var body: some View {
        VStack {
            Text("abc")
        }
        .navigationBarItems(trailing: button)
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
        
    private var button: some View {
        Button("", action: { })
    }
}
#endif

@MainActor
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class StatusBarConfigurationTests: XCTestCase {
    
    #if os(iOS)
    func testStatusBarHidden() throws {
        let sut1 = try EmptyView().statusBar(hidden: false).inspect()
        let sut2 = try EmptyView().statusBar(hidden: true).inspect()
        let sut3 = try EmptyView().padding().inspect()
        XCTAssertFalse(try sut1.statusBarHidden())
        XCTAssertTrue(try sut2.statusBarHidden())
        XCTAssertThrows(try sut3.statusBarHidden(),
            "EmptyView does not have 'statusBar(hidden:)' modifier")
    }
    #endif
}

@MainActor
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
final class NavigationTitleBindingTests: XCTestCase {

    func testNavigationTitleInspection() throws {
        let sut = EmptyView().navigationTitle(.constant("bound"))
        XCTAssertNoThrow(try sut.inspect().emptyView())
    }

    func testNavigationTitleBinding() throws {
        let binding = Binding(wrappedValue: "123")
        let sut = try EmptyView().navigationTitle(binding).inspect()
        XCTAssertEqual(try sut.navigationTitle(), "123")
        try sut.setNavigationTitle("abc")
        XCTAssertEqual(try sut.navigationTitle(), "abc")
    }

    func testNavigationTitleText() throws {
        XCTAssertThrows(try EmptyView().navigationTitle(Text("123")).inspect().navigationTitle(),
                        "navigationTitle() is only supported with a Binding<String> parameter.")
        XCTAssertThrows(try EmptyView().navigationTitle("123").inspect().navigationTitle(),
                        "navigationTitle() is only supported with a Binding<String> parameter.")
        XCTAssertThrows(try EmptyView().navigationTitle(String("123")).inspect().navigationTitle(),
                        "navigationTitle() is only supported with a Binding<String> parameter.")
        XCTAssertThrows(try EmptyView().navigationTitle(Text("123")).inspect().setNavigationTitle(""),
                        "navigationTitle() is only supported with a Binding<String> parameter.")
        XCTAssertThrows(try EmptyView().navigationTitle("123").inspect().setNavigationTitle(""),
                        "navigationTitle() is only supported with a Binding<String> parameter.")
        XCTAssertThrows(try EmptyView().navigationTitle(String("123")).inspect().setNavigationTitle(""),
                        "navigationTitle() is only supported with a Binding<String> parameter.")
    }
}
