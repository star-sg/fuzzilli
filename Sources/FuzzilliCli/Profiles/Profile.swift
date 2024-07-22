// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Fuzzilli

struct JitPickerProcessor: FuzzingPostProcessor {
    init() {}

    func process(_ program: Program, for fuzzer: Fuzzer) -> Program {
        let b = fuzzer.makeBuilder()
        b.append(program, shouldAppendDiff: true)
        if fuzzer.config.differentialRate > 0.0 {
            b.appendDifferentialProbes(with: fuzzer.config.differentialRate)
        }
        return b.finalize()
    }
}

struct Profile {
    let processArgs: (_ randomize: Bool, _ differentialTesting: Bool) -> [String]
    let processArgumentsReference: [String]
    let processEnv: [String : String]
    let maxExecsBeforeRespawn: Int
    // Timeout is in milliseconds.
    let timeout: Int
    let codePrefix: String
    let codeSuffix: String
    let ecmaVersion: ECMAScriptVersion

    // JavaScript code snippets that are executed at startup time to ensure that Fuzzilli and the target engine are configured correctly.
    let startupTests: [(String, ExpectedStartupTestResult)]

    let differentialTests: [String]
    let differentialTestsInvariant: [String]
    let differentialPoison: [String]

    let additionalCodeGenerators: [(CodeGenerator, Int)]
    let additionalProgramTemplates: WeightedList<ProgramTemplate>

    let disabledCodeGenerators: [String]
    let disabledMutators: [String]

    let additionalBuiltins: [String: ILType]
    let additionalObjectGroups: [ObjectGroup]

    // An optional post-processor that is executed for every sample generated for fuzzing and can modify it.
    let optionalPostProcessor: FuzzingPostProcessor?
}

let profiles = [
    "qtjs": qtjsProfile,
    "qjs": qjsProfile,
    "jsc": jscProfile,
    "spidermonkey": spidermonkeyProfile,
    "v8": v8Profile,
    "duktape": duktapeProfile,
    "jerryscript": jerryscriptProfile,
    "xs": xsProfile,
    "v8holefuzzing": v8HoleFuzzingProfile,
    "serenity": serenityProfile,
    "maglev": maglevProfile
]
