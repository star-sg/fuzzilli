// Copyright 2019-2022 Google LLC
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

let xsProfile = Profile(
    processArgs: { (randomize: Bool, differentialTesting: Bool) -> [String] in
        ["-f"]
    },

    processArgumentsReference: ["-f"],

    processEnv: ["UBSAN_OPTIONS":"handle_segv=0"],

    maxExecsBeforeRespawn: 1000,

    timeout: 250,

    codePrefix: """
                const fhash = fuzzilli_hash;
                """,

    codeSuffix: """
                gc();
                """,

    ecmaVersion: ECMAScriptVersion.es6,

    startupTests: [
        // Check that the fuzzilli integration is available.
        ("fuzzilli('FUZZILLI_PRINT', 'test')", .shouldSucceed),

        // Check that common crash types are detected.
        ("fuzzilli('FUZZILLI_CRASH', 0)", .shouldCrash),
        ("fuzzilli('FUZZILLI_CRASH', 1)", .shouldCrash),
        ("fuzzilli('FUZZILLI_CRASH', 2)", .shouldCrash),
    ],

    differentialTests: ["fuzzilli_hash(fuzzilli('FUZZILLI_RANDOM'))",],

    differentialTestsInvariant: ["fuzzilli_hash(Math.random())",
                                 "fuzzilli_hash(Date.now())",],

    differentialPoison: [],

    additionalCodeGenerators: [],

    additionalProgramTemplates: WeightedList<ProgramTemplate>([]),

    disabledCodeGenerators: [],

    disabledMutators: [],

    additionalBuiltins: [
        "gc"                  : .function([] => .undefined),
        "print"               : .function([.string] => .undefined),
        "placeholder"         : .function([] => .undefined),
    ],

    additionalObjectGroups: [],

    optionalPostProcessor: nil
)
