/********************************************************************************
 * Copyright (c) 2023 University of York and others
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *  Charlie Burholt - initial definition
 *	Sinem Getir Yaman - initial definition
 *	Maddie Jones - initial definition 
 ********************************************************************************/
package circus.robocalc.sleec.validation

import circus.robocalc.sleec.SLEECEvaluator
import circus.robocalc.sleec.SLEECSystem
import circus.robocalc.sleec.sLEEC.Atom
import circus.robocalc.sleec.sLEEC.BoolComp
import circus.robocalc.sleec.sLEEC.Constant
import circus.robocalc.sleec.sLEEC.Event
import circus.robocalc.sleec.sLEEC.MBoolExpr
import circus.robocalc.sleec.sLEEC.Measure
import circus.robocalc.sleec.sLEEC.Not
import circus.robocalc.sleec.sLEEC.RelComp
import circus.robocalc.sleec.sLEEC.Rule
import circus.robocalc.sleec.sLEEC.SLEECPackage
import circus.robocalc.sleec.sLEEC.Specification
import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import com.google.common.collect.Sets
import java.util.HashSet
import java.util.List
import java.util.Set
import org.eclipse.xtext.validation.Check
import java.util.HashMap
// import java.util.Collections

/** 
 * This class contains custom validation rules. 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class SLEECValidator extends AbstractSLEECValidator {
	
	// variable names being used by ticktock.csp can cause problems if used here
	var List<String> invalid_names = newArrayList("STOP", "P", "Q", "c", "d")
	
	@Check
	def checkEventName(Event e) {
		if (!Character.isUpperCase(e.name.charAt(0)))
			warning("Event identifier should begin with capital letter", e, SLEECPackage.Literals.DEFINITION__NAME)
		if (invalid_names.contains(e.name))
			error("Invalid variable name: " + e.name + ".", e, SLEECPackage.Literals.DEFINITION__NAME)
	}

	@Check
	def checkMeasureName(Measure m) {
		if (!Character.isLowerCase(m.name.charAt(0)))
			warning("Measure identifier should begin with lower case letter", m, SLEECPackage.Literals.DEFINITION__NAME)
		if (invalid_names.contains(m.name))
			error("Invalid variable name: " + m.name + ".", m, SLEECPackage.Literals.DEFINITION__NAME)
	}

	@Check
	def checkConstantName(Constant c) {
		for (i : 0 ..< c.name.length)
			if (Character.isLowerCase(c.name.charAt(i)))
				warning("Constant identifier should be in all capitals.", c, SLEECPackage.Literals.DEFINITION__NAME)
		if (invalid_names.contains(c.name))
			error("Invalid variable name: " + c.name + ".", c, SLEECPackage.Literals.DEFINITION__NAME)
	}
	
	@Check
	def checkVarNames(Specification s){
		val defBlock = s.defBlock
		
		// check for invalid variable names
		defBlock.eAllContents.filter(Atom).toIterable.forEach [ atom |
			if (invalid_names.contains(atom.measureID))
				error("Invalid variable name: " + atom.measureID + ".", atom, SLEECPackage.Literals.ATOM__MEASURE_ID)
		]
	}

	@Check
	def checkExprTypes(Specification s) {
		val system = new SLEECSystem(s)
		val ruleBlock = s.ruleBlock
		
		// check for undefined variables
		ruleBlock.eAllContents.filter(Atom).toIterable.forEach [ atom |
			val Iterable<String> variableIDs =
				system.numerics +
				system.scales.keySet +
				system.scales.values.toList.flatten +
				system.booleans +
				system.constants.keySet		
			if (!variableIDs.contains(atom.measureID))
				error("Unknown variable: " + atom.measureID, atom, SLEECPackage.Literals.ATOM__MEASURE_ID)
		]
		
		// check the types of a relational operator
		ruleBlock.eAllContents.filter(RelComp).forEach [ relComp |
			// do nothing if both arguments are numeric
			if (system.isNumeric(relComp.left) && system.isNumeric(relComp.right))
				return;
			
			// raise an error if only one argument is numeric
			if (system.isNumeric(relComp.left) != system.isNumeric(relComp.right))
				error("Both operands must be numeric type", relComp, SLEECPackage.Literals.REL_COMP__OP)
			
			// check that both arguments are scale types
			// with one argument being a measureID and the another being a scaleParam
			if (system.isScaleID(relComp.left) && system.isScaleID(relComp.right) ||
				system.isScaleParam(relComp.left) && system.isScaleParam(relComp.right))
				error("One operand must be a measure and the other must be a scale", relComp, SLEECPackage.Literals.REL_COMP__OP)
				
			// check that the scale parameter matches the measure id
			val String = ((system.isScaleID(relComp.left) ? relComp.left : relComp.right) as Atom).measureID
			val String scaleParam = ((system.isScaleParam(relComp.left) ? relComp.left : relComp.right) as Atom).measureID
			if (!system.scales.get(String).contains(scaleParam))
				error(''''ScaleParam «scaleParam»' is not a member of MeasureID '«String»'«»''', relComp, SLEECPackage.Literals.REL_COMP__OP)
		]
		
		// check types of comparison and not operators
		// operands can either be a boolean value or a boolean expression
		ruleBlock.eAllContents.filter(BoolComp).forEach [ boolComp |
			if (!system.isBoolean(boolComp.left) || !system.isBoolean(boolComp.right))
				error("Both operands must be boolean type", boolComp, SLEECPackage.Literals.BOOL_COMP__OP)
		]
		ruleBlock.eAllContents.filter(Not).forEach [ not |
			if (!system.isBoolean(not.expr))
				error("Operand must be boolean type", not, SLEECPackage.Literals.NOT__OP)
		]
		
		// check for conflicts
		
		// create map between each variable and the expressions that it is found in
		val Multimap<String, RelComp> expressions = HashMultimap.create()
		ruleBlock.eAllContents
			.filter(MBoolExpr)
			.forEach[ expr |
				switch(expr) {
					Atom case system.isBoolean(expr.measureID):
						expressions.put(expr.measureID, null)
					RelComp: {
						val args = expr.eContents
							.filter(Atom)
							.map[measureID]
							.filter[system.isNumeric(it) || system.isScaleID(it)]
						// TODO also include expressions that contain two variables as its arguments
						// but this checking for conflicts is more difficult e.g. x < y, y < z, x < y
						args.length == 1 ? expressions.put(args.get(0), expr)
					} 
				}
			]
//		System.out.println('variable -> expression:\t' + expressions)
		
		// find possible values for each variable to make each expression either true or false
		// for numeric expressions x = 5, x < 3, x > 7 the values of x can be: 0, 5, 10
		// for any boolean expression b: b will be 0 (false), 1 (true)
		// for any scale expression: the values will be the 0 .. #scaleParams - 1
		val Multimap<String, Integer> values = HashMultimap.create()
		expressions.asMap.forEach [ k, v |			
			switch(k) {
				case system.isBoolean(k):
					values.get(k).addAll(0, 1)
				case system.isNumeric(k): {
					val getValue = [ RelComp expr |
						system.eval(expr.left) ?: system.eval(expr.right)
					]
					val range = v.map(getValue).min - 1 .. v.map(getValue).max + 1
					val Set<List<Boolean>> outcomes = new HashSet()
					values.putAll(k, range.filter [ i |
						val result = v.map [ expr |
							val left = system.eval(expr.left) ?: i
							val right = system.eval(expr.right) ?: i
							SLEECEvaluator.eval(left, expr.op, right)
						].toList
						outcomes.add(result)
					])
				}
				case system.isScaleID(k): {
					val eval = [ MBoolExpr expr |
						switch (expr) {
							Atom: system.scales.get(k).indexOf(expr.measureID)
						}
					]
					val range = 0 ..< system.scales.get(k).length
					val Set<List<Boolean>> outcomes = new HashSet()
					values.putAll(k, range.filter [ i |
						val result = v.map [ expr |
							val Integer left = eval.apply(expr.left) ?: i
							val Integer right = eval.apply(expr.right) ?: i
							SLEECEvaluator.eval(left, expr.op, right)
						].toList
						outcomes.add(result)
					])
				}
			}
		]
//		System.out.println('variable -> value:\t' + values)
		
		// map between a rule and the index of the index of the combination of values of variables if that combination triggered the rule
		// for:
		// Rule0 when Event0 and x = 5 or y = 3 then E1
		// Rule1 when Event0 and x = 3 and y = 6 then E1
		// values will be
		//{x = [x = 5, x = 3], y = [y = 3, y = 6]}
		// the cartesian product of the values will be:
		// {[x = 5, y = 3], [x = 5, y = 6], [x = 3, y = 3], [x = 3, y = 6]}
		// ruleeTriggered will be:
		// {Rule0 = [0, 1, 2], Rule1 = [3]}
		val Multimap<Rule, Integer> ruleTriggered = HashMultimap.create()
		Sets.cartesianProduct(values.asMap.values.map[toSet]).forEach [ combination, i |
			val variables = (0 ..< combination.size).toMap([values.keySet.get(it)], [combination.get(it)])
			val scales = new HashMap<String, Integer>()
			system.scales.values.forEach [
				forEach[k, v|scales.put(k, v)]
			]
//			System.out.println(variables)
			val evaluator = new SLEECEvaluator(variables, system.constants, scales)
			ruleBlock.rules.forEach [ rule |
				evaluator.eval(rule) ? ruleTriggered.put(rule, i)
			]
		]
//		System.out.println('expressions:\t' + expressions.values.length + '\t' + expressions.values.join(' '))
//		System.out.println('rule -> triggered?\t' + ruleTriggered)
		
		// group rules by matching trigger-response pair
		val Multimap<Pair<String, String>, Rule> rules = HashMultimap.create()
		ruleBlock.rules.forEach [ rule |
			rules.put(rule.trigger.event.name -> rule.response.constraint.event.name, rule)
		]
//		System.out.println('trigger -> response:\t' + rules)
		
		// check for conflicts and redundancies
		rules.asMap.forEach [ trigger, triggeredRules |
			for (i : 0 ..< triggeredRules.length){
				
				val rule0 = triggeredRules.get(i)
				val set0 = ruleTriggered.get(rule0)
				
				for (j : i + 1 ..< triggeredRules.length) {
					
					val rule1 = triggeredRules.get(j)
					val set1 = ruleTriggered.get(rule1)
					// first check for conflicts
					// conflicts happen when responses in the form are both triggered at the same time
					// Event0 within x
					// not Event0 within y
					// where y < x
					if (rule0.response.constraint.not != rule1.response.constraint.not) {
						// only 1 of the 2 rules has a not in their response
						if (rule0.response.constraint.not && system.eval(rule0.response.constraint.value) < system.eval(rule1.response.constraint.value) ||
							rule1.response.constraint.not && system.eval(rule0.response.constraint.value) > system.eval(rule1.response.constraint.value)) {
							error('''«rule0.name» conflicts with «rule1.name».''', rule0, SLEECPackage.Literals.RULE__NAME)
							error('''«rule1.name» conflicts with «rule0.name».''', rule1, SLEECPackage.Literals.RULE__NAME)
							return
						}
						
					}
					// then check for redundancies
					else {
						// either both rules have 'not' or don't have 'not'
						val rule0Redundant = set1.containsAll(set0)
						val rule1Redundant = set0.containsAll(set1)
						// rule0 is redundant if result == 1
						// rule1 is redundant is result == -1
						// no rules are redundant if result == 0
						var result = 
							if (rule0Redundant && (!rule1Redundant || system.eval(rule0.response.constraint.value) <= system.eval(rule1.response.constraint.value)))
								1
							else if (rule1Redundant)
								-1
						// if both rules have not, invert the result
						rule0.response.constraint.not && rule1.response.constraint.not ? result = -result
						switch (result) {
							case 1: warning('''Redundant rule: «rule0.name», under «rule1.name».''', rule0, SLEECPackage.Literals.RULE__NAME)
							case -1: warning('''Redundant rule: «rule1.name», under «rule0.name».''', rule1, SLEECPackage.Literals.RULE__NAME)
						}
					}		
				}
			}	
		]
		
		// Checks a rule's components are not self-conflicting
//		for (rule : ruleBlock.rules) {
			
			// val List<Pair<MBoolExpr, String>> conditions = (Collections.singletonList(rule.trigger.expr -> rule.response.event.name) + rule.defeaters.map[expr -> response.event.name].toList).toList
			
			// System.out.println('conditions for ' + rule.name + ': \t' + conditions)
//		}		
		
		// System.out.println('finished')
	}
}
