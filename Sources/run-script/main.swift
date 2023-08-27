//
//  main.swift
//  
//
//  Created by p-x9 on 2023/02/04.
//  
//

import Combine
import Foundation
import Yams
import ArgumentParser

#if os(macOS)
enum CommandError: LocalizedError {
    case configFileNotExisted
}

enum Timing: String, EnumerableFlag, ExpressibleByArgument {
    case prebuild
    case build
    case command

    static func name(for value: Self) -> NameSpecification {
        .long
    }

    static func help(for value: Self) -> ArgumentHelp? {
        "run scripts defined with '\(value.rawValue)' in configuration file "
    }
}

struct RunScript: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "RunScript",
        abstract: "Run shell scripts configured in yaml files",
        version: "0.0.4",
        shouldDisplay: true,
        helpNames: [.long, .short]
    )

    @Option(help: "configuration file path (YAML)")
    var config: String

    @Option(help: "Which scripts to run in the configuration file")
    var timing: Timing

    @Flag(name: .customLong("silence"), help: "Do not output logs")
    var silence: Bool = false

    func run() async throws {
        let configFileURL = URL(fileURLWithPath: config)

        let fileManager = FileManager.default
        let decoder = YAMLDecoder()

        guard fileManager.fileExists(atPath: config) else {
            throw CommandError.configFileNotExisted
        }

        let data = try Data(contentsOf: configFileURL)
        let config = try decoder.decode(Config.self, from: data)

        let directory = configFileURL.deletingLastPathComponent().path
        FileManager.default.changeCurrentDirectoryPath(directory)

        let scripts = config.scripts(for: timing)

        log("🏃[Start] RunScriptPlugin(\(timing.rawValue))")
        try await scripts.enumerated().asyncForEach { index, script in
            log("🏃[script] \(script.name ?? String(index))...")
            try await run(script)
        }
        log("🏃[End] RunScriptPlugin(\(timing.rawValue))")
    }
}

extension RunScript {
    @inline(never)
    func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if silence { return }
        print(items, separator: separator, terminator: terminator, flush: true)
    }
}

extension RunScript {
    func run(_ script: Script) async throws {
        let outputPublisher = PassthroughSubject<String, Never>()
        let completion = outputPublisher
            .sink { print($0) }
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        process.executableURL = URL(fileURLWithPath:"/bin/sh")

        var environment = ProcessInfo.processInfo.environment
        if let environmentVars = script.environment {
            environment.merge(environmentVars) { $1 }
        }
        process.environment = environment

        if let path = script.path {
            process.arguments = [path]
        } else if let arguments = script.arguments, !arguments.isEmpty {
            process.arguments = arguments
        } else if let script = script.script {
            process.arguments = ["-c", script]
        }

        for try await line in outputPipe.fileHandleForReading.bytes.lines {
            print(line)
        }

        try process.run()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if let error = String(data: errorData, encoding: .utf8) {
            log("warning: [RunScriptPlugin] " + error)
        }
    }
}

RunScript.main()
#endif

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
