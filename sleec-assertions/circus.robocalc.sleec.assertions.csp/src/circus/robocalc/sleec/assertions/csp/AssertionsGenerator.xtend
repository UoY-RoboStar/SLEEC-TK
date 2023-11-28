/********************************************************************************
 * Copyright (c) 2019 University of York and others
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

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import circus.robocalc.robochart.assertions.assertions.RAPackage
import java.util.Date
import java.text.SimpleDateFormat
import org.osgi.framework.FrameworkUtil
import circus.robocalc.robochart.generator.csp.ext.ISLEECConformanceGenerator
import circus.robocalc.robochart.assertions.assertions.SLEECAssertion
import circus.robocalc.sleec.sLEEC.Rule
import circus.robocalc.sleec.generator.SLEECGenerator
import java.util.LinkedHashSet
import java.util.List
import circus.robocalc.robochart.NamedElement
import circus.robocalc.robochart.StateMachineDef
import java.util.HashSet
import com.google.inject.Inject
import circus.robocalc.robochart.generator.csp.comp.untimed.CGeneratorUtils
import java.util.HashMap
import java.util.Map
import circus.robocalc.robochart.Event
import org.eclipse.emf.ecore.EObject
import circus.robocalc.robochart.OperationSig
import circus.robocalc.sleec.sLEEC.Definition
import circus.robocalc.sleec.sLEEC.Measure
import circus.robocalc.sleec.sLEEC.Scale
import circus.robocalc.sleec.sLEEC.Atom
import circus.robocalc.robochart.Controller
import circus.robocalc.robochart.ControllerDef
import circus.robocalc.robochart.ControllerRef
import circus.robocalc.robochart.StateMachineRef
import circus.robocalc.robochart.OperationRef
import circus.robocalc.robochart.OperationDef
import circus.robocalc.robochart.StateMachine
import circus.robocalc.robochart.RCModule
import circus.robocalc.robochart.RoboticPlatform
import circus.robocalc.robochart.RoboticPlatformRef
import circus.robocalc.robochart.RoboticPlatformDef
import circus.robocalc.robochart.textual.RoboCalcTypeProvider
import circus.robocalc.robochart.Enumeration
import circus.robocalc.robochart.TypeRef

class AssertionsGenerator extends SLEECGenerator implements ISLEECConformanceGenerator {
	
	@Inject CGeneratorUtils _gu
	@Inject RoboCalcTypeProvider _tp
	@Inject SLEECUtils _su
	
	protected def gu() { _gu }
	protected def tp() { _tp }
	protected def su() { _su }
	
	override generateAssertion(SLEECAssertion a, String suvSemantics) {
		
		val rule = a.rule
		
		if (rule instanceof Rule) {
			//
			val measures = su.getMeasures(rule)
			val suvEvents = ''''''
			// Probably neater to define the context for both sides of the refinement.
			
			// For the data type mappings, we handle:
			// numeric <- core_int (no change)
			// scale <- (simple) enumerated type
			
			
			// For the event mappings, we handle:
			// ev.(in|out) <- ev
			// opCall <- ev
			return 
			'''
			-- Datatype mappings
«««			«FOR t : getMeasures(rule).filter[t|t.type instanceof Scale]»
«««			«FOR p : (t.type as Scale).scaleParams.map[name]»
«««			«a.name»_rename_«t.name»() = «p»
«««			«ENDFOR»
«««			«ENDFOR»
			
			-- Specification
			Timed(OneStep) {
			
			«a.name»_spec = 
				let
					-- The external 'm' channels for every measure of «rule.name»
					MemoryExternalEvents = {|«FOR m : measures SEPARATOR ','»«m.name»«ENDFOR»|}
					-- The internal 'i_m' channels for every measure of «rule.name»
					MemoryInternalEvents = {|«FOR m : measures SEPARATOR ','»i_«m.name»«ENDFOR»|}
					-- Events of «rule.name» except for those of measures, and any unmapped SUV events:
					CommonProvideEvents = diff(union(A«rule.name»,diff(«gu.processId(a.element)»::sem__events,MappedRCEvents)),MemoryExternalEvents)
					-- The memory process
					Memory = «compileMeasureMemory(measures.toList)»
					-- Ordered reading
					MemoryInOrder = «IF measures.size > 0»«FOR m : measures SEPARATOR ' -> ' AFTER ' -> MemoryInOrder'»«m.name»?x__«ENDFOR»«ELSE»SKIP«ENDIF»
					-- Mapped events
					MappedRCEvents = {|«FOR e : mappedEvents(rule, a.element) SEPARATOR ','»«e»«ENDFOR»|}
					-- SLEEC rule renamed
					Rule = SLEEC«rule.name»
								«FOR m : measures BEFORE '[[' SEPARATOR ',' AFTER ']]'»
								«m.name» <- i_«m.name»
								«ENDFOR»
				within
					timed_priority(
						(
							(Rule ||| TRUN(diff(CommonProvideEvents,A«rule.name»)))
							[| union(CommonProvideEvents,MemoryInternalEvents) |]
							(
								Memory
								[| MemoryExternalEvents |]
								MemoryInOrder
							)
						) \ MemoryInternalEvents
					)
			
			«a.name»_suv =
				let
					-- The external 'm' channels for every measure of «rule.name»
					MemoryExternalEvents = {|«FOR m : measures SEPARATOR ','»«m.name»«ENDFOR»|}
					-- The internal 'i_m' channels for every measure of «rule.name»
					MemoryInternalEvents = {|«FOR m : measures SEPARATOR ','»i_«m.name»«ENDFOR»|}
					-- Events of «rule.name» except for those of measures, and any unmapped SUV events:
					CommonProvideEvents = diff(union(A«rule.name»,diff(«gu.processId(a.element)»::sem__events,MappedRCEvents)),MemoryExternalEvents)
					-- The memory process
					Memory = «compileMeasureMemory(measures)»
					-- Ordered reading
					MemoryInOrder = «IF measures.size > 0»«FOR m : measures SEPARATOR ' -> ' AFTER ' -> MemoryInOrder'»«m.name»?x__«ENDFOR»«ELSE»SKIP«ENDIF»
					-- Mapped events
					MappedRCEvents = {|«FOR e : mappedEvents(rule, a.element) SEPARATOR ','»«e»«ENDFOR»|}
					-- SUV renamed
					SUV = («renameSUV(a.element,rule,suvSemantics)»)
							«FOR m : measures BEFORE '[[' SEPARATOR ',' AFTER ']]'»
							«m.name» <- i_«m.name»
							«ENDFOR»
				within
					timed_priority(
						(
							(SUV ; STOP)
							[| union(CommonProvideEvents,MemoryInternalEvents) |]
							(
								Memory
								[| MemoryExternalEvents |]
								MemoryInOrder
							)
						) \ MemoryInternalEvents
					)
			
			}
			
			assert «IF a.negated»not «ENDIF»«a.name»_spec [T= «a.name»_suv
			'''
		}
	}
	

	
	def dispatch renameNamedElement(EObject obj, Event e, String t) {
		if (e.type === null) {
			'''«gu.processId(obj)»::«gu.eventId(e)».in <- «t»,«gu.processId(obj)»::«gu.eventId(e)».out <- «t»'''			
		} else {
			val bool = tp.getBooleanType(e)
			val eventType = e.type
			val type = if (eventType instanceof TypeRef) eventType.ref else eventType
			
			if (tp.isNumeric(eventType) || tp.typeCompatible(eventType, bool)) {
				'''«gu.processId(obj)»::«gu.eventId(e)».in <- «t»,«gu.processId(obj)»::«gu.eventId(e)».out <- «t»'''	
			} else if (type instanceof Enumeration) {
				'''
				«FOR l : type.literals SEPARATOR ','»
				«gu.processId(obj)»::«gu.eventId(e)».in.«gu.id(l)» <- «t».«l.name»,«gu.processId(obj)»::«gu.eventId(e)».out.«gu.id(l)» <- «t».«l.name»
				«ENDFOR»
				'''
			} else {
				throw new Exception("Unsupported type for event '" + e.name + "' while compiling SLEECAssertion.")
			} 
		}
	}
	
	def dispatch renameNamedElement(EObject obj, OperationSig op, String t) {
		'''«gu.processId(obj)»::«op.name»Call <- «t»'''
	}
	
	def dispatch renameNamedElement(EObject obj, EObject e, String t) {
		throw new Exception("renameNamedElement: unhandled case")
	}
	

	
	def dispatch renameSUV(StateMachine stm, Rule rule, String string) {
		
		val map = su.getNamedElementMap(stm,rule)
		
		'''
		(«string»\{|«gu.processId(stm)»::terminate|})«FOR p : map.keySet BEFORE '[[' SEPARATOR ',' AFTER ']]'»
		«renameNamedElement(stm,p,map.get(p))»
		«ENDFOR»
		'''
	}
	
	def dispatch renameSUV(Controller c, Rule rule, String string) {
		
		val map = su.getNamedElementMap(c,rule)
	
		'''
		(«string»\{|«gu.processId(c)»::terminate|})«FOR p : map.keySet BEFORE '[[' SEPARATOR ',' AFTER ']]'»
		«renameNamedElement(c,p,map.get(p))»
		«ENDFOR»
		'''
	}
	
	def dispatch renameSUV(RCModule m, Rule rule, String string) {
		
		val map = su.getNamedElementMap(m,rule)
		
		'''
		«string»«FOR p : map.keySet BEFORE '[[' SEPARATOR ',' AFTER ']]'»
		«renameNamedElement(m,p,map.get(p))»
		«ENDFOR»
		'''
	}	
	
	def dispatch renameSUV(NamedElement element, Rule rule, String string) {
		throw new Exception("Unhandled NamedElement when compiling SLEECAssertion.")
	}
	
	def dispatch mappedEvents(Rule rule, StateMachine stm) {
		
		val stmDef = if (stm instanceof StateMachineRef) stm.ref else stm as StateMachineDef
		var requiredOps = gu.requiredOperations(stmDef)
		var mapped = new HashSet<String>()
		val alphaRule = su.getAlphabet(rule)
		val events = gu.getEvents(stm)
		
		// Look at defined events
		for (e : events) {
			if (alphaRule.contains(e.name)) {
				mapped.add('''«gu.processId(stm)»::«gu.eventId(e)»''')
			}
		}
		
		// Look at required operations
		for (o : requiredOps) {
			if (alphaRule.contains(o.name)) {
				mapped.add('''«gu.processId(stm)»::«o.name»Call''')
			}
		}
		
		return mapped
	}
	
	def dispatch mappedEvents(Rule rule, Controller c) {
		
		val ctrl = if (c instanceof ControllerRef) c.ref else c as ControllerDef
		var requiredOps = gu.requiredOperations(ctrl)
		val events = gu.getEvents(ctrl)
		val alphaRule = su.getAlphabet(rule)
		var mapped = new HashSet<String>()
		
		// Look at defined events
		for (e : events) {
			if (alphaRule.contains(e.name)) {
				mapped.add('''«gu.processId(c)»::«gu.eventId(e)»''')
			}
		}
		
		// Look at required operations
		for (o : requiredOps) {
			if (alphaRule.contains(o.name)) {
				mapped.add('''«gu.processId(c)»::«o.name»Call''')
			}
		}
		
		return mapped
	}
	
	def dispatch mappedEvents(Rule rule, RCModule m) {
		
		val aux = m.nodes.filter(RoboticPlatform).get(0)
		val rp = if (aux instanceof RoboticPlatformRef) aux.ref else aux as RoboticPlatformDef
		var requiredOps = gu.requiredOperations(rp)
		val events = gu.allEvents(rp)
		val alphaRule = su.getAlphabet(rule)
		var mapped = new HashSet<String>()
		
		// Look at defined events
		for (e : events) {
			if (alphaRule.contains(e.name)) {
				mapped.add('''«gu.processId(m)»::«gu.eventId(e)»''')
			}
		}
		
		// Look at required operations
		for (o : requiredOps) {
			if (alphaRule.contains(o.name)) {
				mapped.add('''«gu.processId(m)»::«o.name»Call''')
			}
		}
		
		return mapped
	}
	
	
	def dispatch mappedEvents(Rule rule, NamedElement element) {
		return new HashSet<String>()
	}
	
	def CharSequence compileMeasureMemory(Iterable<Measure> m) {
		if (m.size > 1) {
			val element = m.head
			'''	
			(
				Mem_«element.name»(CommonProvideEvents)
				[| CommonProvideEvents |] 
				«compileMeasureMemory(m.tail)»
			)
			'''
		} else if (m.size == 1) {
			val element = m.head
			'''Mem_«element.name»(CommonProvideEvents)'''
		} else if (m.size == 0) {
			'''TRUN(CommonProvideEvents)'''
		}
	}
	
	override printAssertion(SLEECAssertion assertion, String suvID) {
		val rule = assertion.rule
		var ruleName = "unknown"
		if (rule instanceof Rule) {
			ruleName = rule.name
		}
		return '''«suvID» «IF assertion.negated»does not conform«ELSE»conforms«ENDIF» to «ruleName» [traces]'''
	}
	
	override calculateImports(EObject rule) {
		if (rule instanceof Rule) {
			return '''../../src-gen/«rule.eResource.getURI().trimFileExtension().lastSegment() + '.csp'»'''
		}
	}
	
}