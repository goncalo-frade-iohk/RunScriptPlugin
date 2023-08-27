// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "RunScriptPlugin",
    platforms: [.macOS(.v12)],
    products: [
        .plugin(
            name: "RunScriptPlugin",
            targets: ["RunScriptPlugin"]
        ),
        .plugin(
            name: "RunScriptCommandPlugin",
            targets: ["RunScriptCommandPlugin"]
        ),
        .executable(
            name: "run-script",
            targets: ["run-script"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "run-script",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .binaryTarget(
            name: "run-script-bin",
            url: "https://github.com/goncalo-frade-iohk/RunScriptPlugin/releases/download/0.7.0/run-script-bin.artifactbundle.zip",
            checksum: "327db805bada3df07049559b1d57db8643e644b6e345ab6d09039ec18d685011"
        ),
//        DEBUG
//        .binaryTarget(name: "run-script-bin", path: "./run-script-bin.artifactbundle.zip"),
        .plugin(
            name: "RunScriptPlugin",
            capability: .buildTool(),
            dependencies: [
                "run-script-bin"
            ]
        ),
        .plugin(
            name: "RunScriptCommandPlugin",
            capability: .command(
                intent: .custom(
                    verb: "run-script",
                    description: "run scripts defined in `runscript.yml`"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "to run scripts defined in `runscript.yml`")
                ]
            ),
            dependencies: [
                "run-script-bin"
            ]
        )
    ]
)
