//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//


#if canImport(TestSupport)
import TestSupport
#endif // canImport(TestSupport)

#if canImport(FoundationEssentials)
@testable import FoundationEssentials
#endif

#if FOUNDATION_FRAMEWORK
@testable import Foundation
#endif

private func checkBehavior<T: Equatable>(_ result: T, new: T, old: T, file: StaticString = #filePath, line: UInt = #line) {
    #if FOUNDATION_FRAMEWORK
    if foundation_swift_url_enabled() {
        XCTAssertEqual(result, new, file: file, line: line)
    } else {
        XCTAssertEqual(result, old, file: file, line: line)
    }
    #else
    XCTAssertEqual(result, new, file: file, line: line)
    #endif
}

final class URLTests : XCTestCase {

    func testURLBasics() throws {
        let string = "https://username:password@example.com:80/path/path?query=value&q=v#fragment"
        let url = try XCTUnwrap(URL(string: string))

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.user(), "username")
        XCTAssertEqual(url.password(), "password")
        XCTAssertEqual(url.host(), "example.com")
        XCTAssertEqual(url.port, 80)
        XCTAssertEqual(url.path(), "/path/path")
        XCTAssertEqual(url.relativePath, "/path/path")
        XCTAssertEqual(url.query(), "query=value&q=v")
        XCTAssertEqual(url.fragment(), "fragment")
        XCTAssertEqual(url.absoluteString, string)
        XCTAssertEqual(url.absoluteURL, url)
        XCTAssertEqual(url.relativeString, string)
        XCTAssertNil(url.baseURL)

        let baseString = "https://user:pass@base.example.com:8080/base/"
        let baseURL = try XCTUnwrap(URL(string: baseString))
        let absoluteURLWithBase = try XCTUnwrap(URL(string: string, relativeTo: baseURL))

        // The URL is already absolute, so .baseURL is nil, and the components are unchanged
        XCTAssertEqual(absoluteURLWithBase.scheme, "https")
        XCTAssertEqual(absoluteURLWithBase.user(), "username")
        XCTAssertEqual(absoluteURLWithBase.password(), "password")
        XCTAssertEqual(absoluteURLWithBase.host(), "example.com")
        XCTAssertEqual(absoluteURLWithBase.port, 80)
        XCTAssertEqual(absoluteURLWithBase.path(), "/path/path")
        XCTAssertEqual(absoluteURLWithBase.relativePath, "/path/path")
        XCTAssertEqual(absoluteURLWithBase.query(), "query=value&q=v")
        XCTAssertEqual(absoluteURLWithBase.fragment(), "fragment")
        XCTAssertEqual(absoluteURLWithBase.absoluteString, string)
        XCTAssertEqual(absoluteURLWithBase.absoluteURL, url)
        XCTAssertEqual(absoluteURLWithBase.relativeString, string)
        XCTAssertNil(absoluteURLWithBase.baseURL)
        XCTAssertEqual(absoluteURLWithBase.absoluteURL, url)

        let relativeString = "relative/path?query#fragment"
        let relativeURL = try XCTUnwrap(URL(string: relativeString))

        XCTAssertNil(relativeURL.scheme)
        XCTAssertNil(relativeURL.user())
        XCTAssertNil(relativeURL.password())
        XCTAssertNil(relativeURL.host())
        XCTAssertNil(relativeURL.port)
        XCTAssertEqual(relativeURL.path(), "relative/path")
        XCTAssertEqual(relativeURL.relativePath, "relative/path")
        XCTAssertEqual(relativeURL.query(), "query")
        XCTAssertEqual(relativeURL.fragment(), "fragment")
        XCTAssertEqual(relativeURL.absoluteString, relativeString)
        XCTAssertEqual(relativeURL.absoluteURL, relativeURL)
        XCTAssertEqual(relativeURL.relativeString, relativeString)
        XCTAssertNil(relativeURL.baseURL)

        let relativeURLWithBase = try XCTUnwrap(URL(string: relativeString, relativeTo: baseURL))

