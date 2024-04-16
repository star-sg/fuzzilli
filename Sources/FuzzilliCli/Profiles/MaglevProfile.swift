import Fuzzilli

fileprivate let GcGenerator = CodeGenerator("GcGenerator") { b in
    let gc = b.loadBuiltin("gc")

    // Do minor GCs more frequently.
    let type = b.loadString(probability(0.25) ? "major" : "minor")
    // If the execution type is 'async', gc() returns a Promise, we currently
    // do not really handle other than typing the return of gc to .undefined |
    // .jsPromise. One could either chain a .then or create two wrapper
    // functions that are differently typed such that fuzzilli always knows
    // what the type of the return value is.
    let execution = b.loadString(probability(0.5) ? "sync" : "async")
    b.callFunction(gc, withArgs: [b.createObject(with: ["type": type, "execution": execution])])
}

fileprivate let MaglevFuzzer = ProgramTemplate("MaglevFuzzer") { b in 
    b.buildPrefix();
    b.build(n: 100, by: .generating)
    let f = b.buildPlainFunction(with: b.randomParameters()) { args in
        b.build(n: 100, by: .generating)
        b.doReturn(b.randomVariable())
    }


    b.eval("%PrepareFunctionForOptimization(%@)", with: [f]);
    b.callFunction(f, withArgs: b.randomArguments(forCalling: f))
    b.eval("%OptimizeMaglevOnNextCall(%@)", with: [f]);
    b.callFunction(f, withArgs: b.randomArguments(forCalling: f))
}

let maglevProfile = Profile(
    processArgs: { randomize in 
        var args = [
            "--expose-gc",
            "--fuzzing",
            "--jit-fuzzing",
            "--allow-natives-syntax"
        ]

        guard randomize else { return args; }

        return args;
    },
    processEnv: [:],
    maxExecsBeforeRespawn: 1,
    timeout: 250,

    codePrefix: "",
    codeSuffix: "",

    ecmaVersion: ECMAScriptVersion.es6,
    startupTests: [
        ("fuzzilli('FUZZILLI_PRINT', 'test')", .shouldSucceed),

        ("fuzzilli('FUZZILLI_CRASH', 0)", .shouldCrash),
        ("fuzzilli('FUZZILLI_CRASH', 1)", .shouldCrash),
        ("fuzzilli('FUZZILLI_CRASH', 2)", .shouldCrash),
        ("fuzzilli('FUZZILLI_CRASH', 3)", .shouldCrash),
    ],

    additionalCodeGenerators: [
        (GcGenerator, 10)
    ],
    additionalProgramTemplates: WeightedList<ProgramTemplate>([
        (MaglevFuzzer, 10)
    ]),

    disabledCodeGenerators: [],
    disabledMutators: [],

    additionalBuiltins: [
        "gc" : .function([] => (.undefined | .jsPromise))
    ],

    additionalObjectGroups: [],
    optionalPostProcessor: nil
)
