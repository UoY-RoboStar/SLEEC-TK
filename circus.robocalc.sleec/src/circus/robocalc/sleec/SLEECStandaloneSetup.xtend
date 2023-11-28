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
package circus.robocalc.sleec


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class SLEECStandaloneSetup extends SLEECStandaloneSetupGenerated {

	def static void doSetup() {
		new SLEECStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
