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

import circus.robocalc.robochart.Enumeration;
import circus.robocalc.robochart.Event;
import circus.robocalc.robochart.Literal;
import circus.robocalc.robochart.NamedElement;
import circus.robocalc.robochart.OperationSig;
import circus.robocalc.robochart.Type;
import circus.robocalc.robochart.TypeRef;
import circus.robocalc.robochart.assertions.assertions.AssertionsPackage;
import circus.robocalc.robochart.assertions.assertions.RAPackage;
import circus.robocalc.robochart.assertions.assertions.SLEECAssertion;
import circus.robocalc.robochart.textual.RoboCalcTypeProvider;
import circus.robocalc.sleec.sLEEC.Measure;
import circus.robocalc.sleec.sLEEC.Numeric;
import circus.robocalc.sleec.sLEEC.Rule;
import circus.robocalc.sleec.sLEEC.Scale;
import circus.robocalc.sleec.sLEEC.ScaleParam;
import com.google.common.base.Objects;
import com.google.common.collect.Iterables;
import com.google.inject.Inject;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.validation.AbstractDeclarativeValidator;
import org.eclipse.xtext.validation.Check;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

@SuppressWarnings("all")
public class AssertionsValidator extends AbstractDeclarativeValidator {
  @Inject
  private SLEECUtils _su;
  
  @Inject
  private RoboCalcTypeProvider _tp;
  
  protected SLEECUtils su() {
    return this._su;
  }
  
  protected RoboCalcTypeProvider tp() {
    return this._tp;
  }
  
  @Override
  public boolean isLanguageSpecific() {
    return false;
  }
  
  @Override
  public List<EPackage> getEPackages() {
    ArrayList<EPackage> result = new ArrayList<EPackage>();
    result.add(AssertionsPackage.eINSTANCE);
    return result;
  }
  
  @Check
  public void uniqueSLEECResourceReferenced(final RAPackage pkg) {
    final Function1<SLEECAssertion, Resource> _function = (SLEECAssertion it) -> {
      return it.getRule().eResource();
    };
    int _size = IterableExtensions.<Resource>toSet(IterableExtensions.<SLEECAssertion, Resource>map(Iterables.<SLEECAssertion>filter(pkg.getAssertions(), SLEECAssertion.class), _function)).size();
    boolean _greaterThan = (_size > 1);
    if (_greaterThan) {
      this.error("Referencing SLEEC rules from more than one .sleec resource is not currently supported.", AssertionsPackage.Literals.RA_PACKAGE__ASSERTIONS);
    }
  }
  
