////
///  ElloSpecHelpers.swift
//

@testable
import Ello
import Quick
import OHHTTPStubs
import Nimble_Snapshots

// Add in custom configuration
class ElloConfiguration: QuickConfiguration {
    override class func configure(config: Configuration) {
        config.beforeSuite {
            setNimbleTolerance(0.0001)
            ElloLinkedStore.databaseName = "ello_test.sqlite"
        }
        config.beforeEach {
            let keychain = FakeKeychain()
            keychain.username = "email"
            keychain.password = "password"
            keychain.authToken = "abcde"
            keychain.authTokenExpires = NSDate().dateByAddingTimeInterval(3600)
            keychain.authTokenType = "grant"
            keychain.refreshAuthToken = "abcde"
            keychain.isPasswordBased = true
            AuthToken.sharedKeychain = keychain

            ElloProvider.shared.authState = .Authenticated
            ElloProvider.shared.queue = nil
            ElloProvider.sharedProvider = ElloProvider.StubbingProvider()
        }
        config.afterEach {
            ElloProvider_Specs.errorStatusCode = .Status404
            let window = UIWindow()
            window.rootViewController = UIViewController()
            window.makeKeyAndVisible()
        }
        config.afterSuite {
            AuthToken.sharedKeychain = ElloKeychain()
            ElloLinkedStore.sharedInstance.writeConnection.readWriteWithBlock { transaction in
                transaction.removeAllObjectsInAllCollections()
            }
            ElloProvider.sharedProvider = ElloProvider.DefaultProvider()
        }
    }
}

func delay(duration: NSTimeInterval, block: () -> Void) {
    let killTimeOffset = Int64(CDouble(duration) * CDouble(NSEC_PER_SEC))
    let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
    dispatch_after(killTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
        block()
    }
}

func stubbedJSONData(file: String, _ propertyName: String) -> ([String:AnyObject]) {
    let loadedData:NSData = stubbedData(file)
    let json: AnyObject = try! NSJSONSerialization.JSONObjectWithData(loadedData, options: [])

    var castJSON = json as! [String: AnyObject]
    let parsedProperty = castJSON[propertyName] as! [String:AnyObject]
    if let linkedJSON = castJSON["linked"] as? [String:[[String:AnyObject]]] {
        ElloLinkedStore.sharedInstance.parseLinked(linkedJSON, completion: {})
    }

    return parsedProperty
}

func stubbedJSONDataArray(file: String, _ propertyName: String) -> [[String:AnyObject]] {
    let loadedData:NSData = stubbedData(file)
    let json: AnyObject = try! NSJSONSerialization.JSONObjectWithData(loadedData, options: [])

    var castJSON:[String:AnyObject] = json as! [String: AnyObject]
    let parsedProperty = castJSON[propertyName] as! [[String:AnyObject]]
    if let linkedJSON = castJSON["linked"] as? [String:[[String:AnyObject]]] {
        ElloLinkedStore.sharedInstance.parseLinked(linkedJSON, completion: {})
    }

    return parsedProperty
}

func supressRequestsTo(domain: String) {
    OHHTTPStubs.stubRequestsPassingTest({$0.URL!.host == domain}) { _ in
        return OHHTTPStubsResponse(data: NSData(),
            statusCode: 200, headers: ["Content-Type":"image/gif"])
    }
}