        XCTAssertEqual(relativeURLWithBase.scheme, baseURL.scheme)
        XCTAssertEqual(relativeURLWithBase.user(), baseURL.user())
        XCTAssertEqual(relativeURLWithBase.password(), baseURL.password())
        XCTAssertEqual(relativeURLWithBase.host(), baseURL.host())
        XCTAssertEqual(relativeURLWithBase.port, baseURL.port)
        XCTAssertEqual(relativeURLWithBase.path(), "/base/relative/path")
        XCTAssertEqual(relativeURLWithBase.relativePath, "relative/path")
        XCTAssertEqual(relativeURLWithBase.query(), "query")
        XCTAssertEqual(relativeURLWithBase.fragment(), "fragment")
        XCTAssertEqual(relativeURLWithBase.absoluteString, "https://user:pass@base.example.com:8080/base/relative/path?query#fragment")
        XCTAssertEqual(relativeURLWithBase.absoluteURL, URL(string: "https://user:pass@base.example.com:8080/base/relative/path?query#fragment"))
        XCTAssertEqual(relativeURLWithBase.relativeString, relativeString)
        XCTAssertEqual(relativeURLWithBase.baseURL, baseURL)
    }

    func testURLResolvingAgainstBase() throws {
        let base = URL(string: "http://a/b/c/d;p?q")
        let tests = [
            // RFC 3986 5.4.1. Normal Examples
            "g:h"           :  "g:h",
            "g"             :  "http://a/b/c/g",
            "./g"           :  "http://a/b/c/g",
            "g/"            :  "http://a/b/c/g/",
            "/g"            :  "http://a/g",
            "//g"           :  "http://g",
            "?y"            :  "http://a/b/c/d;p?y",
            "g?y"           :  "http://a/b/c/g?y",
            "#s"            :  "http://a/b/c/d;p?q#s",
            "g#s"           :  "http://a/b/c/g#s",
            "g?y#s"         :  "http://a/b/c/g?y#s",
            ";x"            :  "http://a/b/c/;x",
            "g;x"           :  "http://a/b/c/g;x",
            "g;x?y#s"       :  "http://a/b/c/g;x?y#s",
            ""              :  "http://a/b/c/d;p?q",
            "."             :  "http://a/b/c/",
            "./"            :  "http://a/b/c/",
            ".."            :  "http://a/b/",
            "../"           :  "http://a/b/",
            "../g"          :  "http://a/b/g",
            "../.."         :  "http://a/",
            "../../"        :  "http://a/",
            "../../g"       :  "http://a/g",

            // RFC 3986 5.4.1. Abnormal Examples
            "../../../g"    :  "http://a/g",
            "../../../../g" :  "http://a/g",
            "/./g"          :  "http://a/g",
            "/../g"         :  "http://a/g",
            "g."            :  "http://a/b/c/g.",
            ".g"            :  "http://a/b/c/.g",
            "g.."           :  "http://a/b/c/g..",
            "..g"           :  "http://a/b/c/..g",

            "./../g"        :  "http://a/b/g",
            "./g/."         :  "http://a/b/c/g/",
            "g/./h"         :  "http://a/b/c/g/h",
            "g/../h"        :  "http://a/b/c/h",
            "g;x=1/./y"     :  "http://a/b/c/g;x=1/y",
            "g;x=1/../y"    :  "http://a/b/c/y",

            "g?y/./x"       :  "http://a/b/c/g?y/./x",
            "g?y/../x"      :  "http://a/b/c/g?y/../x",
            "g#s/./x"       :  "http://a/b/c/g#s/./x",
            "g#s/../x"      :  "http://a/b/c/g#s/../x",

            "http:g"        :  "http:g", // For strict parsers
        ]

        let testsFailingWithoutSwiftURL = Set([
            "",
            "../../../g",
            "../../../../g",
            "/./g",
            "/../g",
        ])

        for test in tests {
            if !foundation_swift_url_enabled(), testsFailingWithoutSwiftURL.contains(test.key) {
                continue
            }

            let url = URL(stringOrEmpty: test.key, relativeTo: base)
            XCTAssertNotNil(url, "Got nil url for string: \(test.key)")
            XCTAssertEqual(url?.absoluteString, test.value, "Failed test for string: \(test.key)")
        }
    }

    func testURLPathAPIsResolveAgainstBase() throws {
        try XCTSkipIf(!foundation_swift_url_enabled())
        // Borrowing the same test cases from RFC 3986, but checking paths
        let base = URL(string: "http://a/b/c/d;p?q")
        let tests = [
            // RFC 3986 5.4.1. Normal Examples
            "g:h"           :  "h",
            "g"             :  "/b/c/g",
            "./g"           :  "/b/c/g",
            "g/"            :  "/b/c/g/",
            "/g"            :  "/g",
            "//g"           :  "",
            "?y"            :  "/b/c/d;p",
            "g?y"           :  "/b/c/g",
            "#s"            :  "/b/c/d;p",
            "g#s"           :  "/b/c/g",
            "g?y#s"         :  "/b/c/g",
            ";x"            :  "/b/c/;x",
            "g;x"           :  "/b/c/g;x",
            "g;x?y#s"       :  "/b/c/g;x",
            ""              :  "/b/c/d;p",
            "."             :  "/b/c/",
            "./"            :  "/b/c/",
            ".."            :  "/b/",
            "../"           :  "/b/",
            "../g"          :  "/b/g",
            "../.."         :  "/",
            "../../"        :  "/",
            "../../g"       :  "/g",

            // RFC 3986 5.4.1. Abnormal Examples
            "../../../g"    :  "/g",
            "../../../../g" :  "/g",
            "/./g"          :  "/g",
            "/../g"         :  "/g",
            "g."            :  "/b/c/g.",
            ".g"            :  "/b/c/.g",
            "g.."           :  "/b/c/g..",
            "..g"           :  "/b/c/..g",

            "./../g"        :  "/b/g",
            "./g/."         :  "/b/c/g/",
            "g/./h"         :  "/b/c/g/h",
            "g/../h"        :  "/b/c/h",
            "g;x=1/./y"     :  "/b/c/g;x=1/y",
            "g;x=1/../y"    :  "/b/c/y",

            "g?y/./x"       :  "/b/c/g",
            "g?y/../x"      :  "/b/c/g",
            "g#s/./x"       :  "/b/c/g",
            "g#s/../x"      :  "/b/c/g",

            "http:g"        :  "g", // For strict parsers
        ]
        for test in tests {
            let url = URL(stringOrEmpty: test.key, relativeTo: base)!
            XCTAssertEqual(url.absolutePath(), test.value)
            if (url.hasDirectoryPath && url.absolutePath().count > 1) {
                // The trailing slash is stripped in .path for file system compatibility
                XCTAssertEqual(String(url.absolutePath().dropLast()), url.path)
            } else {
                XCTAssertEqual(url.absolutePath(), url.path)
            }
        }
    }

    func testURLPathComponentsPercentEncodedSlash() throws {
        try XCTSkipIf(!foundation_swift_url_enabled())

        var url = try XCTUnwrap(URL(string: "https://example.com/https%3A%2F%2Fexample.com"))
        XCTAssertEqual(url.pathComponents, ["/", "https://example.com"])

        url = try XCTUnwrap(URL(string: "https://example.com/https:%2f%2fexample.com"))
        XCTAssertEqual(url.pathComponents, ["/", "https://example.com"])

        url = try XCTUnwrap(URL(string: "https://example.com/https:%2F%2Fexample.com%2Fpath"))
        XCTAssertEqual(url.pathComponents, ["/", "https://example.com/path"])

        url = try XCTUnwrap(URL(string: "https://example.com/https:%2F%2Fexample.com/path"))
        XCTAssertEqual(url.pathComponents, ["/", "https://example.com", "path"])

        url = try XCTUnwrap(URL(string: "https://example.com/https%3A%2F%2Fexample.com%2Fpath%3Fquery%23fragment"))
        XCTAssertEqual(url.pathComponents, ["/", "https://example.com/path?query#fragment"])

        url = try XCTUnwrap(URL(string: "https://example.com/https%3A%2F%2Fexample.com%2Fpath?query#fragment"))
        XCTAssertEqual(url.pathComponents, ["/", "https://example.com/path"])
    }

    func testURLRootlessPath() throws {
        try XCTSkipIf(!foundation_swift_url_enabled())

        let paths = ["", "path"]
        let queries = [nil, "query"]
        let fragments = [nil, "fragment"]

        for path in paths {
            for query in queries {
                for fragment in fragments {
                    let queryString = query != nil ? "?\(query!)" : ""
                    let fragmentString = fragment != nil ? "#\(fragment!)" : ""
                    let urlString = "scheme:\(path)\(queryString)\(fragmentString)"
                    let url = try XCTUnwrap(URL(string: urlString))
                    XCTAssertEqual(url.absoluteString, urlString)
                    XCTAssertEqual(url.scheme, "scheme")
                    XCTAssertNil(url.host())
                    XCTAssertEqual(url.path(), path)
                    XCTAssertEqual(url.query(), query)
                    XCTAssertEqual(url.fragment(), fragment)
                }
            }
        }
    }

    func testURLNonSequentialIPLiteralAndPort() {
        let urlString = "https://[fe80::3221:5634:6544]invalid:433/"
        let url = URL(string: urlString)
        XCTAssertNil(url)
    }

    func testURLFilePathInitializer() throws {
        let directory = URL(filePath: "/some/directory", directoryHint: .isDirectory)
        XCTAssertTrue(directory.hasDirectoryPath)

        let notDirectory = URL(filePath: "/some/file", directoryHint: .notDirectory)
        XCTAssertFalse(notDirectory.hasDirectoryPath)

        // directoryHint defaults to .inferFromPath
        let directoryAgain = URL(filePath: "/some/directory.framework/")
        XCTAssertTrue(directoryAgain.hasDirectoryPath)

        let notDirectoryAgain = URL(filePath: "/some/file")
        XCTAssertFalse(notDirectoryAgain.hasDirectoryPath)

        // Test .checkFileSystem by creating a directory
        let tempDirectory = URL.temporaryDirectory
        let urlBeforeCreation = URL(filePath: "\(tempDirectory.path)/tmp-dir", directoryHint: .checkFileSystem)
        XCTAssertFalse(urlBeforeCreation.hasDirectoryPath)

        try FileManager.default.createDirectory(
            at: URL(filePath: "\(tempDirectory.path)/tmp-dir"),
            withIntermediateDirectories: true
        )
        let urlAfterCreation = URL(filePath: "\(tempDirectory.path)/tmp-dir", directoryHint: .checkFileSystem)
        XCTAssertTrue(urlAfterCreation.hasDirectoryPath)
        try FileManager.default.removeItem(at: URL(filePath: "\(tempDirectory.path)/tmp-dir"))
    }

    #if os(Windows)
    func testURLWindowsDriveLetterPath() throws {
        var url = URL(filePath: #"C:\test\path"#, directoryHint: .notDirectory)
        // .absoluteString and .path() use the RFC 8089 URL path
        XCTAssertEqual(url.absoluteString, "file:///C:/test/path")
        XCTAssertEqual(url.path(), "/C:/test/path")
        // .path and .fileSystemPath() strip the leading slash
        XCTAssertEqual(url.path, "C:/test/path")
        XCTAssertEqual(url.fileSystemPath(), "C:/test/path")

        url = URL(filePath: #"C:\"#, directoryHint: .isDirectory)
        XCTAssertEqual(url.absoluteString, "file:///C:/")
        XCTAssertEqual(url.path(), "/C:/")
        XCTAssertEqual(url.path, "C:/")
        XCTAssertEqual(url.fileSystemPath(), "C:/")

        url = URL(filePath: #"C:\\\"#, directoryHint: .isDirectory)
        XCTAssertEqual(url.absoluteString, "file:///C:///")
        XCTAssertEqual(url.path(), "/C:///")
        XCTAssertEqual(url.path, "C:/")
        XCTAssertEqual(url.fileSystemPath(), "C:/")

        url = URL(filePath: #"\C:\"#, directoryHint: .isDirectory)
        XCTAssertEqual(url.absoluteString, "file:///C:/")
        XCTAssertEqual(url.path(), "/C:/")
        XCTAssertEqual(url.path, "C:/")
        XCTAssertEqual(url.fileSystemPath(), "C:/")

        let base = URL(filePath: #"\d:\path\"#, directoryHint: .isDirectory)
        url = URL(filePath: #"%43:\fake\letter"#, directoryHint: .notDirectory, relativeTo: base)
        // ":" is encoded to "%3A" in the first path segment so it's not mistaken as the scheme separator
        XCTAssertEqual(url.relativeString, "%2543%3A/fake/letter")
        XCTAssertEqual(url.path(), "/d:/path/%2543%3A/fake/letter")
        XCTAssertEqual(url.path, "d:/path/%43:/fake/letter")
        XCTAssertEqual(url.fileSystemPath(), "d:/path/%43:/fake/letter")

        let cwd = URL.currentDirectory()
        var iter = cwd.path().utf8.makeIterator()
        if iter.next() == ._slash,
           let driveLetter = iter.next(), driveLetter.isLetter!,
           iter.next() == ._colon {
            let path = #"\\?\"# + "\(Unicode.Scalar(driveLetter))" + #":\"#
            url = URL(filePath: path, directoryHint: .isDirectory)
            XCTAssertEqual(url.path.last, "/")
            XCTAssertEqual(url.fileSystemPath().last, "/")
        }
    }
    #endif

    func testURLFilePathRelativeToBase() throws {
        try FileManagerPlayground {
            Directory("dir") {
                "Foo"
                "Bar"
            }
        }.test {
            let currentDirectoryPath = $0.currentDirectoryPath
            let baseURL = URL(filePath: currentDirectoryPath, directoryHint: .isDirectory)
            let relativePath = "dir"

            let url1 = URL(filePath: relativePath, directoryHint: .isDirectory, relativeTo: baseURL)

            let url2 = URL(filePath: relativePath, directoryHint: .checkFileSystem, relativeTo: baseURL)
            XCTAssertEqual(url1, url2, "\(url1) was not equal to \(url2)")

            // directoryHint is `.inferFromPath` by default
            let url3 = URL(filePath: relativePath + "/", relativeTo: baseURL)
            XCTAssertEqual(url1, url3, "\(url1) was not equal to \(url3)")
        }
    }

    func testURLFilePathDoesNotFollowLastSymlink() throws {
        try FileManagerPlayground {
            Directory("dir") {
                "Foo"
                SymbolicLink("symlink", destination: "../dir")
            }
        }.test {
            let currentDirectoryPath = $0.currentDirectoryPath
            let baseURL = URL(filePath: currentDirectoryPath, directoryHint: .isDirectory)

            let dirURL = baseURL.appending(path: "dir", directoryHint: .checkFileSystem)
            XCTAssertTrue(dirURL.hasDirectoryPath)

            var symlinkURL = dirURL.appending(path: "symlink", directoryHint: .notDirectory)

            // FileManager uses stat(), which will follow the symlink to the directory.

            #if FOUNDATION_FRAMEWORK
            var isDirectory: ObjCBool = false
            XCTAssertTrue(FileManager.default.fileExists(atPath: symlinkURL.path, isDirectory: &isDirectory))
            XCTAssertTrue(isDirectory.boolValue)
            #else
            var isDirectory = false
            XCTAssertTrue(FileManager.default.fileExists(atPath: symlinkURL.path, isDirectory: &isDirectory))
            XCTAssertTrue(isDirectory)
            #endif

            // URL uses lstat(), which will not follow the symlink at the end of the path.
            // Check that URL(filePath:) and .appending(path:) preserve this behavior.

            symlinkURL = URL(filePath: symlinkURL.path, directoryHint: .checkFileSystem)
            XCTAssertFalse(symlinkURL.hasDirectoryPath)

            symlinkURL = dirURL.appending(path: "symlink", directoryHint: .checkFileSystem)
            XCTAssertFalse(symlinkURL.hasDirectoryPath)
        }
    }

    func testURLRelativeDotDotResolution() throws {
        let baseURL = URL(filePath: "/docs/src/")
        var result = URL(filePath: "../images/foo.png", relativeTo: baseURL)
        XCTAssertEqual(result.path, "/docs/images/foo.png")

        result = URL(filePath: "/../images/foo.png", relativeTo: baseURL)
        XCTAssertEqual(result.path, "/../images/foo.png")
    }

    func testAppendFamily() throws {
        let base = URL(string: "https://www.example.com")!

        // Appending path
        XCTAssertEqual(
            base.appending(path: "/api/v2").absoluteString,
            "https://www.example.com/api/v2"
        )
        var testAppendPath = base
        testAppendPath.append(path: "/api/v3")
        XCTAssertEqual(
            testAppendPath.absoluteString,
            "https://www.example.com/api/v3"
        )

        // Appending component
        XCTAssertEqual(
            base.appending(component: "AC/DC").absoluteString,
            "https://www.example.com/AC%2FDC"
        )
        var testAppendComponent = base
        testAppendComponent.append(component: "AC/DC")
        XCTAssertEqual(
            testAppendComponent.absoluteString,
            "https://www.example.com/AC%2FDC"
        )

        // Append queryItems
        let queryItems = [
            URLQueryItem(name: "id", value: "42"),
            URLQueryItem(name: "color", value: "blue")
        ]
        XCTAssertEqual(
            base.appending(queryItems: queryItems).absoluteString,
            "https://www.example.com?id=42&color=blue"
        )
        var testAppendQueryItems = base
        testAppendQueryItems.append(queryItems: queryItems)
        XCTAssertEqual(
            testAppendQueryItems.absoluteString,
            "https://www.example.com?id=42&color=blue"
        )

        // Appending components
        XCTAssertEqual(
            base.appending(components: "api", "artist", "AC/DC").absoluteString,
            "https://www.example.com/api/artist/AC%2FDC"
        )
        var testAppendComponents = base
        testAppendComponents.append(components: "api", "artist", "AC/DC")
        XCTAssertEqual(
            testAppendComponents.absoluteString,
            "https://www.example.com/api/artist/AC%2FDC"
        )

        // Chaining various appends
        let chained = base
            .appending(path: "api/v2")
            .appending(queryItems: [
                URLQueryItem(name: "magic", value: "42"),
                URLQueryItem(name: "color", value: "blue")
            ])
            .appending(components: "get", "products")
        XCTAssertEqual(
            chained.absoluteString,
            "https://www.example.com/api/v2/get/products?magic=42&color=blue"
        )
    }

    func testAppendFamilyDirectoryHint() throws {
        // Make sure directoryHint values are propagated correctly
        let base = URL(string: "file:///var/mobile")!

        // Appending path
        var url = base.appending(path: "/folder/item", directoryHint: .isDirectory)
        XCTAssertTrue(url.hasDirectoryPath)

        url = base.appending(path: "folder/item", directoryHint: .notDirectory)
        XCTAssertFalse(url.hasDirectoryPath)

        url = base.appending(path: "/folder/item.framework/")
        XCTAssertTrue(url.hasDirectoryPath)

        url = base.appending(path: "/folder/item")
        XCTAssertFalse(url.hasDirectoryPath)

        try runDirectoryHintCheckFilesystemTest {
            $0.appending(path: "/folder/item", directoryHint: .checkFileSystem)
        }

        // Appending component
        url = base.appending(component: "AC/DC", directoryHint: .isDirectory)
        XCTAssertTrue(url.hasDirectoryPath)

        url = base.appending(component: "AC/DC", directoryHint: .notDirectory)
        XCTAssertFalse(url.hasDirectoryPath)

        url = base.appending(component: "AC/DC/", directoryHint: .isDirectory)
        XCTAssertTrue(url.hasDirectoryPath)

        url = base.appending(component: "AC/DC")
        XCTAssertFalse(url.hasDirectoryPath)

        try runDirectoryHintCheckFilesystemTest {
            $0.appending(component: "AC/DC", directoryHint: .checkFileSystem)
        }

        // Appending components
        url = base.appending(components: "api", "v2", "AC/DC", directoryHint: .isDirectory)
        XCTAssertTrue(url.hasDirectoryPath)

        url = base.appending(components: "api", "v2", "AC/DC", directoryHint: .notDirectory)
        XCTAssertFalse(url.hasDirectoryPath)

        url = base.appending(components: "api", "v2", "AC/DC/", directoryHint: .isDirectory)
        XCTAssertTrue(url.hasDirectoryPath)

        url = base.appending(components: "api", "v2", "AC/DC")
        XCTAssertFalse(url.hasDirectoryPath)

        try runDirectoryHintCheckFilesystemTest {
            $0.appending(components: "api", "v2", "AC/DC", directoryHint: .checkFileSystem)
        }
    }

    private func runDirectoryHintCheckFilesystemTest(_ builder: (URL) -> URL) throws {
        let tempDirectory = URL.temporaryDirectory
        // We should not have directory path before it's created
        XCTAssertFalse(builder(tempDirectory).hasDirectoryPath)
        // Create the folder
        try FileManager.default.createDirectory(
            at: builder(tempDirectory),
            withIntermediateDirectories: true
        )
        XCTAssertTrue(builder(tempDirectory).hasDirectoryPath)
        try FileManager.default.removeItem(at: builder(tempDirectory))
    }

    func testURLEncodingInvalidCharacters() throws {
        let urlStrings = [
            " ",
            "path space",
            "/absolute path space",
            "scheme:path space",
            "scheme://host/path space",
            "scheme://host/path space?query space#fragment space",
            "scheme://user space:pass space@host/",
            "unsafe\"<>%{}\\|^~[]`##",
            "http://example.com/unsafe\"<>%{}\\|^~[]`##",
            "mailto:\"Your Name\" <you@example.com>",
            "[This is not a valid URL without encoding.]",
            "Encoding a relative path! 😎",
        ]
        for urlString in urlStrings {
            var url = URL(string: urlString, encodingInvalidCharacters: true)
            XCTAssertNotNil(url, "Expected a percent-encoded url for string \(urlString)")
            url = URL(string: urlString, encodingInvalidCharacters: false)
            XCTAssertNil(url, "Expected to fail strict url parsing for string \(urlString)")
        }
    }

    func testURLAppendingPathDoesNotEncodeColon() throws {
        let baseURL = URL(string: "file:///var/mobile/")!
        let url = URL(string: "relative", relativeTo: baseURL)!
        let component = "no:slash"
        let slashComponent = "/with:slash"

        // Make sure we don't encode ":" since `component` is not the first path segment
        var appended = url.appending(path: component, directoryHint: .notDirectory)
        XCTAssertEqual(appended.absoluteString, "file:///var/mobile/relative/no:slash")
        XCTAssertEqual(appended.relativePath, "relative/no:slash")

        appended = url.appending(path: slashComponent, directoryHint: .notDirectory)
        XCTAssertEqual(appended.absoluteString, "file:///var/mobile/relative/with:slash")
        XCTAssertEqual(appended.relativePath, "relative/with:slash")

        appended = url.appending(component: component, directoryHint: .notDirectory)
        XCTAssertEqual(appended.absoluteString, "file:///var/mobile/relative/no:slash")
        XCTAssertEqual(appended.relativePath, "relative/no:slash")

        // .appending(component:) should explicitly treat slashComponent as a single
        // path component, meaning "/" should be encoded to "%2F" before appending.
        // However, the old behavior didn't do this for file URLs, so we maintain the
        // old behavior to prevent breakage.
        appended = url.appending(component: slashComponent, directoryHint: .notDirectory)
        XCTAssertEqual(appended.absoluteString, "file:///var/mobile/relative/with:slash")
        XCTAssertEqual(appended.relativePath, "relative/with:slash")

        appended = url.appendingPathComponent(component, isDirectory: false)
        XCTAssertEqual(appended.absoluteString, "file:///var/mobile/relative/no:slash")
        XCTAssertEqual(appended.relativePath, "relative/no:slash")

        // Test deprecated API, which acts like `appending(path:)`
        appended = url.appendingPathComponent(slashComponent, isDirectory: false)
        XCTAssertEqual(appended.absoluteString, "file:///var/mobile/relative/with:slash")
        XCTAssertEqual(appended.relativePath, "relative/with:slash")
    }

    func testURLDeletingLastPathComponent() throws {
        var absolute = URL(filePath: "/absolute/path", directoryHint: .notDirectory)
        // Note: .relativePath strips the trailing slash for compatibility
        XCTAssertEqual(absolute.relativePath, "/absolute/path")
        XCTAssertFalse(absolute.hasDirectoryPath)

        absolute.deleteLastPathComponent()
        XCTAssertEqual(absolute.relativePath, "/absolute")
        XCTAssertTrue(absolute.hasDirectoryPath)

        absolute.deleteLastPathComponent()
        XCTAssertEqual(absolute.relativePath, "/")
        XCTAssertTrue(absolute.hasDirectoryPath)

        // The old .deleteLastPathComponent() implementation appends ".." to the
        // root directory "/", resulting in "/../". This resolves back to "/".
        // The new implementation simply leaves "/" as-is.
        absolute.deleteLastPathComponent()
        checkBehavior(absolute.relativePath, new: "/", old: "/..")
        XCTAssertTrue(absolute.hasDirectoryPath)

        absolute.append(path: "absolute", directoryHint: .isDirectory)
        checkBehavior(absolute.path, new: "/absolute", old: "/../absolute")

        // Reset `var absolute` to "/absolute" to prevent having
        // a "/../" prefix in all the old expectations.
        absolute = URL(filePath: "/absolute", directoryHint: .isDirectory)

        var relative = URL(filePath: "relative/path", directoryHint: .notDirectory, relativeTo: absolute)
        XCTAssertEqual(relative.relativePath, "relative/path")
        XCTAssertFalse(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute/relative/path")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "relative")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute/relative")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, ".")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "..")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "../..")
        XCTAssertTrue(relative.hasDirectoryPath)
        checkBehavior(relative.path, new:"/", old: "/..")

        relative.append(path: "path", directoryHint: .isDirectory)
        XCTAssertEqual(relative.relativePath, "../../path")
        XCTAssertTrue(relative.hasDirectoryPath)
        checkBehavior(relative.path, new: "/path", old: "/../path")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "../..")
        XCTAssertTrue(relative.hasDirectoryPath)
        checkBehavior(relative.path, new: "/", old: "/..")

        relative = URL(filePath: "", relativeTo: absolute)
        XCTAssertEqual(relative.relativePath, ".")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "..")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "../..")
        XCTAssertTrue(relative.hasDirectoryPath)
        checkBehavior(relative.path, new: "/", old: "/..")

        relative = URL(filePath: "relative/./", relativeTo: absolute)
        // According to RFC 3986, "." and ".." segments should not be removed
        // until the path is resolved against the base URL (when calling .path)
        checkBehavior(relative.relativePath, new: "relative/.", old: "relative")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute/relative")

        relative.deleteLastPathComponent()
        checkBehavior(relative.relativePath, new: "relative/..", old: ".")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute")

        relative = URL(filePath: "relative/.", directoryHint: .isDirectory, relativeTo: absolute)
        checkBehavior(relative.relativePath, new: "relative/.", old: "relative")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute/relative")

        relative.deleteLastPathComponent()
        checkBehavior(relative.relativePath, new: "relative/..", old: ".")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute")

        relative = URL(filePath: "relative/..", relativeTo: absolute)
        XCTAssertEqual(relative.relativePath, "relative/..")
        checkBehavior(relative.hasDirectoryPath, new: true, old: false)
        XCTAssertEqual(relative.path, "/absolute")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "relative/../..")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/")

        relative = URL(filePath: "relative/..", directoryHint: .isDirectory, relativeTo: absolute)
        XCTAssertEqual(relative.relativePath, "relative/..")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/absolute")

        relative.deleteLastPathComponent()
        XCTAssertEqual(relative.relativePath, "relative/../..")
        XCTAssertTrue(relative.hasDirectoryPath)
        XCTAssertEqual(relative.path, "/")

        var url = try XCTUnwrap(URL(string: "scheme://host.with.no.path"))
        XCTAssertTrue(url.path().isEmpty)

        url.deleteLastPathComponent()
        XCTAssertEqual(url.absoluteString, "scheme://host.with.no.path")
        XCTAssertTrue(url.path().isEmpty)

        let unusedBase = URL(string: "base://url")
        url = try XCTUnwrap(URL(string: "scheme://host.with.no.path", relativeTo: unusedBase))
        XCTAssertEqual(url.absoluteString, "scheme://host.with.no.path")
        XCTAssertTrue(url.path().isEmpty)

        url.deleteLastPathComponent()
        XCTAssertEqual(url.absoluteString, "scheme://host.with.no.path")
        XCTAssertTrue(url.path().isEmpty)

        var schemeRelative = try XCTUnwrap(URL(string: "scheme:relative/path"))
        // Bug in the old implementation where a relative path is not recognized
        checkBehavior(schemeRelative.relativePath, new: "relative/path", old: "")

        schemeRelative.deleteLastPathComponent()
        checkBehavior(schemeRelative.relativePath, new: "relative", old: "")

        schemeRelative.deleteLastPathComponent()
        XCTAssertEqual(schemeRelative.relativePath, "")

        schemeRelative.deleteLastPathComponent()
        XCTAssertEqual(schemeRelative.relativePath, "")
    }

    func testURLFilePathDropsTrailingSlashes() throws {
        var url = URL(filePath: "/path/slashes///")
        XCTAssertEqual(url.path(), "/path/slashes///")
        // TODO: Update this once .fileSystemPath uses backslashes for Windows
        XCTAssertEqual(url.fileSystemPath(), "/path/slashes")

        url = URL(filePath: "/path/slashes/")
        XCTAssertEqual(url.path(), "/path/slashes/")
        XCTAssertEqual(url.fileSystemPath(), "/path/slashes")

        url = URL(filePath: "/path/slashes")
        XCTAssertEqual(url.path(), "/path/slashes")
        XCTAssertEqual(url.fileSystemPath(), "/path/slashes")
    }

    func testURLNotDirectoryHintStripsTrailingSlash() throws {
        // Supply a path with a trailing slash but say it's not a direcotry
        var url = URL(filePath: "/path/", directoryHint: .notDirectory)
        XCTAssertFalse(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/path")

        url = URL(fileURLWithPath: "/path/", isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/path")

        url = URL(filePath: "/path///", directoryHint: .notDirectory)
        XCTAssertFalse(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/path")

        url = URL(fileURLWithPath: "/path///", isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/path")

        // With .checkFileSystem, don't modify the path for a non-existent file
        url = URL(filePath: "/my/non/existent/path/", directoryHint: .checkFileSystem)
        XCTAssertTrue(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/my/non/existent/path/")

        url = URL(fileURLWithPath: "/my/non/existent/path/")
        XCTAssertTrue(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/my/non/existent/path/")

        url = URL(filePath: "/my/non/existent/path", directoryHint: .checkFileSystem)
        XCTAssertFalse(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/my/non/existent/path")

        url = URL(fileURLWithPath: "/my/non/existent/path")
        XCTAssertFalse(url.hasDirectoryPath)
        XCTAssertEqual(url.path(), "/my/non/existent/path")
    }

    func testURLHostRetainsIDNAEncoding() throws {
        let url = URL(string: "ftp://user:password@*.xn--poema-9qae5a.com.br:4343/cat.txt")!
        XCTAssertEqual(url.host, "*.xn--poema-9qae5a.com.br")
    }

    func testURLHostIPLiteralCompatibility() throws {
        var url = URL(string: "http://[::]")!
        XCTAssertEqual(url.host, "::")
        XCTAssertEqual(url.host(), "::")

        url = URL(string: "https://[::1]:433/")!
        XCTAssertEqual(url.host, "::1")
        XCTAssertEqual(url.host(), "::1")

        url = URL(string: "https://[2001:db8::]/")!
        XCTAssertEqual(url.host, "2001:db8::")
        XCTAssertEqual(url.host(), "2001:db8::")

        url = URL(string: "https://[2001:db8::]:433")!
        XCTAssertEqual(url.host, "2001:db8::")
        XCTAssertEqual(url.host(), "2001:db8::")

        url = URL(string: "http://[fe80::a%25en1]")!
        XCTAssertEqual(url.absoluteString, "http://[fe80::a%25en1]")
        XCTAssertEqual(url.host, "fe80::a%en1")
        XCTAssertEqual(url.host(percentEncoded: true), "fe80::a%25en1")
        XCTAssertEqual(url.host(percentEncoded: false), "fe80::a%en1")

        url = URL(string: "http://[fe80::a%en1]")!
        XCTAssertEqual(url.absoluteString, "http://[fe80::a%25en1]")
        XCTAssertEqual(url.host, "fe80::a%en1")
        XCTAssertEqual(url.host(percentEncoded: true), "fe80::a%25en1")
        XCTAssertEqual(url.host(percentEncoded: false), "fe80::a%en1")

        url = URL(string: "http://[fe80::a%100%CustomZone]")!
        XCTAssertEqual(url.absoluteString, "http://[fe80::a%25100%25CustomZone]")
        XCTAssertEqual(url.host, "fe80::a%100%CustomZone")
        XCTAssertEqual(url.host(percentEncoded: true), "fe80::a%25100%25CustomZone")
        XCTAssertEqual(url.host(percentEncoded: false), "fe80::a%100%CustomZone")

        // Make sure an IP-literal with invalid characters `{` and `}`
        // returns `nil` even if we can percent-encode the zone-ID.
        let invalid = URL(string: "http://[{Invalid}%100%EncodableZone]")
        XCTAssertNil(invalid)
    }

    #if !os(Windows)
    func testURLTildeFilePath() throws {
        func urlIsAbsolute(_ url: URL) -> Bool {
            if url.relativePath.utf8.first == ._slash {
                return true
            }
            guard url.baseURL != nil else {
                return false
            }
            return url.path.utf8.first == ._slash
        }

        // "~" must either be expanded to an absolute path or resolved against a base URL
        var url = URL(filePath: "~")
        XCTAssertTrue(urlIsAbsolute(url))

        url = URL(filePath: "~", directoryHint: .isDirectory)
        XCTAssertTrue(urlIsAbsolute(url))
        XCTAssertEqual(url.path().utf8.last, ._slash)

        url = URL(filePath: "~/")
        XCTAssertTrue(urlIsAbsolute(url))
        XCTAssertEqual(url.path().utf8.last, ._slash)
    }
    #endif // !os(Windows)

    func testURLPathExtensions() throws {
        var url = URL(filePath: "/path", directoryHint: .notDirectory)
        url.appendPathExtension("foo")
        XCTAssertEqual(url.path(), "/path.foo")
        url.deletePathExtension()
        XCTAssertEqual(url.path(), "/path")

        url = URL(filePath: "/path", directoryHint: .isDirectory)
        url.appendPathExtension("foo")
        XCTAssertEqual(url.path(), "/path.foo/")
        url.deletePathExtension()
        XCTAssertEqual(url.path(), "/path/")

        url = URL(filePath: "/path/", directoryHint: .inferFromPath)
        url.appendPathExtension("foo")
        XCTAssertEqual(url.path(), "/path.foo/")
        url.append(path: "/////")
        url.deletePathExtension()
        // Old behavior only searches the last empty component, so the extension isn't actually removed
        checkBehavior(url.path(), new: "/path/", old: "/path.foo///")

        url = URL(filePath: "/tmp/x")
        url.appendPathExtension("")
        XCTAssertEqual(url.path(), "/tmp/x")
        XCTAssertEqual(url, url.deletingPathExtension().appendingPathExtension(url.pathExtension))

        url = URL(filePath: "/tmp/x.")
        url.deletePathExtension()
        XCTAssertEqual(url.path(), "/tmp/x.")
    }

    func testURLAppendingToEmptyPath() throws {
        let baseURL = URL(filePath: "/base/directory", directoryHint: .isDirectory)
        let emptyPathURL = URL(filePath: "", relativeTo: baseURL)
        let url = emptyPathURL.appending(path: "main.swift")
        XCTAssertEqual(url.relativePath, "./main.swift")
        XCTAssertEqual(url.path, "/base/directory/main.swift")

        var example = try XCTUnwrap(URL(string: "https://example.com"))
        XCTAssertEqual(example.host(), "example.com")
        XCTAssertTrue(example.path().isEmpty)

        // Appending to an empty path should add a slash if an authority exists
        // The appended path should never become part of the host
        example.append(path: "foo")
        XCTAssertEqual(example.host(), "example.com")
        XCTAssertEqual(example.path(), "/foo")
        XCTAssertEqual(example.absoluteString, "https://example.com/foo")

        // Maintain old behavior, where appending an empty path
        // to an empty host does not add a slash, but appending
        // an empty path to a non-empty host does
        example = try XCTUnwrap(URL(string: "https://example.com"))
        example.append(path: "")
        XCTAssertEqual(example.host(), "example.com")
        XCTAssertEqual(example.path(), "/")
        XCTAssertEqual(example.absoluteString, "https://example.com/")

        var emptyHost = try XCTUnwrap(URL(string: "scheme://"))
        XCTAssertNil(emptyHost.host())
        XCTAssertTrue(emptyHost.path().isEmpty)

        emptyHost.append(path: "")
        XCTAssertNil(emptyHost.host())
        XCTAssertTrue(emptyHost.path().isEmpty)

        emptyHost.append(path: "foo")
        XCTAssertTrue(emptyHost.host()?.isEmpty ?? true)
        // Old behavior failed to append correctly to an empty host
        // Modern parsers agree that "foo" relative to "scheme://" is "scheme:///foo"
        checkBehavior(emptyHost.path(), new: "/foo", old: "")
        checkBehavior(emptyHost.absoluteString, new: "scheme:///foo", old: "scheme://")

        var schemeOnly = try XCTUnwrap(URL(string: "scheme:"))
        XCTAssertTrue(schemeOnly.host()?.isEmpty ?? true)
        XCTAssertTrue(schemeOnly.path().isEmpty)

        schemeOnly.append(path: "foo")
        XCTAssertTrue(schemeOnly.host()?.isEmpty ?? true)
        // Old behavior appends to the string, but is missing the path
        checkBehavior(schemeOnly.path(), new: "foo", old: "")
        XCTAssertEqual(schemeOnly.absoluteString, "scheme:foo")
    }

    func testURLEmptySchemeCompatibility() throws {
        var url = try XCTUnwrap(URL(string: ":memory:"))
        XCTAssertEqual(url.scheme, "")

        let base = try XCTUnwrap(URL(string: "://home"))
        XCTAssertEqual(base.host(), "home")

        url = try XCTUnwrap(URL(string: "/path", relativeTo: base))
        XCTAssertEqual(url.scheme, "")
        XCTAssertEqual(url.host(), "home")
        XCTAssertEqual(url.path, "/path")
        XCTAssertEqual(url.absoluteString, "://home/path")
        XCTAssertEqual(url.absoluteURL.scheme, "")
    }

    func testURLComponentsPercentEncodedUnencodedProperties() throws {
        var comp = URLComponents()

        comp.user = "%25"
        XCTAssertEqual(comp.user, "%25")
        XCTAssertEqual(comp.percentEncodedUser, "%2525")

        comp.password = "%25"
        XCTAssertEqual(comp.password, "%25")
        XCTAssertEqual(comp.percentEncodedPassword, "%2525")

        // Host behavior differs since the addition of IDNA-encoding
        comp.host = "%25"
        XCTAssertEqual(comp.host, "%")
        XCTAssertEqual(comp.percentEncodedHost, "%25")

        comp.path = "%25"
        XCTAssertEqual(comp.path, "%25")
        XCTAssertEqual(comp.percentEncodedPath, "%2525")

        comp.query = "%25"
        XCTAssertEqual(comp.query, "%25")
        XCTAssertEqual(comp.percentEncodedQuery, "%2525")

        comp.fragment = "%25"
        XCTAssertEqual(comp.fragment, "%25")
        XCTAssertEqual(comp.percentEncodedFragment, "%2525")

        comp.queryItems = [URLQueryItem(name: "name", value: "a%25b")]
        XCTAssertEqual(comp.queryItems, [URLQueryItem(name: "name", value: "a%25b")])
        XCTAssertEqual(comp.percentEncodedQueryItems, [URLQueryItem(name: "name", value: "a%2525b")])
        XCTAssertEqual(comp.query, "name=a%25b")
        XCTAssertEqual(comp.percentEncodedQuery, "name=a%2525b")
    }

    func testURLPercentEncodedProperties() throws {
        var url = URL(string: "https://%3Auser:%3Apassword@%3A.com/%3Apath?%3Aquery=%3A#%3Afragment")!

        XCTAssertEqual(url.user(), "%3Auser")
        XCTAssertEqual(url.user(percentEncoded: false), ":user")

        XCTAssertEqual(url.password(), "%3Apassword")
        XCTAssertEqual(url.password(percentEncoded: false), ":password")

        XCTAssertEqual(url.host(), "%3A.com")
        XCTAssertEqual(url.host(percentEncoded: false), ":.com")

        XCTAssertEqual(url.path(), "/%3Apath")
        XCTAssertEqual(url.path(percentEncoded: false), "/:path")

        XCTAssertEqual(url.query(), "%3Aquery=%3A")
        XCTAssertEqual(url.query(percentEncoded: false), ":query=:")

        XCTAssertEqual(url.fragment(), "%3Afragment")
        XCTAssertEqual(url.fragment(percentEncoded: false), ":fragment")

        // Lowercase input
        url = URL(string: "https://%3auser:%3apassword@%3a.com/%3apath?%3aquery=%3a#%3afragment")!

        XCTAssertEqual(url.user(), "%3auser")
        XCTAssertEqual(url.user(percentEncoded: false), ":user")

        XCTAssertEqual(url.password(), "%3apassword")
        XCTAssertEqual(url.password(percentEncoded: false), ":password")

        XCTAssertEqual(url.host(), "%3a.com")
        XCTAssertEqual(url.host(percentEncoded: false), ":.com")

        XCTAssertEqual(url.path(), "/%3apath")
        XCTAssertEqual(url.path(percentEncoded: false), "/:path")

        XCTAssertEqual(url.query(), "%3aquery=%3a")
        XCTAssertEqual(url.query(percentEncoded: false), ":query=:")

        XCTAssertEqual(url.fragment(), "%3afragment")
        XCTAssertEqual(url.fragment(percentEncoded: false), ":fragment")
    }

    func testURLComponentsUppercasePercentEncoding() throws {
        // Always use uppercase percent-encoding when unencoded components are assigned
        var comp = URLComponents()
        comp.scheme = "https"
        comp.user = "?user"
        comp.password = "?password"
        comp.path = "?path"
        comp.query = "#query"
        comp.fragment = "#fragment"
        XCTAssertEqual(comp.percentEncodedUser, "%3Fuser")
        XCTAssertEqual(comp.percentEncodedPassword, "%3Fpassword")
        XCTAssertEqual(comp.percentEncodedPath, "%3Fpath")
        XCTAssertEqual(comp.percentEncodedQuery, "%23query")
        XCTAssertEqual(comp.percentEncodedFragment, "%23fragment")
    }

    func testURLComponentsRangeCombinations() throws {
        // This brute forces many combinations and takes a long time.
        // Skip this for automated testing purposes and test manually when needed.
        try XCTSkipIf(true)

        let schemes = [nil, "a", "aa"]
        let users = [nil, "b", "bb"]
        let passwords = [nil, "c", "cc"]
        let hosts = [nil, "d", "dd"]
        let ports = [nil, 80, 433]
        let paths = ["", "/e", "/e/e"]
        let queries = [nil, "f=f", "hh=hh"]
        let fragments = [nil, "j", "jj"]

        func forAll(_ block: (String?, String?, String?, String?, Int?, String, String?, String?) throws -> ()) rethrows {
            for scheme in schemes {
                for user in users {
                    for password in passwords {
                        for host in hosts {
                            for port in ports {
                                for path in paths {
                                    for query in queries {
                                        for fragment in fragments {
                                            try block(scheme, user, password, host, port, path, query, fragment)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        func validateRanges(_ comp: URLComponents, scheme: String?, user: String?, password: String?, host: String?, port: Int?, path: String, query: String?, fragment: String?) throws {
            let string = try XCTUnwrap(comp.string)
            if let scheme {
                let range = try XCTUnwrap(comp.rangeOfScheme)
                XCTAssertTrue(string[range] == scheme)
            } else {
                XCTAssertNil(comp.rangeOfScheme)
            }
            if let user {
                let range = try XCTUnwrap(comp.rangeOfUser)
                XCTAssertTrue(string[range] == user)
            } else {
                // Even if we set comp.user = nil, a non-nil password
                // implies that user exists as the empty string.
                let isEmptyUserWithPassword = (
                    comp.user?.isEmpty ?? false &&
                    comp.rangeOfUser?.isEmpty ?? false &&
                    comp.password != nil
                )
                XCTAssertTrue(comp.rangeOfUser == nil || isEmptyUserWithPassword)
            }
            if let password {
                let range = try XCTUnwrap(comp.rangeOfPassword)
                XCTAssertTrue(string[range] == password)
            } else {
                XCTAssertNil(comp.rangeOfPassword)
            }
            if let host {
                let range = try XCTUnwrap(comp.rangeOfHost)
                XCTAssertTrue(string[range] == host)
            } else {
                // Even if we set comp.host = nil, any non-nil authority component
                // implies that host exists as the empty string.
                let isEmptyHostWithAuthorityComponent = (
                    comp.host?.isEmpty ?? false &&
                    comp.rangeOfHost?.isEmpty ?? false &&
                    (user != nil || password != nil || port != nil)
                )
                XCTAssertTrue(comp.rangeOfHost == nil || isEmptyHostWithAuthorityComponent)
            }
            if let port {
                let range = try XCTUnwrap(comp.rangeOfPort)
                XCTAssertTrue(string[range] == String(port))
            } else {
                XCTAssertNil(comp.rangeOfPort)
            }
            // rangeOfPath should never be nil.
            let pathRange = try XCTUnwrap(comp.rangeOfPath)
            XCTAssertTrue(string[pathRange] == path)
            if let query {
                let range = try XCTUnwrap(comp.rangeOfQuery)
                XCTAssertTrue(string[range] == query)
            } else {
                XCTAssertNil(comp.rangeOfQuery)
            }
            if let fragment {
                let range = try XCTUnwrap(comp.rangeOfFragment)
                XCTAssertTrue(string[range] == fragment)
            } else {
                XCTAssertNil(comp.rangeOfFragment)
            }
        }

        try forAll { scheme, user, password, host, port, path, query, fragment in

            // Assign all components then get the ranges

            var comp = URLComponents()
            comp.scheme = scheme
            comp.user = user
            comp.password = password
            comp.host = host
            comp.port = port
            comp.path = path
            comp.query = query
            comp.fragment = fragment
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            let string = try XCTUnwrap(comp.string)
            let fullComponents = URLComponents(string: string)!

            // Get the ranges directly from URLParseInfo

            comp = fullComponents
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            // Set components after parsing, which invalidates the URLParseInfo ranges

            comp = fullComponents
            comp.scheme = scheme
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.user = user
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.password = password
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.host = host
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.port = port
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.path = path
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.query = query
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.fragment = fragment
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            // Remove components from the string, set them back, and validate ranges

            comp = fullComponents
            comp.scheme = nil
            try validateRanges(comp, scheme: nil, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            let stringWithoutScheme = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutScheme)!
            comp.scheme = scheme
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            var expectedHost = host
            if user != nil && host == nil {
                // We parsed a string with a non-nil user, so expect host to
                // be the empty string, even after we set comp.user = nil.
                expectedHost = ""
            }
            comp.user = nil
            try validateRanges(comp, scheme: scheme, user: nil, password: password, host: expectedHost, port: port, path: path, query: query, fragment: fragment)

            let stringWithoutUser = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutUser)!
            comp.user = user
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            var expectedUser = user
            if password != nil && user == nil {
                // We parsed a string with a non-nil password, so expect user to
                // be the empty string, even after we set comp.password = nil.
                expectedUser = ""
            }
            comp.password = nil
            try validateRanges(comp, scheme: scheme, user: expectedUser, password: nil, host: host, port: port, path: path, query: query, fragment: fragment)

            let stringWithoutPassword = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutPassword)!
            comp.password = password
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.host = nil
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: nil, port: port, path: path, query: query, fragment: fragment)

            let stringWithoutHost = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutHost)!
            comp.host = host
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            expectedHost = host
            if port != nil && host == nil {
                // We parsed a string with a non-nil port, so expect host to
                // be the empty string, even after we set comp.port = nil.
                expectedHost = ""
            }
            comp.port = nil
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: expectedHost, port: nil, path: path, query: query, fragment: fragment)

            let stringWithoutPort = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutPort)!
            comp.port = port
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.path = ""
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: "", query: query, fragment: fragment)

            let stringWithoutPath = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutPath)!
            comp.path = path
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.query = nil
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: nil, fragment: fragment)

            let stringWithoutQuery = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutQuery)!
            comp.query = query
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)

            comp = fullComponents
            comp.fragment = nil
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: nil)

            let stringWithoutFragment = try XCTUnwrap(comp.string)
            comp = URLComponents(string: stringWithoutFragment)!
            comp.fragment = fragment
            try validateRanges(comp, scheme: scheme, user: user, password: password, host: host, port: port, path: path, query: query, fragment: fragment)
        }
    }

    func testURLComponentsEncodesFirstPathColon() throws {
        let path = "first:segment:with:colons/second:segment:with:colons"
        var comp = URLComponents()
        comp.path = path
        guard let compString = comp.string else {
            XCTFail("compString was nil")
            return
        }
        guard let slashIndex = compString.firstIndex(of: "/") else {
            XCTFail("Could not find slashIndex")
            return
        }
        let firstSegment = compString[..<slashIndex]
        let secondSegment = compString[slashIndex...]
        XCTAssertNil(firstSegment.firstIndex(of: ":"), "There should not be colons in the first path segment")
        XCTAssertNotNil(secondSegment.firstIndex(of: ":"), "Colons should be allowed in subsequent path segments")

        comp = URLComponents()
        comp.path = path
        guard let compString2 = comp.string else {
            XCTFail("compString2 was nil")
            return
        }
        guard let slashIndex2 = compString2.firstIndex(of: "/") else {
            XCTFail("Could not find slashIndex2")
            return
        }
        let firstSegment2 = compString2[..<slashIndex2]
        let secondSegment2 = compString2[slashIndex2...]
        XCTAssertNil(firstSegment2.firstIndex(of: ":"), "There should not be colons in the first path segment")
        XCTAssertNotNil(secondSegment2.firstIndex(of: ":"), "Colons should be allowed in subsequent path segments")

        // Colons are allowed in the first segment if there is a scheme.

        let colonFirstPath = "playlist:37i9dQZF1E35u89RYOJJV6"
        let legalURLString = "spotify:\(colonFirstPath)"
        comp = try XCTUnwrap(URLComponents(string: legalURLString))
        XCTAssertEqual(comp.string, legalURLString)
        XCTAssertEqual(comp.percentEncodedPath, colonFirstPath)

        // Colons should be percent-encoded by URLComponents.string if
        // they could be misinterpreted as a scheme separator.

        comp = URLComponents()
        comp.percentEncodedPath = "not%20a%20scheme:"
        XCTAssertEqual(comp.string, "not%20a%20scheme%3A")

        // These would fail if we did not percent-encode the colon.
        // .string should always produce a valid URL string, or nil.

        XCTAssertNotNil(URL(string: comp.string!))
        XCTAssertNotNil(URLComponents(string: comp.string!))

        // In rare cases, an app might rely on URL allowing an empty scheme,
        // but then take that string and pass it to URLComponents to modify
        // other components of the URL. We shouldn't percent-encode the colon
        // in these cases.

        let url = try XCTUnwrap(URL(string: "://host/path"))
        comp = try XCTUnwrap(URLComponents(string: url.absoluteString))
        comp.query = "key=value"
        XCTAssertEqual(comp.string, "://host/path?key=value")
    }

    func testURLComponentsInvalidPaths() {
        var comp = URLComponents()

        // Path must start with a slash if there's an authority component.
        comp.path = "does/not/start/with/slash"
        XCTAssertNotNil(comp.string)

        comp.user = "user"
        XCTAssertNil(comp.string)
        comp.user = nil

        comp.password = "password"
        XCTAssertNil(comp.string)
        comp.password = nil

        comp.host = "example.com"
        XCTAssertNil(comp.string)
        comp.host = nil

        comp.port = 80
        XCTAssertNil(comp.string)
        comp.port = nil

        comp = URLComponents()

        // If there's no authority, path cannot start with "//".
        comp.path = "//starts/with/two/slashes"
        XCTAssertNil(comp.string)

        // If there's an authority, it's okay.
        comp.user = "user"
        XCTAssertNotNil(comp.string)
        comp.user = nil

        comp.password = "password"
        XCTAssertNotNil(comp.string)
        comp.password = nil

        comp.host = "example.com"
        XCTAssertNotNil(comp.string)
        comp.host = nil

        comp.port = 80
        XCTAssertNotNil(comp.string)
        comp.port = nil
    }

    func testURLComponentsAllowsEqualSignInQueryItemValue() {
        var comp = URLComponents(string: "http://example.com/path?item=value==&q==val")!
        var expected = [URLQueryItem(name: "item", value: "value=="), URLQueryItem(name: "q", value: "=val")]
        XCTAssertEqual(comp.percentEncodedQueryItems, expected)
        XCTAssertEqual(comp.queryItems, expected)

        expected = [URLQueryItem(name: "new", value: "=value="), URLQueryItem(name: "name", value: "=")]
        comp.percentEncodedQueryItems = expected
        XCTAssertEqual(comp.percentEncodedQueryItems, expected)
        XCTAssertEqual(comp.queryItems, expected)
    }

    func testURLComponentsLookalikeIPLiteral() {
        // We should consider a lookalike IP literal invalid (note accent on the first bracket)
        let fakeIPLiteral = "[́::1]"
        let fakeURLString = "http://\(fakeIPLiteral):80/"

        let comp = URLComponents(string: fakeURLString)
        XCTAssertNil(comp)

        var comp2 = URLComponents()
        comp2.host = fakeIPLiteral
        XCTAssertNil(comp2.string)
    }

    func testURLComponentsDecodingNULL() {
        let comp = URLComponents(string: "http://example.com/my\u{0}path")!
        XCTAssertEqual(comp.percentEncodedPath, "/my%00path")
        XCTAssertEqual(comp.path, "/my\u{0}path")
    }

    func testURLStandardizedEmptyString() {
        let url = URL(string: "../../../")!
        let standardized = url.standardized
        XCTAssertTrue(standardized.path().isEmpty)
    }

#if FOUNDATION_FRAMEWORK
    func testURLComponentsBridging() {
        var nsURLComponents = NSURLComponents(
            string: "https://example.com?url=https%3A%2F%2Fapple.com"
        )!
        var urlComponents = nsURLComponents as URLComponents
        XCTAssertEqual(urlComponents.string, nsURLComponents.string)

        urlComponents = URLComponents(
            string: "https://example.com?url=https%3A%2F%2Fapple.com"
        )!
        nsURLComponents = urlComponents as NSURLComponents
        XCTAssertEqual(urlComponents.string, nsURLComponents.string)
    }
#endif

    func testURLComponentsUnixDomainSocketOverHTTPScheme() {
        var comp = URLComponents()
        comp.scheme = "http+unix"
        comp.host = "/path/to/socket"
        comp.path = "/info"
        XCTAssertEqual(comp.string, "http+unix://%2Fpath%2Fto%2Fsocket/info")

        comp.scheme = "https+unix"
        XCTAssertEqual(comp.string, "https+unix://%2Fpath%2Fto%2Fsocket/info")

        comp.encodedHost = "%2Fpath%2Fto%2Fsocket"
        XCTAssertEqual(comp.string, "https+unix://%2Fpath%2Fto%2Fsocket/info")
        XCTAssertEqual(comp.encodedHost, "%2Fpath%2Fto%2Fsocket")
        XCTAssertEqual(comp.host, "/path/to/socket")
        XCTAssertEqual(comp.path, "/info")

        // "/path/to/socket" is not a valid host for schemes
        // that IDNA-encode hosts instead of percent-encoding
        comp.scheme = "http"
        XCTAssertNil(comp.string)

        comp.scheme = "https"
        XCTAssertNil(comp.string)

        comp.scheme = "https+unix"
        XCTAssertEqual(comp.string, "https+unix://%2Fpath%2Fto%2Fsocket/info")

        // Check that we can parse a percent-encoded http+unix URL string
        comp = URLComponents(string: "http+unix://%2Fpath%2Fto%2Fsocket/info")!
        XCTAssertEqual(comp.encodedHost, "%2Fpath%2Fto%2Fsocket")
        XCTAssertEqual(comp.host, "/path/to/socket")
        XCTAssertEqual(comp.path, "/info")
    }

    func testURLComponentsUnixDomainSocketOverWebSocketScheme() {
        var comp = URLComponents()
        comp.scheme = "ws+unix"
        comp.host = "/path/to/socket"
        comp.path = "/info"
        XCTAssertEqual(comp.string, "ws+unix://%2Fpath%2Fto%2Fsocket/info")

        comp.scheme = "wss+unix"
        XCTAssertEqual(comp.string, "wss+unix://%2Fpath%2Fto%2Fsocket/info")

        comp.encodedHost = "%2Fpath%2Fto%2Fsocket"
        XCTAssertEqual(comp.string, "wss+unix://%2Fpath%2Fto%2Fsocket/info")
        XCTAssertEqual(comp.encodedHost, "%2Fpath%2Fto%2Fsocket")
        XCTAssertEqual(comp.host, "/path/to/socket")
        XCTAssertEqual(comp.path, "/info")

        // "/path/to/socket" is not a valid host for schemes
        // that IDNA-encode hosts instead of percent-encoding
        comp.scheme = "ws"
        XCTAssertNil(comp.string)

        comp.scheme = "wss"
        XCTAssertNil(comp.string)

        comp.scheme = "wss+unix"
        XCTAssertEqual(comp.string, "wss+unix://%2Fpath%2Fto%2Fsocket/info")

        // Check that we can parse a percent-encoded ws+unix URL string
        comp = URLComponents(string: "ws+unix://%2Fpath%2Fto%2Fsocket/info")!
        XCTAssertEqual(comp.encodedHost, "%2Fpath%2Fto%2Fsocket")
        XCTAssertEqual(comp.host, "/path/to/socket")
        XCTAssertEqual(comp.path, "/info")
    }
}
