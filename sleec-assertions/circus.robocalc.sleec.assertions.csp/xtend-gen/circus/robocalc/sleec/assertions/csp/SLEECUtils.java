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

import circus.robocalc.robochart.Controller;
import circus.robocalc.robochart.ControllerDef;
import circus.robocalc.robochart.ControllerRef;
import circus.robocalc.robochart.Event;
import circus.robocalc.robochart.NamedElement;
import circus.robocalc.robochart.OperationSig;
import circus.robocalc.robochart.RCModule;
import circus.robocalc.robochart.RoboticPlatform;
import circus.robocalc.robochart.RoboticPlatformDef;
import circus.robocalc.robochart.RoboticPlatformRef;
import circus.robocalc.robochart.StateMachine;
import circus.robocalc.robochart.StateMachineDef;
import circus.robocalc.robochart.StateMachineRef;
import circus.robocalc.robochart.generator.csp.comp.untimed.CGeneratorUtils;
import circus.robocalc.sleec.sLEEC.Atom;
import circus.robocalc.sleec.sLEEC.Constraint;
import circus.robocalc.sleec.sLEEC.Measure;
import circus.robocalc.sleec.sLEEC.Rule;
import com.google.common.collect.Iterables;
import com.google.common.collect.Iterators;
import com.google.inject.Inject;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.IteratorExtensions;

@SuppressWarnings("all")
public class SLEECUtils {
  @Inject
  private CGeneratorUtils _gu;
  
  @Inject
  private SLEECUtils _su;
  
  protected CGeneratorUtils gu() {
    return this._gu;
  }
  
  protected SLEECUtils su() {
    return this._su;
  }
  
  protected <T extends EObject> List<String> alphaE(final T AST) {
    Collection<Constraint> _xifexpression = null;
    if ((AST instanceof Constraint)) {
      _xifexpression = Collections.<Constraint>singleton(((Constraint) AST));
    } else {
      _xifexpression = IteratorExtensions.<Constraint>toList(Iterators.<Constraint>filter(AST.eAllContents(), Constraint.class));
    }
    final Iterable<Constraint> leaves = _xifexpression;
    final Function1<Constraint, String> _function = (Constraint it) -> {
      return it.getEvent().getName();
    };
    return IterableExtensions.<String>toList(IterableExtensions.<Constraint, String>map(leaves, _function));
  }
  
  public Set<Measure> getMeasures(final Rule r) {
    final Function1<Atom, String> _function = (Atom it) -> {
      return it.getMeasureID();
    };
    final Set<String> measures = IteratorExtensions.<String>toSet(IteratorExtensions.<Atom, String>map(Iterators.<Atom>filter(r.eAllContents(), Atom.class), _function));
    final Resource resource = r.eResource();
    final Set<Measure> allMeasures = IteratorExtensions.<Measure>toSet(Iterators.<Measure>filter(resource.getAllContents(), Measure.class));
    final Function1<Measure, Boolean> _function_1 = (Measure m) -> {
      return Boolean.valueOf(measures.contains(m.getName()));
    };
    return IterableExtensions.<Measure>toSet(IterableExtensions.<Measure>filter(allMeasures, _function_1));
  }
  
  public HashSet<String> getEvents(final Rule r) {
    HashSet<String> ruleAlphabet = new HashSet<String>();
    ruleAlphabet.add(r.getTrigger().getEvent().getName());
    ruleAlphabet.addAll(this.<Rule>alphaE(r));
    return ruleAlphabet;
  }
  
  public HashSet<String> getAlphabet(final Rule r) {
    HashSet<String> ruleAlphabet = new HashSet<String>();
    ruleAlphabet.add(r.getTrigger().getEvent().getName());
    ruleAlphabet.addAll(this.<Rule>alphaE(r));
    final Function1<Measure, String> _function = (Measure it) -> {
      return it.getName();
    };
    Iterables.<String>addAll(ruleAlphabet, IterableExtensions.<Measure, String>map(this.getMeasures(r), _function));
    return ruleAlphabet;
  }
  
