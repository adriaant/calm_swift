import Foundation


struct Parameters {
	var values = [Double](count:Names.BMAP.rawValue + 1, repeatedValue: 0.0)
	
	enum Names: Int {
		case UP = 0,
			DOWN,
			CROSS,
			FLAT,
			HIGH,
			LOW,
			AE,
			ER,
			INITWT,
			LOWCRIT,
			HIGHCRIT,
			K_A,
			K_Lmax,
			K_Lmin,
			L_L,
			D_L,
			WMUE_L,
			G_L,
			G_W,
			F_Bw,		// Feedback weight update
			F_Ba,		// Feedback activation enforcer
			SIGMA,
			P_G,		// Grow parameter
			P_S,		// Shrink parameter
			U_L,
			AMAP,
			BMAP
	}

	init() {
	}

	init?(fromFile: String) {
		let fileData: AnyObject? = dataFromJsonFile(fromFile)
		if (fileData != nil) {
			let readValues = fileData as! [Double]
			for (index, value) in readValues.enumerate() {
				values[index] = value
			}
		} else {
			return nil
		}
	}

	subscript(index: Names) -> Double {
		let i = index.rawValue
		if 0 <= i && i < values.count {
			return values[i]
		}
		print("Accessing non-existing parameter!")
		return 0.0
	}
}

/// Network of interconnected modules
class Network: CustomStringConvertible {
	
	var parameters: Parameters = Parameters()
	var inputModules: [String: InputModule] = [:]
	var modules: [String:CalmModule] = [:]

	init?(baseDirectory: String) {
		let customParameters = Parameters(fromFile:"\(baseDirectory)/pars.txt")
		if customParameters == nil {
			print("Parameters could not be initialized!")
			return nil
		}
		self.parameters = customParameters!
	}
	
	func addInputModule(name: String, size: Int) {
		inputModules[name] = InputModule(name: name, size: size)
	}

	func addModule(name: String, size: Int) {
		modules[name] = CalmModule(name: name, size: size)
	}

	func connectModule(from: Module, toModule: CalmModule) {
		toModule.addConnectionFromModule(from)
	}

	func connectModuleWithName(fromName: String, toModuleWithName: String) {
		var success = false
		if let fromModule = inputModules[fromName] {
			if let toModule = modules[toModuleWithName] {
				connectModule(fromModule, toModule: toModule)
				success = true
			}
		} else if let fromModule = modules[fromName] {
			if let toModule = modules[toModuleWithName] {
				connectModule(fromModule, toModule: toModule)
				success = true
			}
		}
		if !success {
			print("Cannot connect \(fromName) to \(toModuleWithName)")
		}
	}

	func winnerForModule(name: String) -> Int {
		var winner: Int = 0
		if let mdl = modules[name] {
			winner = mdl.winner()
		}
		return winner
	}

	var description: String {
		var output = ""
		for mdl in modules {
			output += "\(mdl)"
			output += "\n"
		}
		return output
	}

	func prepareForLearning() {
		for module in modules.values {
			module.prepare(true)
		}
	}

	func prepareForTesting() {
		for module in modules.values {
			module.prepare(false)
		}
	}
	

	/**
	Trains a single input vector. The input modules are set to the input values,
	after which activation will iterate for a given number of iterations and
	weights are adapted.
	
	- parameter values: A dictionary mapping input values on input modules.
	*/
	func train(values: [String: [Double]]) {
		/// Set the input values
		for (name, input) in values {
			if let inputModule = inputModules[name] {
				inputModule.present(input)
			} else {
				print("There is no input module named \(name)!")
			}
		}
		
		let moduleList = modules.values
		// first reset activations
		for module in moduleList {
			module.reset()
		}
		for _ in 1...Workspace.numberOfIterations {
			for module in moduleList {
				module.updateActivations()
			}
			for module in moduleList {
				module.updateWeights()
			}
			for module in moduleList {
				module.swapActivations()
			}
		}
	}

	/**
	Tests a single input vector. The input modules are set to the input values,
	after which activation will iterate for a given number of iterations without
	weights being adapted.
	
	- parameter values: A dictionary mapping input values on input modules.
	*/
	func test(values: [String: [Double]]) {
		/// Set the input values
		for (name, input) in values {
			if let inputModule = inputModules[name] {
				inputModule.present(input)
			} else {
				print("There is no input module named \(name)!")
			}
		}
		
		let moduleList = modules.values
		// first reset activations
		for module in moduleList {
			module.reset()
		}
		for _ in 1...Workspace.numberOfIterations {
			for module in moduleList {
				module.updateActivations()
			}
			for module in moduleList {
				module.swapActivations()
			}
		}
	}
}

/// Generic module
class Module {
	var size: Int
	var name: String
	var nodes: [RepresentationNode]

	init(name: String, size: Int) {
		self.name = name
		self.size = size
		nodes = [RepresentationNode]((0..<size).map { _ in
			RepresentationNode()
		})
	}

	func indexIsValid(index: Int) -> Bool {
		return index >= 0 && index < nodes.count
	}
	
