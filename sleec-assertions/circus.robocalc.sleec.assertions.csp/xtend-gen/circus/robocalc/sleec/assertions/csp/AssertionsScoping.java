/**
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
 */
package circus.robocalc.sleec.assertions.csp;

import circus.robocalc.sleec.sLEEC.Rule;
import com.google.common.base.Predicate;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.resource.IEObjectDescription;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.IScopeProvider;
import org.eclipse.xtext.scoping.impl.DelegatingScopeProvider;
import org.eclipse.xtext.scoping.impl.FilteringScope;

@SuppressWarnings("all")
public class AssertionsScoping extends DelegatingScopeProvider implements IScopeProvider {
  @Override
  public IScope getScope(final EObject context, final EReference reference) {
    final IScope scope = this.delegateGetScope(context, reference);
    final Predicate<IEObjectDescription> _function = (IEObjectDescription e) -> {
      EObject _eObjectOrProxy = e.getEObjectOrProxy();
      return (_eObjectOrProxy instanceof Rule);
    };
    return new FilteringScope(scope, _function);
  }
}
