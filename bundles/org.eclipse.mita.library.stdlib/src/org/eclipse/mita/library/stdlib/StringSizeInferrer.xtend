/********************************************************************************
 * Copyright (c) 2017, 2018 Bosch Connected Devices and Solutions GmbH.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * Contributors:
 *    Bosch Connected Devices and Solutions GmbH - initial contribution
 *
 * SPDX-License-Identifier: EPL-2.0
 ********************************************************************************/

package org.eclipse.mita.library.stdlib

import com.google.inject.Inject
import org.eclipse.mita.base.expressions.StringLiteral
import org.eclipse.mita.base.types.InterpolatedStringLiteral
import org.eclipse.mita.base.types.validation.IValidationIssueAcceptor.ValidationIssue
import org.eclipse.mita.base.typesystem.StdlibTypeRegistry
import org.eclipse.mita.base.typesystem.constraints.EqualityConstraint
import org.eclipse.mita.base.typesystem.constraints.InterpolatedStringExpressionConstraint
import org.eclipse.mita.base.typesystem.constraints.SumConstraint
import org.eclipse.mita.base.typesystem.infra.InferenceContext
import org.eclipse.mita.base.typesystem.types.LiteralNumberType
import org.eclipse.mita.base.typesystem.types.TypeConstructorType
import org.eclipse.mita.base.typesystem.types.TypeVariable

import static org.eclipse.mita.program.inferrer.ProgramSizeInferrer.*

class StringSizeInferrer extends ArraySizeInferrer {
	@Inject
	StdlibTypeRegistry typeRegistry;
	
	override getDataTypeIndexes() {
		return #[];
	}
	
	override getSizeTypeIndexes() {
		return #[1];
	}
				
	dispatch def void doCreateConstraints(InferenceContext c, StringLiteral lit, TypeConstructorType type) {
		val u32 = typeRegistry.getTypeModelObject(lit, StdlibTypeRegistry.u32TypeQID);
		val u32Type = c.system.getTypeVariable(u32);
		c.system.associate(type, lit);
		c.system.addConstraint(new EqualityConstraint(type.typeArguments.last, new LiteralNumberType(lit, lit.value.length, u32Type), new ValidationIssue("%s is not %s", lit)))
	}

	dispatch def void doCreateConstraints(InferenceContext c, InterpolatedStringLiteral expr, TypeConstructorType type) {
		val u32 = typeRegistry.getTypeModelObject(expr, StdlibTypeRegistry.u32TypeQID);
		val u32Type = c.system.getTypeVariable(u32);
		val lengthText = new LiteralNumberType(expr, expr.sumTextParts, u32Type);
		
		// sum expression value part
		val sublengths = expr.content.map[subexpr |
			val result = c.system.newTypeVariable(subexpr);
			c.system.addConstraint(new InterpolatedStringExpressionConstraint(new ValidationIssue("", subexpr), subexpr, result, c.system.getTypeVariable(subexpr)));
			result;
		]

		c.system.associate(type, expr);
		c.system.addConstraint(new SumConstraint(typeVariableToTypeConstructorType(c, c.system.getTypeVariable(expr), type).typeArguments.last as TypeVariable, #[lengthText] + sublengths, new ValidationIssue("", expr)))
	}
		
	protected def long sumTextParts(InterpolatedStringLiteral expr) {
		val texts = StringGenerator.getOriginalTexts(expr)
		if (texts.nullOrEmpty) {
			0
		} else {
			texts.map[x | x.length as long ].reduce[x1, x2| x1 + x2 ];
		}
	}		
}