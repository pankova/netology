// In-memory data cache
final class MemoryCache: URLCache {
    
    // MARK: - Constants
    
    private enum Constants {
        static let memoryCapacity = 20 * 1024 * 1024
    }
    
    // MARK: - Public Properties
    
    override var currentDiskUsage: Int { 0 }
    override var currentMemoryUsage: Int {
        MemoryLayout.size(ofValue: storedData)
    }
    
    // MARK: - Private Properties
    
    private let queue = DispatchQueue(label: "MemoryCacheQueue")
    private var storedData = [String: CachedURLResponse]()
    
    // MARK: - Initializers
    
    override init() {
        super.init(
            memoryCapacity: Constants.memoryCapacity,
            diskCapacity: 0,
            diskPath: nil)
    }
    
    override init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        super.init(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: path)
    }
    
    // MARK: - URLCache
    
    // MARK: - Store data
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        guard let requestPath = dataTask.originalRequest?.url?.absoluteString else { return }
        queue.sync { storedData[requestPath] = updatedResponse(cachedResponse) }
    }
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        guard let requestPath = request.url?.absoluteString else { return }
        queue.sync { storedData[requestPath] = updatedResponse(cachedResponse) }
    }
    
    // MARK: - Retrieve data
    
    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let requestPath = request.url?.absoluteString else { return nil }
        return queue.sync { storedData[requestPath] }
    }
    
    override func getCachedResponse(
        for dataTask: URLSessionDataTask,
        completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        guard let requestPath = dataTask.originalRequest?.url?.absoluteString else {
                completionHandler(nil)
                return
        }
        let cachedResponse = queue.sync { storedData[requestPath] }
        completionHandler(cachedResponse)
    }
    
    // MARK: - Clear data
    
    override func removeCachedResponse(for dataTask: URLSessionDataTask) {
        guard let requestPath = dataTask.originalRequest?.url?.absoluteString else { return }
        queue.sync { storedData[requestPath] = nil }
    }
    
    override func removeCachedResponse(for request: URLRequest) {
        guard let requestPath = request.url?.absoluteString else { return }
        queue.sync { storedData[requestPath] = nil }
    }
    
    override func removeCachedResponses(since date: Date) {
        queue.sync { storedData = [:] }
    }
    
    override func removeAllCachedResponses() {
        queue.sync { storedData = [:] }
    }
    
    // MARK: - Private Methods
    
    private func updatedResponse(_ cachedResponse: CachedURLResponse) -> CachedURLResponse {
        CachedURLResponse(
            response: cachedResponse.response,
            data: cachedResponse.data,
            userInfo: cachedResponse.userInfo,
            storagePolicy: .allowedInMemoryOnly)
    }
}