	subscript(index:Int) -> Double {
		get {
			assert(indexIsValid(index), "Index out of range")
			return nodes[index].currentActivation
		}
	}
	
	func winner() -> Int {
		var winner = 0
		for (i, node) in nodes.enumerate() {
			if node.currentActivation >= 0.9 {
				if winner == 0 {
					winner = i + 1 // 1-based
				} else {
					return 0 // more than one node, so competition did not resolve
				}
			}
		}
		return winner
	}
}

/// Input module
class InputModule: Module {
	
	func present(values: [Double]) {
		for (index, value) in values.enumerate() {
			nodes[index].setActivation(value)
		}
	}
}

/// Standard CALM module
class CalmModule: Module, CustomStringConvertible {
	var vNodes: [VetoNode]
	var aNode: ArousalNode = ArousalNode()
	var eNode: ExternalNode = ExternalNode()
	var connections: [Connection] = []

	let crossWeight: Double = Workspace.valueForParameter(.CROSS)
	let downWeight: Double = Workspace.valueForParameter(.DOWN)
	let upWeight: Double = Workspace.valueForParameter(.UP)
	let flatWeight: Double = Workspace.valueForParameter(.FLAT)
	
	let glParameter: Double = Workspace.valueForParameter(.G_L)
	let gwParameter: Double = Workspace.valueForParameter(.G_W)
	let dlParameter: Double = Workspace.valueForParameter(.D_L)
	let muParameter: Double = Workspace.valueForParameter(.WMUE_L)
	
	override init(name: String, size: Int) {
		vNodes = [VetoNode]((0..<size).map { _ in
			VetoNode()
		})
		super.init(name: name, size: size)
	}

	var description: String {
		return "\(connections)"
	}

	func reset() {
		for node in nodes {
			node.reset()
		}
		for node in vNodes {
			node.reset()
		}
		aNode.reset()
		eNode.reset()
	}

	func prepare(isLearning: Bool) {
		eNode.setActivationRule(isLearning)
		if isLearning {
			// reset weights to initial value for new training sessions
			for connection in connections {
				connection.reset()
			}
		}
	}

	func addConnectionFromModule(from:Module) {
		// first check if we do not already have a connection
		for connection in connections {
			if connection.fromModule != nil && connection.fromModule! === from {
				return
			}
		}
		// create one and add to internal connections list
		connections.append(Connection(from: from, to: self))
	}
	
	func updateActivations() {
		var totalVact: Double = 0.0;
		var totalRact: Double = 0.0;

		/// Record the sum of V-node activations
		for node in vNodes {
			totalVact += node.currentActivation
		}
		
		/// Update R-node activation
		for (index, node) in nodes.enumerate() {
			var newAct: Double = 0.0
			let pairedVNodeActivation: Double = vNodes[index].currentActivation

			totalRact += node.currentActivation
			
			/// Loop through incoming connections
			for connection in connections {
				newAct += connection.weightedActivationToNodeWithIndex(index)
			}
			
			/// Update with V-node activations
			newAct += crossWeight * (totalVact - pairedVNodeActivation)
			newAct += downWeight * pairedVNodeActivation
			
			/// Update with E-node activation
			newAct += eNode.activationRule()
			
			/// Set the new activation
			node.updateActivation(newAct)
		}

		/// Update V-node activation
		for (index, node) in vNodes.enumerate() {
			var newAct: Double = 0.0
			
			/// Activation from paired R-node
			newAct += upWeight * nodes[index].currentActivation
			
			/// Activation from other V-nodes
			newAct += flatWeight * (totalVact - node.currentActivation)
			
			/// Set the new activation
			node.updateActivation(newAct)
		}

		aNode.updateActivation(totalRact, totalVactivation: totalVact)
		eNode.updateActivation(aNode.currentActivation)
	}

	/**
	Updates weights on connection between R-nodes using a dynamic Gaussian learning rate.
	*/
	func updateWeights() {
		/// Gaussian learning rule
		let externalFactor: Double = (eNode.currentActivation - glParameter) * (eNode.currentActivation - glParameter)
		let mu: Double = dlParameter + muParameter * exp(0.0 - (externalFactor / gwParameter))

		/// this is the original CALM learning rate:
		///	mu = dlParameter + muParametr * eNode.currentActivation

		for (index, _) in nodes.enumerate() {
			var backgroundActivation: Double = 0.0
			
			/// Get all weighted incoming activations
			for connection in connections {
				backgroundActivation += connection.weightedActivationToNodeWithIndex(index)
			}
			/// Update each connection.
			/// Note that background activation applies to all connections.
			for connection in connections {
				connection.updateWeightToIndex(index, rate: mu, background: backgroundActivation)
			}
		}
	}

	/// Swaps activations in all nodes.
	func swapActivations() {

		for i in 0 ..< nodes.count {
			nodes[i].swapActivation()
			vNodes[i].swapActivation()
		}
		
		aNode.swapActivation()
		eNode.swapActivation()
	}
}

/// Generic node of a CALM module, always activatable.
class Node: CustomStringConvertible {
	var currentActivation: Double = 0.0
	var newActivation: Double = 0.0
	let decayRate: Double = 1.0 - Workspace.valueForParameter(.K_A)

