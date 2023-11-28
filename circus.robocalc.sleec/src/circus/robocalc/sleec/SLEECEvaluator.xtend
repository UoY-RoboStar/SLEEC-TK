package circus.robocalc.sleec

import circus.robocalc.sleec.sLEEC.Atom
import circus.robocalc.sleec.sLEEC.BoolComp
import circus.robocalc.sleec.sLEEC.BoolOp
import circus.robocalc.sleec.sLEEC.MBoolExpr
import circus.robocalc.sleec.sLEEC.Not
import circus.robocalc.sleec.sLEEC.RelComp
import circus.robocalc.sleec.sLEEC.RelOp
import circus.robocalc.sleec.sLEEC.Rule
import java.util.Map
import circus.robocalc.sleec.sLEEC.Constant
import circus.robocalc.sleec.sLEEC.Value
import circus.robocalc.sleec.sLEEC.BoolValue
import java.util.List
import java.util.Collections

class SLEECEvaluator {

	public Map<String, Integer> variables
	public Map<String, Integer> constants
	public Map<String, Integer> scales

	new(Map<String, Integer> variables, Map<String, Integer> constants, Map<String, Integer> scales) {
		this.variables = variables
		this.constants = constants
		this.scales = scales
	}

	def Boolean eval(Rule rule) {
		rule.trigger.expr === null || eval(rule.trigger.expr)
	}

	def Boolean eval(MBoolExpr expr) {
		if (variables.keySet.containsAll(alpha(expr))) {
			switch (expr) {
				BoolComp: eval(expr)
				BoolValue: expr.value
				RelComp: eval(expr)
				Not: eval(expr)
				Atom: eval(expr)
				default: throw new AssertionError('''unknown type: «expr.class»''')
			}
		}
	}

	def Boolean eval(BoolComp expr) {
		eval(eval(expr.left), expr.op, eval(expr.right))
	}

	def Boolean eval(RelComp expr) {
		eval(evalInt(expr.left), expr.op, evalInt(expr.right))
	}

	def Boolean eval(Not expr) {
		!eval(expr.expr)
	}

	def Boolean eval(Atom expr) {
		val name = expr.measureID
		if (variables.keySet.contains(name))
			variables.get(name) != 0
		else
			throw new AssertionError('expected boolean')
	}

	def static Boolean eval(Integer left, RelOp op, Integer right) {
		switch (op) {
			case EQUAL: left == right
			case NOT_EQUAL: left != right
			case LESS_THAN: left < right
			case GREATER_THAN: left > right
			case LESS_EQUAL: left <= right
			case GREATER_EQUAL: left >= right
		}
	}

	def static Boolean eval(Boolean left, BoolOp op, Boolean right) {
		switch (op) {
			case AND: left && right
			case OR: left || right
		}
	}

	def Integer evalInt(MBoolExpr expr) {
		switch (expr) {
			Atom: {
				val id = expr.measureID 
				switch (id) {
					case variables.containsKey(id): variables.get(id)
					case constants.containsKey(id): constants.get(id)
					case scales.containsKey(id): scales.get(id)
					default: throw new AssertionError('''undefined variable: «id», not found in «variables.keySet»''')
				}
			}
			Value: evalInt(expr)
			default: throw new AssertionError('''expected atom, got «expr»''')
		}
	}
	
	def Integer evalInt(Value expr) {
		switch (expr) {
			Constant: evalInt(expr.constant.value)
			default: expr.value
		}
	}
	
	// TODO move this to its own class as it is used implemented separately in multiple files
	private def List<String> alpha(MBoolExpr expr) {
		val Iterable<Atom> leaves = switch (expr) {
			Atom: Collections.singleton(expr)
			default: expr.eAllContents.filter(Atom).toList
		}
		return leaves
			.map[measureID]
			.toList
	}
}
