import Foundation
import OpenAI

protocol OpenAIClientProviding {
    var client: OpenAI? { get }
}

final class OpenAIClientProvider: OpenAIClientProviding {

    static let shared = OpenAIClientProvider()

    private lazy var cachedClient: OpenAI? = {
        guard Config.isOpenAIConfigured else { return nil }
        guard let configuration = makeConfiguration() else { return nil }
        return OpenAI(configuration: configuration)
    }()

    private init() {}

    var client: OpenAI? {
        cachedClient
    }

    private func makeConfiguration() -> OpenAI.Configuration? {
        guard let components = URLComponents(string: Config.openAIBaseURL) else {
            return OpenAI.Configuration(
                token: Config.openAIAPIKey,
                customHeaders: makeCustomHeaders()
            )
        }

        let host = components.host ?? "api.openai.com"
        let basePath = components.path.isEmpty ? "/v1" : components.path

        return OpenAI.Configuration(
            token: Config.openAIAPIKey,
            organizationIdentifier: nil,
            host: host,
            port: components.port ?? 443,
            scheme: components.scheme ?? "https",
            basePath: basePath,
            timeoutInterval: 90.0,
            customHeaders: makeCustomHeaders()
        )
    }

    private func makeCustomHeaders() -> [String: String] {
        guard Config.openAIProjectID.isEmpty == false else {
            return [:]
        }
        return ["OpenAI-Project": Config.openAIProjectID]
    }
}