  @Check
  public void checkAllEventsProvided(final SLEECAssertion a) {
    final EObject rule = a.getRule();
    if ((rule instanceof Rule)) {
      final Set<Measure> measures = this.su().getMeasures(((Rule)rule));
      final HashSet<String> events = this.su().getEvents(((Rule)rule));
      final HashMap<NamedElement, String> mapped = this.su().getNamedElementMap(a.getElement(), ((Rule)rule));
      for (final String e : events) {
        boolean _containsValue = mapped.containsValue(e);
        boolean _not = (!_containsValue);
        if (_not) {
          String _name = a.getElement().getName();
          String _plus = ((("Capability \'" + e) + "\' not available in SUV \'") + _name);
          String _plus_1 = (_plus + "\'");
          this.error(_plus_1, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
        }
      }
      for (final Measure e_1 : measures) {
        boolean _containsValue_1 = mapped.containsValue(e_1.getName());
        boolean _not_1 = (!_containsValue_1);
        if (_not_1) {
          String _name_1 = e_1.getName();
          String _plus_2 = ("Measure \'" + _name_1);
          String _plus_3 = (_plus_2 + "\' not available in SUV \'");
          String _name_2 = a.getElement().getName();
          String _plus_4 = (_plus_3 + _name_2);
          String _plus_5 = (_plus_4 + "\'");
          this.warning(_plus_5, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
        }
      }
    }
  }
  
  @Check
  public void checkMeasuresWellTyped(final SLEECAssertion a) {
    final EObject rule = a.getRule();
    if ((rule instanceof Rule)) {
      final Set<Measure> measures = this.su().getMeasures(((Rule)rule));
      final HashMap<NamedElement, String> mapped = this.su().getNamedElementMap(a.getElement(), ((Rule)rule));
      for (final Measure e : measures) {
        boolean _containsValue = mapped.containsValue(e.getName());
        if (_containsValue) {
          final Function1<Map.Entry<NamedElement, String>, Boolean> _function = (Map.Entry<NamedElement, String> l) -> {
            String _value = l.getValue();
            String _name = e.getName();
            return Boolean.valueOf(Objects.equal(_value, _name));
          };
          final Map.Entry<NamedElement, String> entry = IterableExtensions.<Map.Entry<NamedElement, String>>head(IterableExtensions.<Map.Entry<NamedElement, String>>filter(mapped.entrySet(), _function));
          if ((entry != null)) {
            final NamedElement element = entry.getKey();
            if ((element instanceof Event)) {
              this.wellTypedMeasure(a, ((Event)element), e);
            }
          }
        }
      }
    }
  }
  
  @Check
  public void checkEventsWellTyped(final SLEECAssertion a) {
    final EObject rule = a.getRule();
    if ((rule instanceof Rule)) {
      final HashSet<String> events = this.su().getEvents(((Rule)rule));
      final HashMap<NamedElement, String> mapped = this.su().getNamedElementMap(a.getElement(), ((Rule)rule));
      for (final String e : events) {
        boolean _containsValue = mapped.containsValue(e);
        if (_containsValue) {
          final Function1<Map.Entry<NamedElement, String>, Boolean> _function = (Map.Entry<NamedElement, String> l) -> {
            String _value = l.getValue();
            return Boolean.valueOf(Objects.equal(_value, e));
          };
          final Map.Entry<NamedElement, String> entry = IterableExtensions.<Map.Entry<NamedElement, String>>head(IterableExtensions.<Map.Entry<NamedElement, String>>filter(mapped.entrySet(), _function));
          if ((entry != null)) {
            final NamedElement element = entry.getKey();
            if ((element instanceof Event)) {
              Type _type = ((Event)element).getType();
              boolean _tripleNotEquals = (_type != null);
              if (_tripleNotEquals) {
                String _name = a.getElement().getName();
                String _plus = ((("Event \'" + e) + "\' is typed SUV \'") + _name);
                String _plus_1 = (_plus + "\'. This is not currently supported.");
                this.error(_plus_1, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
              }
            } else {
              if ((element instanceof OperationSig)) {
                int _size = ((OperationSig)element).getParameters().size();
                boolean _greaterThan = (_size > 0);
                if (_greaterThan) {
                  String _name_1 = a.getElement().getName();
                  String _plus_2 = ((("Operation \'" + e) + "\' has parameters in SUV \'") + _name_1);
                  String _plus_3 = (_plus_2 + "\'. This is not currently supported.");
                  this.error(_plus_3, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
                }
              }
            }
          }
        }
      }
    }
  }
  
  public Object wellTypedMeasure(final SLEECAssertion a, final Event e, final Measure m) {
    Object _xifexpression = null;
    if (((e.getType() == null) && (m.getType() == null))) {
      _xifexpression = null;
    } else {
      if (((e.getType() == null) && (m.getType() != null))) {
        String _name = m.getName();
        String _plus = ("Measure \'" + _name);
        String _plus_1 = (_plus + "\' is not typed, while SUV event \'");
        String _name_1 = e.getName();
        String _plus_2 = (_plus_1 + _name_1);
        String _plus_3 = (_plus_2 + "\' is typed.");
        this.error(_plus_3, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
      } else {
        if (((e.getType() != null) && (m.getType() == null))) {
          String _name_2 = m.getName();
          String _plus_4 = ("Measure \'" + _name_2);
          String _plus_5 = (_plus_4 + "\' has no type, while SUV event \'");
          String _name_3 = e.getName();
          String _plus_6 = (_plus_5 + _name_3);
          String _plus_7 = (_plus_6 + "\' is typed.");
          this.error(_plus_7, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
        } else {
          if (((e.getType() != null) && (m.getType() != null))) {
            final Type bool = this.tp().getBooleanType(e);
            final Type eventType = e.getType();
            EObject _xifexpression_1 = null;
            if ((eventType instanceof TypeRef)) {
              _xifexpression_1 = ((TypeRef)eventType).getRef();
            } else {
              _xifexpression_1 = eventType;
            }
            final EObject type = _xifexpression_1;
            if ((this.tp().isNumeric(eventType) && (!(m.getType() instanceof Numeric)))) {
              String _name_4 = m.getName();
              String _plus_8 = ("Measure \'" + _name_4);
              String _plus_9 = (_plus_8 + "\' is not of numeric type, but SUV event \'");
              String _name_5 = e.getName();
              String _plus_10 = (_plus_9 + _name_5);
              String _plus_11 = (_plus_10 + "\' is.");
              this.error(_plus_11, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
            } else {
              if (((!this.tp().isNumeric(eventType)) && (m.getType() instanceof Numeric))) {
                String _name_6 = m.getName();
                String _plus_12 = ("Measure \'" + _name_6);
                String _plus_13 = (_plus_12 + "\' is of numeric type, but SUV event \'");
                String _name_7 = e.getName();
                String _plus_14 = (_plus_13 + _name_7);
                String _plus_15 = (_plus_14 + "\' is not.");
                this.error(_plus_15, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
              }
            }
            if (((this.tp().typeCompatible(eventType, bool)).booleanValue() && (!(m.getType() instanceof circus.robocalc.sleec.sLEEC.Boolean)))) {
              String _name_8 = m.getName();
              String _plus_16 = ("Measure \'" + _name_8);
              String _plus_17 = (_plus_16 + "\' is not of boolean type, but SUV event \'");
              String _name_9 = e.getName();
              String _plus_18 = (_plus_17 + _name_9);
              String _plus_19 = (_plus_18 + "\' is.");
              this.error(_plus_19, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
            } else {
              if (((!(this.tp().typeCompatible(eventType, bool)).booleanValue()) && (m.getType() instanceof circus.robocalc.sleec.sLEEC.Boolean))) {
                String _name_10 = m.getName();
                String _plus_20 = ("Measure \'" + _name_10);
                String _plus_21 = (_plus_20 + "\' is of boolean type, but SUV event \'");
                String _name_11 = e.getName();
                String _plus_22 = (_plus_21 + _name_11);
                String _plus_23 = (_plus_22 + "\' is not.");
                this.error(_plus_23, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
              }
            }
            if (((type instanceof Enumeration) && (m.getType() instanceof Scale))) {
              final Enumeration en = ((Enumeration) type);
              circus.robocalc.sleec.sLEEC.Type _type = m.getType();
              final Scale sps = ((Scale) _type);
              EList<ScaleParam> _scaleParams = sps.getScaleParams();
              for (final ScaleParam sp : _scaleParams) {
                final Function1<Literal, Boolean> _function = (Literal l) -> {
                  return Boolean.valueOf((Objects.equal(l.getName(), sp.getName()) && (l.getTypes().size() == 0)));
                };
                boolean _exists = IterableExtensions.<Literal>exists(en.getLiterals(), _function);
                boolean _not = (!_exists);
                if (_not) {
                  String _name_12 = m.getName();
                  String _plus_24 = ("Measure \'" + _name_12);
                  String _plus_25 = (_plus_24 + "\' is has scale type with literal \'");
                  String _name_13 = sp.getName();
                  String _plus_26 = (_plus_25 + _name_13);
                  String _plus_27 = (_plus_26 + "\' without corresponding literal in SUV enumerated type of the same name.");
                  this.error(_plus_27, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
                }
              }
            } else {
              if (((!(type instanceof Enumeration)) && (m.getType() instanceof Scale))) {
                String _name_14 = m.getName();
                String _plus_28 = ("Measure \'" + _name_14);
                String _plus_29 = (_plus_28 + "\' is not scale type, but SUV event \'");
                String _name_15 = e.getName();
                String _plus_30 = (_plus_29 + _name_15);
                String _plus_31 = (_plus_30 + "\' is not.");
                this.error(_plus_31, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
              } else {
                if (((type instanceof Enumeration) && (!(m.getType() instanceof Scale)))) {
                  String _name_16 = m.getName();
                  String _plus_32 = ("Measure \'" + _name_16);
                  String _plus_33 = (_plus_32 + "\' is not of scale type, but SUV event \'");
                  String _name_17 = e.getName();
                  String _plus_34 = (_plus_33 + _name_17);
                  String _plus_35 = (_plus_34 + "\' is.");
                  this.error(_plus_35, a, AssertionsPackage.Literals.SLEEC_ASSERTION__RULE);
                }
              }
            }
          }
        }
      }
    }
    return _xifexpression;
  }
}
