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

import org.eclipse.xtext.validation.Check
import circus.robocalc.robochart.assertions.assertions.RAPackage
import circus.robocalc.robochart.assertions.assertions.SLEECAssertion
import circus.robocalc.robochart.assertions.assertions.AssertionsPackage
import org.eclipse.emf.ecore.EPackage
import java.util.ArrayList
import org.eclipse.xtext.validation.AbstractDeclarativeValidator
import com.google.inject.Inject
import circus.robocalc.sleec.sLEEC.Rule
import org.eclipse.emf.ecore.EObject
import circus.robocalc.sleec.sLEEC.Measure
import circus.robocalc.robochart.Event
import circus.robocalc.robochart.textual.RoboCalcTypeProvider
import circus.robocalc.robochart.TypeRef
import circus.robocalc.sleec.sLEEC.Numeric
import circus.robocalc.sleec.sLEEC.Scale
import circus.robocalc.robochart.Enumeration
import circus.robocalc.robochart.Type
import circus.robocalc.robochart.OperationSig

class AssertionsValidator extends AbstractDeclarativeValidator {
	
	@Inject SLEECUtils _su
	@Inject RoboCalcTypeProvider _tp
	protected def su() { _su }
	protected def tp() { _tp }
	
	override isLanguageSpecific() {
		return false; 
		// This needs to be false as otherwise the super class has 'SLEEC' as injected by Xtext 
		// and we do want to validate assertions here, not SLEEC language models. 
	}
	
	override getEPackages() {
		var result = new ArrayList<EPackage>();
		result.add(circus.robocalc.robochart.assertions.assertions.AssertionsPackage.eINSTANCE);
		return result;
	}
	
	@Check
	def uniqueSLEECResourceReferenced(RAPackage pkg)
	{
		if (pkg.assertions.filter(SLEECAssertion).map[rule.eResource].toSet.size > 1) {
			error('Referencing SLEEC rules from more than one .sleec resource is not currently supported.', AssertionsPackage.Literals.RA_PACKAGE__ASSERTIONS)
		}
	}
	
	// FIXME: Check that all events and measures used by a rule are also
	//		  defined/provided by the model being verified.
	@Check
	def checkAllEventsProvided(SLEECAssertion a) {
		val rule = a.rule
		if (rule instanceof Rule) {
			val measures = su.getMeasures(rule)
			val events = su.getEvents(rule)
			val mapped = su.getNamedElementMap(a.element,rule)
			for (e : events) {
				if (!mapped.containsValue(e)) {
					error("Capability '" + e + "' not available in SUV '" + a.element.name + "'", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE)
				}
			}
			for (e : measures) {
				if (!mapped.containsValue(e.name)) {
					warning("Measure '" + e.name + "' not available in SUV '" + a.element.name + "'", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE)
				}
			}
		}
	}
	
	@Check
	def checkMeasuresWellTyped(SLEECAssertion a) {
		val rule = a.rule
		if (rule instanceof Rule) {
			val measures = su.getMeasures(rule)
			val mapped = su.getNamedElementMap(a.element,rule)
			for (e: measures) {
				if (mapped.containsValue(e.name)) {
					// Assume injective map
					val entry = mapped.entrySet.filter[l|l.value == e.name].head
					if (entry !== null) {
						val element = entry.key
						if (element instanceof Event) {
							wellTypedMeasure(a,element,e)
						}	
					}
				}
			}
		}
	}
	
	@Check
	def checkEventsWellTyped(SLEECAssertion a) {
		val rule = a.rule
		if (rule instanceof Rule) {
			val events = su.getEvents(rule)
			val mapped = su.getNamedElementMap(a.element,rule)
			for (e: events) {
				if (mapped.containsValue(e)) {
					// Assume injective map
					val entry = mapped.entrySet.filter[l|l.value == e].head
					if (entry !== null) {
						val element = entry.key
						if (element instanceof Event) {
							if (element.type !== null) {
								error("Event '" + e + "' is typed SUV '" + a.element.name + "'. This is not currently supported.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE)
							}
						} else if (element instanceof OperationSig) {
							if (element.parameters.size > 0) {
								error("Operation '" + e + "' has parameters in SUV '" + a.element.name + "'. This is not currently supported.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE)
							}
						}
					}
				}
			}
		}
	}
	
	def wellTypedMeasure(SLEECAssertion a, Event e, Measure m) {
		if (e.type === null && m.type === null) {
			// Nothing to do, type ok.
		} else if (e.type === null && m.type !== null) {
			error("Measure '" + m.name  + "' is not typed, while SUV event '" + e.name + "' is typed.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
		} else if (e.type !== null && m.type === null) {
			error("Measure '" + m.name  + "' has no type, while SUV event '" + e.name + "' is typed.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
		} else if (e.type !== null && m.type !== null) {
			// Both have types. Are they compatible?
			val bool = tp.getBooleanType(e)
			val eventType = e.type
			val type = if (eventType instanceof TypeRef) eventType.ref else eventType
			
			
			
			// Numeric types
			if (tp.isNumeric(eventType) && !(m.type instanceof Numeric)) {
				error("Measure '" + m.name  + "' is not of numeric type, but SUV event '" + e.name + "' is.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
			} else if (!tp.isNumeric(eventType) && (m.type instanceof Numeric)) {
				error("Measure '" + m.name  + "' is of numeric type, but SUV event '" + e.name + "' is not.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
			}
			
			// Boolean types
			if (tp.typeCompatible(eventType, bool) && !(m.type instanceof circus.robocalc.sleec.sLEEC.Boolean)) {
				error("Measure '" + m.name  + "' is not of boolean type, but SUV event '" + e.name + "' is.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
			} else if (!tp.typeCompatible(eventType, bool) && (m.type instanceof circus.robocalc.sleec.sLEEC.Boolean)) {
				error("Measure '" + m.name  + "' is of boolean type, but SUV event '" + e.name + "' is not.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
			}
			
			// Scalar types
			if (type instanceof Enumeration && m.type instanceof Scale) {
				val en = (type as Enumeration)
				val sps = (m.type as Scale)
				for (sp : sps.scaleParams) {
					if (!en.literals.exists[l|l.name == sp.name && l.types.size == 0]) {
						error("Measure '" + m.name  + "' is has scale type with literal '" + sp.name + "' without corresponding literal in SUV enumerated type of the same name.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
					}
				}
			} else if (!(type instanceof Enumeration) && m.type instanceof Scale) {
				error("Measure '" + m.name  + "' is not scale type, but SUV event '" + e.name + "' is not.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
			} else if ((type instanceof Enumeration) && !(m.type instanceof Scale)) {
				error("Measure '" + m.name  + "' is not of scale type, but SUV event '" + e.name + "' is.", a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
			}
		}
	}
	
}