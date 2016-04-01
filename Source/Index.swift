//
//  Copyright (c) 2015 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// Contains all the functions related to one index
///
/// You can use Client.getIndex(indexName) to retrieve this object
@objc public class Index : NSObject {
    @objc public let indexName: String
    @objc public let client: Client
    let urlEncodedIndexName: String
    
    var searchCache: ExpiringCache?
    
    @objc public init(client: Client, indexName: String) {
        self.client = client
        self.indexName = indexName
        urlEncodedIndexName = indexName.urlEncode()
    }
    
    /// Add an object in this index
    ///
    /// - parameter object: The object to add inside the index.
    @objc public func addObject(object: [String: AnyObject], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)"
        return client.performHTTPQuery(path, method: .POST, body: object, hostnames: client.writeHosts, block: block)
    }
    
    /// Add an object in this index
    ///
    /// - parameter object: The object to add inside the index.
    /// - parameter withID: An objectID you want to attribute to this object (if the attribute already exist, the old object will be overwrite)
    @objc public func addObject(object: [String: AnyObject], withID objectID: String, block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/\(objectID.urlEncode())"
        return client.performHTTPQuery(path, method: .PUT, body: object, hostnames: client.writeHosts, block: block)
    }
    
    /// Add several objects in this index
    ///
    /// - parameter objects: An array of objects to add (Array of Dictionnary object).
    @objc public func addObjects(objects: [AnyObject], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/batch"
        
        var requests = [AnyObject]()
        requests.reserveCapacity(objects.count)
        for object in objects {
            requests.append(["action": "addObject", "body": object])
        }
        let request = ["requests": requests]
        
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Delete an object from the index
    ///
    /// - parameter objectID: The unique identifier of object to delete
    @objc public func deleteObject(objectID: String, block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/\(objectID.urlEncode())"
        return client.performHTTPQuery(path, method: .DELETE, body: nil, hostnames: client.writeHosts, block: block)
    }
    
    /// Delete several objects
    ///
    /// - parameter objectIDs: An array of objectID to delete.
    @objc public func deleteObjects(objectIDs: [String], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/batch"
        
        var requests = [AnyObject]()
        requests.reserveCapacity(objectIDs.count)
        for id in objectIDs {
            requests.append(["action": "deleteObject", "objectID": id])
        }
        let request = ["requests": requests]
        
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Get an object from this index
    ///
    /// - parameter objectID: The unique identifier of the object to retrieve
    @objc public func getObject(objectID: String, block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/\(objectID.urlEncode())"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: block)
    }
    
    /// Get an object from this index
    ///
    /// - parameter objectID: The unique identifier of the object to retrieve
    /// - parameter attributesToRetrieve: The list of attributes to retrieve
    @objc public func getObject(objectID: String, attributesToRetrieve attributes: [String], block: CompletionHandler) -> NSOperation {
        let query = Query()
        query.attributesToRetrieve = attributes
        let path = "1/indexes/\(urlEncodedIndexName)/\(objectID.urlEncode())?\(query.build())"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: block)
    }
    
    /// Get several objects from this index
    ///
    /// - parameter objectIDs: The array of unique identifier of objects to retrieve
    @objc public func getObjects(objectIDs: [String], block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/*/objects"
        
        var requests = [AnyObject]()
        requests.reserveCapacity(objectIDs.count)
        for id in objectIDs {
            requests.append(["indexName": indexName, "objectID": id])
        }
        let request = ["requests": requests]
        
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.readHosts, block: block)
    }
    
    /// Update partially an object (only update attributes passed in argument)
    ///
    /// - parameter object: The object attributes to override, the object must contains an objectID attribute
    @objc public func partialUpdateObject(partialObject: [String: AnyObject], objectID: String, block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/\(objectID.urlEncode())/partial"
        return client.performHTTPQuery(path, method: .POST, body: partialObject, hostnames: client.writeHosts, block: block)
    }
    
    /// Update partially the content of several objects
    ///
    /// - parameter objects: An array of Dictionary to update (each Dictionary must contains an objectID attribute)
    @objc public func partialUpdateObjects(objects: [AnyObject], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/batch"
        
        var requests = [AnyObject]()
        requests.reserveCapacity(objects.count)
        for object in objects {
            if let object = object as? [String: AnyObject] {
                requests.append([
                    "action": "partialUpdateObject",
                    "objectID": object["objectID"] as! String,
                    "body": object
                    ])
            }
        }
        let request = ["requests": requests]
        
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Override the content of object
    ///
    /// - parameter object: The object to override, the object must contains an objectID attribute
    @objc public func saveObject(object: [String: AnyObject], block: CompletionHandler? = nil) -> NSOperation {
        let objectID = object["objectID"] as! String
        let path = "1/indexes/\(urlEncodedIndexName)/\(objectID.urlEncode())"
        return client.performHTTPQuery(path, method: .PUT, body: object, hostnames: client.writeHosts, block: block)
    }
    
    /// Override the content of several objects
    ///
    /// - parameter objects: An array of Dictionary to save (each Dictionary must contains an objectID attribute)
    @objc public func saveObjects(objects: [AnyObject], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/batch"
        
        var requests = [AnyObject]()
        requests.reserveCapacity(objects.count)
        for object in objects {
            if let object = object as? [String: AnyObject] {
                requests.append([
                    "action": "updateObject",
                    "objectID": object["objectID"] as! String,
                    "body": object
                    ])
            }
        }
        let request = ["requests": requests]
        
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Search inside the index
    @objc public func search(query: Query, block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/query"
        let request = ["params": query.build()]
        
        // First try the in-memory query cache.
        let cacheKey = "\(path)_body_\(request)"
        if let content = searchCache?.objectForKey(cacheKey) {
            // We *have* to return something, so we create a block operation.
            // Note that its execution will be deferred until the next iteration of the main run loop.
            let operation = NSBlockOperation() {
                block(content: content, error: nil)
            }
            NSOperationQueue.mainQueue().addOperation(operation)
            return operation
        }
        // Otherwise, run an online query.
        else {
            return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.readHosts, isSearchQuery: true) {
                (content, error) -> Void in
                assert(content != nil || error != nil)
                if content != nil {
                    self.searchCache?.setObject(content!, forKey: cacheKey)
                    block(content: content, error: error)
                } else {
                    block(content: content, error: error)
                }
            }
        }
    }
    
    /// Wait the publication of a task on the server.
    /// All server task are asynchronous and you can check with this method that the task is published.
    ///
    /// - parameter taskID: The ID of the task returned by server
    @objc public func waitTask(taskID: Int, block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/task/\(taskID)"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: { (content, error) -> Void in
            if let content = content {
                if (content["status"] as? String) == "published" {
                    block(content: content, error: nil)
                } else {
                    NSThread.sleepForTimeInterval(0.1)
                    self.waitTask(taskID, block: block)
                }
            } else {
                block(content: content, error: error)
            }
        })
    }
    
    /// Get settings of this index
    @objc public func getSettings(block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/settings"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: block)
    }
    
    /// Set settings for this index
    ///
    /// - parameter settings: The settings object
    ///
    /// NB: The settings object can contains :
    ///
    /// - minWordSizefor1Typo: (integer) the minimum number of characters to accept one typo (default = 3).
    /// - minWordSizefor2Typos: (integer) the minimum number of characters to accept two typos (default = 7).
    /// - hitsPerPage: (integer) the number of hits per page (default = 10).
    /// - attributesToRetrieve: (array of strings) default list of attributes to retrieve in objects. If set to null, all attributes are retrieved.
    /// - attributesToHighlight: (array of strings) default list of attributes to highlight. If set to null, all indexed attributes are highlighted.
    /// - attributesToSnippet: (array of strings) default list of attributes to snippet alongside the number of words to return (syntax is attributeName:nbWords). By default no snippet is computed. If set to null, no snippet is computed.
    /// - attributesToIndex: (array of strings) the list of fields you want to index. If set to null, all textual and numerical attributes of your objects are indexed, but you should update it to get optimal results. This parameter has two important uses:
    ///     - Limit the attributes to index: For example if you store a binary image in base64, you want to store it and be able to retrieve it but you don't want to search in the base64 string.
    ///     - Control part of the ranking*: (see the ranking parameter for full explanation) Matches in attributes at the beginning of the list will be considered more important than matches in attributes further down the list. In one attribute, matching text at the beginning of the attribute will be considered more important than text after, you can disable this behavior if you add your attribute inside `unordered(AttributeName)`, for example attributesToIndex: ["title", "unordered(text)"].
    /// - attributesForFaceting: (array of strings) The list of fields you want to use for faceting. All strings in the attribute selected for faceting are extracted and added as a facet. If set to null, no attribute is used for faceting.
    /// - ranking: (array of strings) controls the way results are sorted. We have six available criteria:
    ///     - typo: sort according to number of typos,
    ///     - geo: sort according to decreassing distance when performing a geo-location based search,
    ///     - proximity: sort according to the proximity of query words in hits,
    ///     - attribute: sort according to the order of attributes defined by attributesToIndex,
    ///     - exact: sort according to the number of words that are matched identical to query word (and not as a prefix),
    ///     - custom: sort according to a user defined formula set in customRanking attribute. The standard order is ["typo", "geo", "proximity", "attribute", "exact", "custom"]
    /// - customRanking: (array of strings) lets you specify part of the ranking. The syntax of this condition is an array of strings containing attributes prefixed by asc (ascending order) or desc (descending order) operator. For example `"customRanking" => ["desc(population)", "asc(name)"]`
    /// - queryType: Select how the query words are interpreted, it can be one of the following value:
    ///     - prefixAll: all query words are interpreted as prefixes,
    ///     - prefixLast: only the last word is interpreted as a prefix (default behavior),
    ///     - prefixNone: no query word is interpreted as a prefix. This option is not recommended.
    /// - highlightPreTag: (string) Specify the string that is inserted before the highlighted parts in the query result (default to "<em>").
    /// - highlightPostTag: (string) Specify the string that is inserted after the highlighted parts in the query result (default to "</em>").
    /// - optionalWords: (array of strings) Specify a list of words that should be considered as optional when found in the query.
    @objc public func setSettings(settings: [String: AnyObject], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/settings"
        return client.performHTTPQuery(path, method: .PUT, body: settings, hostnames: client.writeHosts, block: block)
    }
    
    /// Delete the index content without removing settings and index specific API keys.
    @objc public func clearIndex(block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/clear"
        return client.performHTTPQuery(path, method: .POST, body: nil, hostnames: client.writeHosts, block: block)
    }
    
    /// List all existing user keys associated to this index
    @objc public func listUserKeys(block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: block)
    }
    
    /// List all existing user keys associated to this index
    @objc public func getUserKeyACL(key: String, block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys/\(key.urlEncode())"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: block)
    }
    
    /// Delete an existing user key associated to this index
    @objc public func deleteUserKey(key: String, block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys/\(key.urlEncode())"
        return client.performHTTPQuery(path, method: .DELETE, body: nil, hostnames: client.writeHosts, block: block)
    }
    
    /// Create a new user key associated to this index
    ///
    /// - parameter acls: The list of ACL for this key. The list can contains the following values (as String): search, addObject, deleteObject, deleteIndex, settings, editSettings
    @objc public func addUserKey(acls: [String], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys"
        let request = ["acl": acls]
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Create a new user key associated to this index
    ///
    /// - parameter acls: The list of ACL for this key. The list can contains the following values (as String): search, addObject, deleteObject, deleteIndex, settings, editSettings
    /// - parameter withValidity: The number of seconds after which the key will be automatically removed (0 means no time limit for this key)
    /// - parameter maxQueriesPerIPPerHour: Specify the maximum number of API calls allowed from an IP address per hour.  Defaults to 0 (unlimited).
    /// - parameter maxHitsPerQuery: Specify the maximum number of hits this API key can retrieve in one call. Defaults to 0 (unlimited)
    @objc public func addUserKey(acls: [String], withValidity validity: UInt, maxQueriesPerIPPerHour maxQueries: UInt, maxHitsPerQuery maxHits: UInt, block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys"
        let request: [String: AnyObject] = [
            "acl": acls,
            "validity": validity,
            "maxQueriesPerIPPerHour": maxQueries,
            "maxHitsPerQuery": maxHits,
        ]
        
        return client.performHTTPQuery(path, method: .POST, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Update a user key associated to this index
    ///
    /// - parameter withACL: The list of ACL for this key. The list can contains the following values (as String): search, addObject, deleteObject, deleteIndex, settings, editSettings
    @objc public func updateUserKey(key: String, withACL acls: [String], block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys/\(key.urlEncode())"
        let request = ["acl": acls]
        return client.performHTTPQuery(path, method: .PUT, body: request, hostnames: client.writeHosts, block: block)
    }
    
    /// Update a user key associated to this index
    ///
    /// - parameter withACL: The list of ACL for this key. The list can contains the following values (as String): search, addObject, deleteObject, deleteIndex, settings, editSettings
    /// - parameter andValidity: The number of seconds after which the key will be automatically removed (0 means no time limit for this key)
    /// - parameter maxQueriesPerIPPerHour: Specify the maximum number of API calls allowed from an IP address per hour.  Defaults to 0 (unlimited).
    /// - parameter maxHitsPerQuery: Specify the maximum number of hits this API key can retrieve in one call. Defaults to 0 (unlimited)
    @objc public func updateUserKey(key: String, withACL acls: [String], andValidity validity: UInt, maxQueriesPerIPPerHour maxQueries: UInt, maxHitsPerQuery maxHits: UInt, block: CompletionHandler? = nil) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/keys/\(key.urlEncode())"
        let request: [String: AnyObject] = [
            "acl": acls,
            "validity": validity,
            "maxQueriesPerIPPerHour": maxQueries,
            "maxHitsPerQuery": maxHits,
        ]
        
        return client.performHTTPQuery(path, method: .PUT, body: request, hostnames: client.writeHosts, block: block)
    }
    
    // MARK: - Browse
    
    /// Browse all index content (initial call).
    /// This method should be called once to initiate a browse. It will return the first page of results and a cursor,
    /// unless the end of the index has been reached. To retrieve subsequent pages, call `browseFrom` with that cursor.
    ///
    /// - parameter query: The query parameters for the browse.
    @objc public func browse(query: Query, block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/browse"
        let body = [
            "params": query.build()
        ]
        return client.performHTTPQuery(path, method: .POST, body: body, hostnames: client.readHosts, block: block)
    }
    
    /// Browse the index from a cursor.
    /// This method should be called after an initial call to `browse()`. It returns a cursor, unless the end of the
    /// index has been reached.
    ///
    /// - parameter cursor: The cursor of the next page to retrieve
    @objc public func browseFrom(cursor: String, block: CompletionHandler) -> NSOperation {
        let path = "1/indexes/\(urlEncodedIndexName)/browse?cursor=\(cursor.urlEncode())"
        return client.performHTTPQuery(path, method: .GET, body: nil, hostnames: client.readHosts, block: block)
    }
    
    // MARK: - Search Cache
    
    /// Enable search cache.
    ///
    /// - parameter expiringTimeInterval: Each cached search will be valid during this interval of time
    @objc public func enableSearchCache(expiringTimeInterval: NSTimeInterval = 120) {
        searchCache = ExpiringCache(expiringTimeInterval: expiringTimeInterval)
    }
    
    /// Disable search cache
    @objc public func disableSearchCache() {
        searchCache?.clearCache()
        searchCache = nil
    }
    
    /// Clear search cache
    @objc public func clearSearchCache() {
        searchCache?.clearCache()
    }
}
