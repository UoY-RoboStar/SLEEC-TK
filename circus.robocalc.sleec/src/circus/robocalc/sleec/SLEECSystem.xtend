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

import circus.robocalc.sleec.sLEEC.Constant
import circus.robocalc.sleec.sLEEC.Measure
import circus.robocalc.sleec.sLEEC.Numeric
import circus.robocalc.sleec.sLEEC.Scale
import circus.robocalc.sleec.sLEEC.Specification
import circus.robocalc.sleec.sLEEC.Value
import java.util.List
import java.util.Map
import java.util.Set
import circus.robocalc.sleec.sLEEC.Atom
import circus.robocalc.sleec.sLEEC.MBoolExpr
import circus.robocalc.sleec.sLEEC.BoolValue
import circus.robocalc.sleec.sLEEC.Not
import circus.robocalc.sleec.sLEEC.BoolComp
import circus.robocalc.sleec.sLEEC.RelComp

class SLEECSystem {
	public Set<String> numerics
	public Map<String, Integer> constants
	public Map<String, List<String>> scales
	public Set<String> booleans
	Set<String> scaleParams

	new(Specification s) {
		val defBlock = s.defBlock

		numerics = defBlock.eAllContents
			.filter(Measure)
			.filter[type instanceof Numeric]
			.map[name]
			.toSet

		constants = defBlock.eAllContents
			.filter(Constant)
			.toMap([name], [eval(value)])

		scales = defBlock.eAllContents
			.filter(Measure)
			.filter[type instanceof Scale]
			.toMap([name], [(type as Scale).scaleParams.map[name]])
			
		scaleParams = scales.values.flatten.toSet

		booleans = defBlock.eAllContents
			.filter(Measure)
			.filter[type instanceof circus.robocalc.sleec.sLEEC.Boolean]
			.map[name]
			.toSet
	}

	def isNumeric(String s) {
		numerics.contains(s) || constants.keySet.contains(s)
	}

	def isNumeric(MBoolExpr expr) {
		switch (expr) {
			Value: true
			Atom: isNumeric(expr.measureID)
			default: false
		}
	}

	def isScale(String s) {
		isScaleID(s) || isScaleParam(s)
	}

	def isScaleID(String s) {
		scales.keySet.contains(s)
	}

	def isScaleParam(String s) {
		scaleParams.contains(s)
	}

	def isScale(MBoolExpr expr) {
		isScaleID(expr) || isScaleParam(expr)
	}

	def isScaleID(MBoolExpr expr) {
		switch (expr) {
			Atom: isScaleID(expr.measureID)
			default: false
		}
	}

	def isBoolean(String s) {
		booleans.contains(s)
	}

	def isBoolean(MBoolExpr expr) {
		switch (expr) {
			circus.robocalc.sleec.sLEEC.Boolean,
			BoolValue,
			Not,
			BoolComp,
			RelComp: true
			Atom: isBoolean(expr.measureID)
			default: false
		}
	}	
	
	def isScaleParam(MBoolExpr expr) {
		switch (expr) {
			Atom: isScaleParam(expr.measureID)
			default: false
		}
	}
	
	
	def Integer eval(Value value) {
		if (value === null)
			Integer.MAX_VALUE
		else
			switch (value) {
				case Constant: eval(value)
				default: value.value
			}
	}
	
	def Integer eval(MBoolExpr expr) {
		switch (expr) {
			Value: eval(expr)
		}
	}
}
