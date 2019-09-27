/********************************************************************************
 * Copyright (c) 2018, 2019 Robert Bosch GmbH & TypeFox GmbH
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * Contributors:
 *    Robert Bosch GmbH & TypeFox GmbH - initial contribution
 *
 * SPDX-License-Identifier: EPL-2.0
 ********************************************************************************/

package org.eclipse.mita.base.typesystem.constraints

import org.eclipse.mita.base.types.validation.IValidationIssueAcceptor.ValidationIssue
import org.eclipse.mita.base.typesystem.infra.NicerTypeVariableNamesForErrorMessages
import org.eclipse.mita.base.typesystem.solver.ConstraintSystem
import org.eclipse.mita.base.typesystem.types.AbstractType
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.EqualsHashCode

@Accessors
@EqualsHashCode
class EqualityConstraint extends AbstractTypeConstraint {
	protected final AbstractType left;
	protected final AbstractType right;

	new(AbstractType left, AbstractType right, ValidationIssue source) {
		super(source);
		this.left = left;
		this.right = right;
		if(left === null || right === null || source === null) {
			throw new NullPointerException;
		}
	}
	
	override getErrorMessage() {
		val formatter = new NicerTypeVariableNamesForErrorMessages;
		val types = this.modifyNames(formatter) as EqualityConstraint;
		return new ValidationIssue(_errorMessage, String.format(_errorMessage.message, types.left, types.right));
	}

	override toString() {
		left + " ≡ " + right
	}
		
	override getTypes() {
		return #[left, right];
	}
	
	override toGraphviz() {
		return '''"«left»" -> "«right»" [dir=both]; «left.toGraphviz» «right.toGraphviz»''';
	}
			
	override map((AbstractType)=>AbstractType f) {
		val newL = f.apply(left);
		val newR = f.apply(right);
		if(left !== newL || right !== newR) {
			return new EqualityConstraint(newL, newR, _errorMessage);
		} 
		return this;
	}
	
	override getOperator() {
		return "≡"
	}
	
	override isAtomic(ConstraintSystem system) {
		return false;
	}
	
	override hasProxy() {
		return left.hasProxy || right.hasProxy
	}
	
}