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
 *   Pedro Ribeiro - initial definition
 ********************************************************************************/
 package circus.robocalc.sleec.assertions.csp

import circus.robocalc.sleec.sLEEC.Rule
import circus.robocalc.sleec.sLEEC.Atom
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import circus.robocalc.sleec.sLEEC.Constraint
import java.util.List
import java.util.Collections
import circus.robocalc.sleec.sLEEC.Measure
import circus.robocalc.robochart.RCModule
import circus.robocalc.robochart.RoboticPlatform
import circus.robocalc.robochart.RoboticPlatformRef
import circus.robocalc.robochart.RoboticPlatformDef
import circus.robocalc.robochart.NamedElement
import java.util.HashMap
import com.google.inject.Inject
import circus.robocalc.robochart.generator.csp.comp.untimed.CGeneratorUtils
import circus.robocalc.robochart.StateMachine
import circus.robocalc.robochart.StateMachineRef
import circus.robocalc.robochart.StateMachineDef
import circus.robocalc.robochart.Controller
import circus.robocalc.robochart.ControllerRef
import circus.robocalc.robochart.ControllerDef

class SLEECUtils {
	
	@Inject CGeneratorUtils _gu
	@Inject SLEECUtils _su
	
	protected def gu() { _gu }
	protected def su() { _su }
	
	// Returns a list of all the EventIds in AST
	protected def <T extends EObject> List<String> alphaE(T AST) {
		// eAllContents does not include the root of the tree
		// so this will return an empty list if AST is an instance of Atom, which is an error
		// so first check that AST is an instance of atom
		val Iterable<Constraint> leaves = if (AST instanceof Constraint)
				// create a 1 element list with the atom's measureID
				Collections.singleton(AST as Constraint)
			else
				AST.eAllContents.filter(Constraint).toList
		// the name of an atom can either be a measureID or a scaleParam
		// filter out the scaleParams 
		return leaves.map[event.name].toList
	}
	
	def getMeasures(Rule r) {
		val measures = r.eAllContents.filter(Atom).map[measureID].toSet // alphaMtree(r) // these are just identifiers, we want actual objects
		val resource = r.eResource
		val allMeasures = resource.allContents.filter(Measure).toSet
		return allMeasures.filter[m|measures.contains(m.name)].toSet
	}
	
	def getEvents(Rule r) {
		var ruleAlphabet = new HashSet<String>()
		ruleAlphabet.add(r.trigger.event.name)
		ruleAlphabet.addAll(alphaE(r))
		return ruleAlphabet
	}
	
	def getAlphabet(Rule r) {
		var ruleAlphabet = new HashSet<String>()
		ruleAlphabet.add(r.trigger.event.name)
		ruleAlphabet.addAll(alphaE(r))
		ruleAlphabet.addAll(getMeasures(r).map[name])
		return ruleAlphabet
	}
	
	def dispatch getNamedElementMap(StateMachine stm, Rule rule) {
		val stmDef = if (stm instanceof StateMachineRef) stm.ref else stm as StateMachineDef
		var requiredOps = gu.requiredOperations(stmDef)
		val events = gu.getEvents(stmDef)
		val alphaRule = su.getAlphabet(rule)
		
		var map = new HashMap<NamedElement,String>
		
		for (e : events) {
			if (alphaRule.contains(e.name)) {
				map.put(e,e.name)
			}
		}
		
		for (o : requiredOps) {
			if (alphaRule.contains(o.name)) {
				map.put(o,o.name)
			}
		}
		return map
	}
	
	def dispatch getNamedElementMap(Controller c, Rule rule) {
		
		val ctrl = if (c instanceof ControllerRef) c.ref else c as ControllerDef
		var requiredOps = gu.requiredOperations(ctrl)
		val events = gu.getEvents(ctrl)
		val alphaRule = su.getAlphabet(rule)
		
		var map = new HashMap<NamedElement,String>
		
		for (e : events) {
			if (alphaRule.contains(e.name)) {
				map.put(e,e.name)
			}
		}
		
		for (o : requiredOps) {
			if (alphaRule.contains(o.name)) {
				map.put(o,o.name)
			}
		}
		return map
	}
	
	def dispatch getNamedElementMap(RCModule m, Rule rule) {
		val aux = m.nodes.filter(RoboticPlatform).get(0)
		val rp = if (aux instanceof RoboticPlatformRef) aux.ref else aux as RoboticPlatformDef
		var allOps = gu.allOperations(rp)
		val events = gu.allEvents(rp)
		val alphaRule = su.getAlphabet(rule)
		
		var map = new HashMap<NamedElement,String>
		
		for (e : events) {
			if (alphaRule.contains(e.name)) {
				map.put(e,e.name)
			}
		}
		
		for (o : allOps) {
			if (alphaRule.contains(o.name)) {
				map.put(o,o.name)
			}
		}
		return map
	}
	
}