# RunScriptPlugin

SwiftPackage Plugin for executing arbitrary ShellScript.


## Usage
Place the file named `.runscript.yml` in the root of the project.
Write the shell script you want to run in this file.

The format is as follows.

```yaml
prebuild: # prebuildCommand
  - name: "Hello"
    script: "echo Hello" # Write scripts directly
  - name: "Show current path"
    script: "pwd"
  - name: "Write file"
    script: "echo Hello >> test.txt"
  - name: "SwiftLint"
    launchPath: "/bin/bash" # bash, zsh, etc. can be specified
    script: "swiftlint lint --fix"

  - name: "Update schema"
    file: "update_schema.sh" # Execute .sh file

build: # build Command
   - name: "Hello"
     script: "echo Hello"

```

## Example
- SwiftLint
You can run Lint in SPM without using the SwiftLint plugin.
```yaml
- name: "SwiftLint"
  script: "swiftlint lint"
```

- Build Log
```yaml
- name: "Build Log"
  script: "echo \"[$(date)] Build >> build.log\""
```

- Theos(Orion) install
You can install the Tweak from the Build button in SPM.
```yaml
- name: "Theos make package and install"
  script: "make do"
```
- SwiftFormat
```yaml
- name: "SwiftFormat"
  script: "swiftformat ."
```

- SwiftGen
```yaml
- name: "SwiftGen"
  script: "swiftgen config run"
```
