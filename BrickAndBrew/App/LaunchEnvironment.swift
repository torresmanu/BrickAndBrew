import Foundation

enum LaunchEnvironment {
    /// The test host launches the full app; skip CloudKit/Apple bootstrap there.
    static var isRunningUnitTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
    }
}
