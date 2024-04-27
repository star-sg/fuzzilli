import Foundation
import Fuzzilli

func importJSFile(from path: String) -> Program {
    guard FileManager.default.fileExists(atPath: path) else {
        emitError("Invalid input file path \"\(path)\", file does not exist")
    }

    var program = Program()
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let pb = try Fuzzilli_Protobuf_Program(serializedData: data)
        program = try Program.init(from: pb)
    } catch {
        emitError("Failed to import program from disk: \(error)")
    }

    return program
}

class MockEvaluator: ProgramEvaluator {
    func evaluate(_ execution: Execution) -> ProgramAspects? {
        return nil
    }

    func evaluateCrash(_ execution: Execution) -> ProgramAspects? {
        return nil
    }

    func hasAspects(_ execution: Execution, _ aspects: ProgramAspects) -> Bool {
        return false
    }

    var currentScore: Double {
        return 13.37
    }

    func initialize(with fuzzer: Fuzzer) {}

    var isInitialized: Bool {
        return true
    }

    func exportState() -> Data {
        return Data()
    }

    func importState(_ state: Data) {}

    func computeAspectIntersection(of program: Program, with aspects: ProgramAspects) -> ProgramAspects? {
        return nil
    }

    func resetState() {}
}

let args = Arguments.parse(from: CommandLine.arguments)

if args["-h"] != nil || args["--help"] != nil || args.numPositionalArguments != 1 {
    print("""
Usage:
\(args.programName) [options] /path/to/jsshell

Options:
    -h, --help                  : Print this help message
    --target=name               : The name of the input file
    --differential              : If enabled, the fuzzer will use a differential testing on the provided input file
    --profile=name              : Select one of several preconfigured profiles.
                                  Available profiles: \(profiles.keys).
""")
    exit(0)
}

let jsShellPath = args[0]

func emitError(_ message: String) -> Never {
    print("Error: \(message)")
    exit(-1)
}

if !FileManager.default.fileExists(atPath: jsShellPath) {
    emitError("Invalid JS shell path \"\(jsShellPath)\", file does not exist")
}

var profile: Profile! = nil
var profileName: String! = nil
if let val = args["--profile"], let p = profiles[val] {
    profile = p
    profileName = val
}
if profile == nil || profileName == nil {
    emitError("Please provide a valid profile with --profile=profile_name. Available profiles: \(profiles.keys)")
}

var targetProgram: Program! = nil
if let target = args["--target"] {
    targetProgram = importJSFile(from: target)
} else {
    emitError("Please provide a target file with --target=name")
}

let differentialTesting = args.has("--differential")

let configuration = Configuration(logLevel: .warning)
let runner = REPRL(executable: jsShellPath, processArguments: profile.processArgs(false, differentialTesting), processEnvironment: profile.processEnv, maxExecsBeforeRespawn: profile.maxExecsBeforeRespawn)
let _ = ProgramCoverageEvaluator(runner: runner)

var referenceRunner: ScriptRunner? = nil
if differentialTesting {
    referenceRunner = REPRL(executable: jsShellPath, processArguments: profile.processArgumentsReference, processEnvironment: profile.processEnv, maxExecsBeforeRespawn: profile.maxExecsBeforeRespawn)
    let _ = ProgramCoverageEvaluator(runner: referenceRunner!)
}

let mutators = WeightedList<Mutator>([
    (CodeGenMutator(),                  1),
    (OperationMutator(),                1),
    (InputMutator(isTypeAware: false),  1),
    (CombineMutator(),                  1),
])

let engine = MutationEngine(numConsecutiveMutations: 5)
let evaluator = MockEvaluator()
let environment = JavaScriptEnvironment(additionalBuiltins: profile.additionalBuiltins, additionalObjectGroups: profile.additionalObjectGroups)
let lifter = JavaScriptLifter(prefix: profile.codePrefix, suffix: profile.codeSuffix, ecmaVersion: profile.ecmaVersion)
let corpus = BasicCorpus(minSize: 1000, maxSize: 2000, minMutationsPerSample: 5)
let minimizer = Minimizer()
let codeGenerators = WeightedList<CodeGenerator>(CodeGenerators.map { return ($0, codeGeneratorWeights[$0.name]!) })
let programTemplates = WeightedList<ProgramTemplate>(ProgramTemplates.map { return ($0, programTemplateWeights[$0.name]!) })

let fuzzer = Fuzzer(configuration: configuration,
                    scriptRunner: runner,
                    referenceRunner: referenceRunner,
                    engine: engine,
                    mutators: mutators,
                    codeGenerators: codeGenerators,
                    programTemplates: programTemplates,
                    evaluator: evaluator,
                    environment: environment,
                    lifter: lifter,
                    corpus: corpus,
                    minimizer: minimizer,
                    queue: DispatchQueue.main)

fuzzer.initialize()

let script = lifter.lift(targetProgram)
let execution = runner.run(script, withTimeout: 250)

print("Execution outcome: \(execution.outcome.description)")

if differentialTesting {
    let referenceExecution = referenceRunner!.run(script, withTimeout: 250)
    print("Reference execution outcome: \(referenceExecution.outcome.description)")
    if execution.outcome == referenceExecution.outcome && execution.outcome == .succeeded {
        if execution.differentialResult != referenceExecution.differentialResult {
            print("Execution results differ : 0x\(String(execution.differentialResult, radix: 16)) --- 0x\(String(referenceExecution.differentialResult, radix: 16))")
        } else {
            print("Execution results are equal : 0x\(String(execution.differentialResult, radix: 16))")
        }
    } else {
        print("Reference execution failed")
    }
}
