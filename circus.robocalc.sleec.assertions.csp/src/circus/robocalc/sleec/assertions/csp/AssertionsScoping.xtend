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

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.scoping.impl.DelegatingScopeProvider
import org.eclipse.xtext.scoping.impl.FilteringScope
import circus.robocalc.sleec.sLEEC.Rule

class AssertionsScoping extends DelegatingScopeProvider implements IScopeProvider {
	
	override getScope(EObject context, EReference reference) {
		// Need to filter resourceset 
		val scope = delegateGetScope(context, reference)
		return new FilteringScope(scope, [e|e.EObjectOrProxy instanceof Rule])
	}
	
}