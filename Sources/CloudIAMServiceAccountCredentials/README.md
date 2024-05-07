# GoogleCloudIAMServiceAccountCredentialsAPI

## Getting Started
If you only need to use the [Google Cloud IAM Service Account Credentials API](https://cloud.google.com/iam/docs/reference/credentials/rest), then this guide will help you get started.

In your `Package.swift` file, make sure you have the following dependencies and targets

```swift
dependencies: [
        //...
        .package(url: "https://github.com/vapor-community/google-cloud.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "MyAppName", dependencies: [
            //...
            .product(name: "CloudIAMServiceAccountCredentials", package: "google-cloud"),
        ]),
    ]
```

Now you can setup the configuration for any GCP API globally via `Application`.

In `configure.swift`

```swift
 import CloudIAMServiceAccountCredentials
 
 app.googleCloud.credentials = try GoogleCloudCredentialsConfiguration(projectId: "myprojectid-12345",
 credentialsFile: "~/path/to/service-account.json")
```
Next we setup the CloudIAMServiceAccountCredentials API configuration (specific to this API).

```swift
app.googleCloud.iamServiceAccountCredentials.configuration = .default()
```

Now we can start using the GoogleCloudIAMServiceAccountCredentials API
There's a handy extension on `Request` that you can use to get access to a secret manager client via a property named `gcIAMServiceAccountCredentials`. 

```swift

func signJWT(_ req: Request) throws -> EventLoopFuture<String> {
    
    let unsignedToken: any JWTPayload = Payload()  
       
    req.gcIAMServiceAccountCredentials.api.signJWT(
        unsignedToken
        serviceAccount: "email-for-my-service@account.com"
    )
    .map { $0.signedJwt }
}
```
