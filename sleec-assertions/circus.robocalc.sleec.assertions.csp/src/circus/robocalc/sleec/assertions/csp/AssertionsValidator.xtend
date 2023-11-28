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

class AssertionsValidator extends AbstractDeclarativeValidator {
	
	@Inject SLEECUtils _su
	protected def su() { _su }
	
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

}