	func reset() {
		currentActivation = 0.0
		newActivation = 0.0
	}

	func setActivation(value: Double) {
		currentActivation = value
	}

	func updateActivation(value: Double) {
		let decay: Double = decayRate * currentActivation
		
		newActivation = value
		if newActivation >= 0.0 {
			newActivation = decay + (newActivation / (1.0 + newActivation)) * (1.0 - decay)
		} else {
			newActivation = decay + (newActivation / (1.0 - newActivation)) * decay
		}
		
		newActivation = max(min(newActivation, 1.0), 0.0)
	}

	func swapActivation() {
		currentActivation = newActivation
	}

	var description: String {
		return "\(currentActivation)"
	}
}

class RepresentationNode: Node {
}

class VetoNode: Node {
}

class ArousalNode: Node {
	let highWeight: Double = Workspace.valueForParameter(.HIGH)
	let lowWeight: Double = Workspace.valueForParameter(.LOW)

	func updateActivation(totalRActivation: Double, totalVactivation: Double) {
		let value: Double = highWeight * totalVactivation + lowWeight * totalRActivation
		updateActivation(value)
	}
}

class ExternalNode: Node {
	let aeWeight: Double = Workspace.valueForParameter(.AE)
	let erWeight: Double = Workspace.valueForParameter(.ER)
	// For testing you'd set gen to FakeRandomDoubleGenerator();
	let gen = UniformRandomDoubleGenerator()

	lazy var withNoise: () -> Double = {
		[unowned self] in
		return self.gen.nextValue() * self.erWeight * self.currentActivation
	}
	lazy var withoutNoise: () -> Double = {
		[unowned self] in
		return self.erWeight * self.currentActivation
	}

	var activationRule: (()->Double)!

	override func updateActivation(value: Double) {
		let newvalue: Double = aeWeight * value
		super.updateActivation(newvalue)
	}

	func setActivationRule(isLearning: Bool) {
		if isLearning {
			activationRule = withNoise
		} else {
			activationRule = withoutNoise
		}
	}
}

/// Weight on connection between R-nodes
class Weight: CustomStringConvertible {
	var value: Double = Workspace.valueForParameter(.INITWT)
	var delta: Double = 0.0
	let max_value: Double = Workspace.valueForParameter(.K_Lmax)
	let min_value: Double = Workspace.valueForParameter(.K_Lmin)

	var description: String {
		return "\(value)"
	}
	
	func reset() {
		value = Workspace.valueForParameter(.INITWT)
	}
	
	func adapt(delta: Double) {
		self.delta = delta
		value = max(min(value + delta, max_value), min_value);
	}
}

/// Connection between modules
class Connection: CustomStringConvertible {
	weak var fromModule: Module?
	weak var toModule: Module?
	var matrix: [Weight]
	
	let klMaxParameter: Double = Workspace.valueForParameter(.K_Lmax)
	let klMinParameter: Double = Workspace.valueForParameter(.K_Lmin)
	let llParameter: Double = Workspace.valueForParameter(.L_L)
	
	init(from:Module, to:Module) {
		let count = from.size * to.size
		self.fromModule = from
		self.toModule = to
		matrix = [Weight]((0..<count).map { _ in
			Weight()
		})
	}
	
	func indexIsValidForRow(row: Int, column: Int) -> Bool {
		return row >= 0 && row < toModule!.size && column >= 0 && column < fromModule!.size
	}

	subscript(i:Int, j:Int) -> Weight {
		get {
			assert(indexIsValidForRow(i, column: j), "Index out of range")
			return matrix[toModule!.size * i + j]
		}
		set {
			assert(indexIsValidForRow(i, column: j), "Index out of range")
			matrix[toModule!.size * i + j] = newValue
		}
	}
	
	func weightedActivationToNodeWithIndex(i: Int) -> Double {
		var newAct: Double = 0.0
		
		for j in 0 ..< fromModule!.size {
			newAct += self[i, j].value * fromModule![j]
		}
		return newAct
	}

	/// Apply the Grossberg learning rule
	func updateWeightToIndex(i: Int, rate: Double, background: Double) {
		for j in 0 ..< fromModule!.size {
			let incomingActivation: Double = fromModule![j]
			let connectionWeight: Double = self[i, j].value
			let delta: Double = rate * toModule![i] * (
					(klMaxParameter - connectionWeight) * incomingActivation -
					llParameter * (connectionWeight - klMinParameter) * (background - connectionWeight * incomingActivation)
				)
			self[i, j].adapt(delta)
		}
	}

	func reset() {
		for row in 0 ..< toModule!.size {
			for col in 0 ..< fromModule!.size {
				self[row, col].reset()
			}
		}
	}

	var description: String {
		var output = "\(fromModule!.name) ⟶ \(toModule!.name)\n"
		for row in 0 ..< toModule!.size {
			for col in 0 ..< fromModule!.size {
				output += "\(row):\(col) = \(self[row, col])  "
			}
			output += "\n"
		}
		return output
	}
}