  protected HashMap<NamedElement, String> _getNamedElementMap(final StateMachine stm, final Rule rule) {
    StateMachineDef _xifexpression = null;
    if ((stm instanceof StateMachineRef)) {
      _xifexpression = ((StateMachineRef)stm).getRef();
    } else {
      _xifexpression = ((StateMachineDef) stm);
    }
    final StateMachineDef stmDef = _xifexpression;
    Set<OperationSig> requiredOps = this.gu().requiredOperations(stmDef);
    final LinkedList<Event> events = this.gu().getEvents(stmDef);
    final HashSet<String> alphaRule = this.su().getAlphabet(rule);
    HashMap<NamedElement, String> map = new HashMap<NamedElement, String>();
    for (final Event e : events) {
      boolean _contains = alphaRule.contains(e.getName());
      if (_contains) {
        map.put(e, e.getName());
      }
    }
    for (final OperationSig o : requiredOps) {
      boolean _contains_1 = alphaRule.contains(o.getName());
      if (_contains_1) {
        map.put(o, o.getName());
      }
    }
    return map;
  }
  
  protected HashMap<NamedElement, String> _getNamedElementMap(final Controller c, final Rule rule) {
    ControllerDef _xifexpression = null;
    if ((c instanceof ControllerRef)) {
      _xifexpression = ((ControllerRef)c).getRef();
    } else {
      _xifexpression = ((ControllerDef) c);
    }
    final ControllerDef ctrl = _xifexpression;
    Set<OperationSig> requiredOps = this.gu().requiredOperations(ctrl);
    final LinkedList<Event> events = this.gu().getEvents(ctrl);
    final HashSet<String> alphaRule = this.su().getAlphabet(rule);
    HashMap<NamedElement, String> map = new HashMap<NamedElement, String>();
    for (final Event e : events) {
      boolean _contains = alphaRule.contains(e.getName());
      if (_contains) {
        map.put(e, e.getName());
      }
    }
    for (final OperationSig o : requiredOps) {
      boolean _contains_1 = alphaRule.contains(o.getName());
      if (_contains_1) {
        map.put(o, o.getName());
      }
    }
    return map;
  }
  
  protected HashMap<NamedElement, String> _getNamedElementMap(final RCModule m, final Rule rule) {
    final RoboticPlatform aux = ((RoboticPlatform[])Conversions.unwrapArray((Iterables.<RoboticPlatform>filter(m.getNodes(), RoboticPlatform.class)), RoboticPlatform.class))[0];
    RoboticPlatformDef _xifexpression = null;
    if ((aux instanceof RoboticPlatformRef)) {
      _xifexpression = ((RoboticPlatformRef)aux).getRef();
    } else {
      _xifexpression = ((RoboticPlatformDef) aux);
    }
    final RoboticPlatformDef rp = _xifexpression;
    ArrayList<OperationSig> allOps = this.gu().allOperations(rp);
    final ArrayList<Event> events = this.gu().allEvents(rp);
    final HashSet<String> alphaRule = this.su().getAlphabet(rule);
    HashMap<NamedElement, String> map = new HashMap<NamedElement, String>();
    for (final Event e : events) {
      boolean _contains = alphaRule.contains(e.getName());
      if (_contains) {
        map.put(e, e.getName());
      }
    }
    for (final OperationSig o : allOps) {
      boolean _contains_1 = alphaRule.contains(o.getName());
      if (_contains_1) {
        map.put(o, o.getName());
      }
    }
    return map;
  }
  
  public HashMap<NamedElement, String> getNamedElementMap(final NamedElement c, final Rule rule) {
    if (c instanceof Controller) {
      return _getNamedElementMap((Controller)c, rule);
    } else if (c instanceof RCModule) {
      return _getNamedElementMap((RCModule)c, rule);
    } else if (c instanceof StateMachine) {
      return _getNamedElementMap((StateMachine)c, rule);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(c, rule).toString());
    }
  }
}
