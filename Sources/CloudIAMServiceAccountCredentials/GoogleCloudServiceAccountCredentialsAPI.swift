import Vapor
@_exported import IAMServiceAccountCredentials
@_exported import GoogleCloud

extension Application.GoogleCloudPlatform {
    
    private struct APIKey: StorageKey {
        typealias Value = ServiceAccountCredentialsAPI
    }
    
    private struct ConfigurationKey: StorageKey {
        typealias Value = IAMServiceAccountCredentialsConfiguration
    }
    
    private struct HTTPClientKey: StorageKey, LockKey {
        typealias Value = HTTPClient
    }
    
    public var iamServiceAccountCredentials: ServiceAccountCredentialsAPI {
        get {
            if let existing = self.application.storage[APIKey.self] {
                return existing
            } else {
                return .init(application: self.application, eventLoop: self.application.eventLoopGroup.next())
            }
        }
        
        nonmutating set {
            self.application.storage[APIKey.self] = newValue
        }
    }
    
    public struct ServiceAccountCredentialsAPI {
        public let application: Application
        public let eventLoop: EventLoop
        
        /// A client used to interact with the `GoogleCloudIAMServiceAccountCredentials` API.
        public var client: IAMServiceAccountCredentialsClient {
            do {
                let new = try IAMServiceAccountCredentialsClient(
                    credentials: self.application.googleCloud.credentials,
                    config: self.configuration,
                    httpClient: self.http,
                    eventLoop: self.eventLoop
                )
                return new
            } catch {
                fatalError("\(error.localizedDescription)")
            }
        }
        
        /// The configuration for using `GoogleCloudIAMServiceAccountCredentials` APIs.
        public var configuration: IAMServiceAccountCredentialsConfiguration {
            get {
                if let configuration = application.storage[ConfigurationKey.self] {
                   return configuration
                } else {
                    fatalError("Service Account Credentials configuration has not been set. Use app.googleCloud.iamServiceAccountCredentials.configuration = ...")
                }
            }
            set {
                if application.storage[ConfigurationKey.self] == nil {
                    application.storage[ConfigurationKey.self] = newValue
                } else {
                    fatalError("Attempting to override credentials configuration after being set is not allowed.")
                }
            }
        }
        
        /// Custom `HTTPClient` that ignores unclean SSL shutdown.
        public var http: HTTPClient {
            if let existing = application.storage[HTTPClientKey.self] {
                return existing
            } else {
                let lock = application.locks.lock(for: HTTPClientKey.self)
                lock.lock()
                defer { lock.unlock() }
                if let existing = application.storage[HTTPClientKey.self] {
                    return existing
                }
                let new = HTTPClient(
                    eventLoopGroupProvider: .shared(application.eventLoopGroup),
                    configuration: HTTPClient.Configuration(ignoreUncleanSSLShutdown: true)
                )
                application.storage.set(HTTPClientKey.self, to: new) {
                    try $0.syncShutdown()
                }
                return new
            }
        }
    }
}

extension Request {
    private struct IAMServiceAccountCredentialsClientKey: StorageKey {
        typealias Value = IAMServiceAccountCredentialsClient
    }
    
    /// A client used to interact with the `GoogleCloudIAMServiceAccountCredentials` API
    public var gcIAMServiceAccountCredentials: IAMServiceAccountCredentialsClient {
        
        if let existing = application.storage[IAMServiceAccountCredentialsClientKey.self] {
            return existing.hopped(to: self.eventLoop)
        } else {
            
            let new = Application.GoogleCloudPlatform.ServiceAccountCredentialsAPI(
                application: self.application,
                eventLoop: self.eventLoop
            ).client
            
            application.storage[IAMServiceAccountCredentialsClientKey.self] = new
            
            return new
        }
    }
}
