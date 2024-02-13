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
import circus.robocalc.robochart.Enumeration;
import circus.robocalc.robochart.Event;
import circus.robocalc.robochart.Literal;
import circus.robocalc.robochart.NamedElement;
import circus.robocalc.robochart.OperationSig;
import circus.robocalc.robochart.RCModule;
import circus.robocalc.robochart.RoboticPlatform;
import circus.robocalc.robochart.RoboticPlatformDef;
import circus.robocalc.robochart.RoboticPlatformRef;
import circus.robocalc.robochart.StateMachine;
import circus.robocalc.robochart.StateMachineDef;
import circus.robocalc.robochart.StateMachineRef;
import circus.robocalc.robochart.Type;
import circus.robocalc.robochart.TypeRef;
import circus.robocalc.robochart.assertions.assertions.SLEECAssertion;
import circus.robocalc.robochart.generator.csp.comp.untimed.CGeneratorUtils;
import circus.robocalc.robochart.generator.csp.ext.ISLEECConformanceGenerator;
import circus.robocalc.robochart.textual.RoboCalcTypeProvider;
import circus.robocalc.sleec.generator.SLEECGenerator;
import circus.robocalc.sleec.sLEEC.Measure;
import circus.robocalc.sleec.sLEEC.Rule;
import com.google.common.collect.Iterables;
import com.google.inject.Inject;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Set;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

@SuppressWarnings("all")
public class AssertionsGenerator extends SLEECGenerator implements ISLEECConformanceGenerator {
  @Inject
  private CGeneratorUtils _gu;
  
  @Inject
  private RoboCalcTypeProvider _tp;
  
  @Inject
  private SLEECUtils _su;
  
  protected CGeneratorUtils gu() {
    return this._gu;
  }
  
  protected RoboCalcTypeProvider tp() {
    return this._tp;
  }
  
  protected SLEECUtils su() {
    return this._su;
  }
  
  @Override
  public String generateAssertion(final SLEECAssertion a, final String suvSemantics) {
    final EObject rule = a.getRule();
    if ((rule instanceof Rule)) {
      final Set<Measure> measures = this.su().getMeasures(((Rule)rule));
      StringConcatenation _builder = new StringConcatenation();
      final String suvEvents = _builder.toString();
      StringConcatenation _builder_1 = new StringConcatenation();
      _builder_1.append("-- Datatype mappings");
      _builder_1.newLine();
      _builder_1.newLine();
      _builder_1.append("-- Specification");
      _builder_1.newLine();
      _builder_1.append("Timed(OneStep) {");
      _builder_1.newLine();
      _builder_1.newLine();
      String _name = a.getName();
      _builder_1.append(_name);
      _builder_1.append("_spec = ");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t");
      _builder_1.append("let");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("-- The external \'m\' channels for every measure of ");
      String _name_1 = ((Rule)rule).getName();
      _builder_1.append(_name_1, "\t\t");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("MemoryExternalEvents = {|");
      {
        boolean _hasElements = false;
        for(final Measure m : measures) {
          if (!_hasElements) {
            _hasElements = true;
          } else {
            _builder_1.appendImmediate(",", "\t\t");
          }
          String _name_2 = m.getName();
          _builder_1.append(_name_2, "\t\t");
        }
      }
      _builder_1.append("|}");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- The internal \'i_m\' channels for every measure of ");
      String _name_3 = ((Rule)rule).getName();
      _builder_1.append(_name_3, "\t\t");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("MemoryInternalEvents = {|");
      {
        boolean _hasElements_1 = false;
        for(final Measure m_1 : measures) {
          if (!_hasElements_1) {
            _hasElements_1 = true;
          } else {
            _builder_1.appendImmediate(",", "\t\t");
          }
          _builder_1.append("i_");
          String _name_4 = m_1.getName();
          _builder_1.append(_name_4, "\t\t");
        }
      }
      _builder_1.append("|}");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- Events of ");
      String _name_5 = ((Rule)rule).getName();
      _builder_1.append(_name_5, "\t\t");
      _builder_1.append(" except for those of measures, and any unmapped SUV events:");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("CommonProvideEvents = diff(union(A");
      String _name_6 = ((Rule)rule).getName();
      _builder_1.append(_name_6, "\t\t");
      _builder_1.append(",diff(");
      String _processId = this.gu().processId(a.getElement());
      _builder_1.append(_processId, "\t\t");
      _builder_1.append("::sem__events,MappedRCEvents)),MemoryExternalEvents)");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- The memory process");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("Memory = ");
      CharSequence _compileMeasureMemory = this.compileMeasureMemory(IterableExtensions.<Measure>toList(measures));
      _builder_1.append(_compileMeasureMemory, "\t\t");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- Ordered reading");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("MemoryInOrder = ");
      {
        int _size = measures.size();
        boolean _greaterThan = (_size > 0);
        if (_greaterThan) {
          {
            boolean _hasElements_2 = false;
            for(final Measure m_2 : measures) {
              if (!_hasElements_2) {
                _hasElements_2 = true;
              } else {
                _builder_1.appendImmediate(" -> ", "\t\t");
              }
              String _name_7 = m_2.getName();
              _builder_1.append(_name_7, "\t\t");
              _builder_1.append("?x__");
            }
            if (_hasElements_2) {
              _builder_1.append(" -> MemoryInOrder", "\t\t");
            }
          }
        } else {
          _builder_1.append("SKIP");
        }
      }
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- Mapped events");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("MappedRCEvents = {|");
      {
        HashSet<String> _mappedEvents = this.mappedEvents(((Rule)rule), a.getElement());
        boolean _hasElements_3 = false;
        for(final String e : _mappedEvents) {
          if (!_hasElements_3) {
            _hasElements_3 = true;
          } else {
            _builder_1.appendImmediate(",", "\t\t");
          }
          _builder_1.append(e, "\t\t");
        }
      }
      _builder_1.append("|}");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- SLEEC rule renamed");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("Rule = SLEEC");
      String _name_8 = ((Rule)rule).getName();
      _builder_1.append(_name_8, "\t\t");
      _builder_1.newLineIfNotEmpty();
      {
        boolean _hasElements_4 = false;
        for(final Measure m_3 : measures) {
          if (!_hasElements_4) {
            _hasElements_4 = true;
            _builder_1.append("[[", "\t\t\t\t\t");
          } else {
            _builder_1.appendImmediate(",", "\t\t\t\t\t");
          }
          _builder_1.append("\t\t\t\t\t");
          String _name_9 = m_3.getName();
          _builder_1.append(_name_9, "\t\t\t\t\t");
          _builder_1.append(" <- i_");
          String _name_10 = m_3.getName();
          _builder_1.append(_name_10, "\t\t\t\t\t");
          _builder_1.newLineIfNotEmpty();
        }
        if (_hasElements_4) {
          _builder_1.append("]]", "\t\t\t\t\t");
        }
      }
      _builder_1.append("\t");
      _builder_1.append("within");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("timed_priority(");
      _builder_1.newLine();
      _builder_1.append("\t\t\t");
      _builder_1.append("(");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append("(Rule ||| TRUN(diff(CommonProvideEvents,A");
      String _name_11 = ((Rule)rule).getName();
      _builder_1.append(_name_11, "\t\t\t\t");
      _builder_1.append(")))");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t\t\t");
      _builder_1.append("[| union(CommonProvideEvents,MemoryInternalEvents) |]");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append("(");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t\t");
      _builder_1.append("Memory");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t\t");
      _builder_1.append("[| MemoryExternalEvents |]");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t\t");
      _builder_1.append("MemoryInOrder");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append(")");
      _builder_1.newLine();
      _builder_1.append("\t\t\t");
      _builder_1.append(") \\ MemoryInternalEvents");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append(")");
      _builder_1.newLine();
      _builder_1.newLine();
      String _name_12 = a.getName();
      _builder_1.append(_name_12);
      _builder_1.append("_suv =");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t");
      _builder_1.append("let");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("-- The external \'m\' channels for every measure of ");
      String _name_13 = ((Rule)rule).getName();
      _builder_1.append(_name_13, "\t\t");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("MemoryExternalEvents = {|");
      {
        boolean _hasElements_5 = false;
        for(final Measure m_4 : measures) {
          if (!_hasElements_5) {
            _hasElements_5 = true;
          } else {
            _builder_1.appendImmediate(",", "\t\t");
          }
          String _name_14 = m_4.getName();
          _builder_1.append(_name_14, "\t\t");
        }
      }
      _builder_1.append("|}");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- The internal \'i_m\' channels for every measure of ");
      String _name_15 = ((Rule)rule).getName();
      _builder_1.append(_name_15, "\t\t");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("MemoryInternalEvents = {|");
      {
        boolean _hasElements_6 = false;
        for(final Measure m_5 : measures) {
          if (!_hasElements_6) {
            _hasElements_6 = true;
          } else {
            _builder_1.appendImmediate(",", "\t\t");
          }
          _builder_1.append("i_");
          String _name_16 = m_5.getName();
          _builder_1.append(_name_16, "\t\t");
        }
      }
      _builder_1.append("|}");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- Events of ");
      String _name_17 = ((Rule)rule).getName();
      _builder_1.append(_name_17, "\t\t");
      _builder_1.append(" except for those of measures, and any unmapped SUV events:");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("CommonProvideEvents = diff(union(A");
      String _name_18 = ((Rule)rule).getName();
      _builder_1.append(_name_18, "\t\t");
      _builder_1.append(",diff(");
      String _processId_1 = this.gu().processId(a.getElement());
      _builder_1.append(_processId_1, "\t\t");
      _builder_1.append("::sem__events,MappedRCEvents)),MemoryExternalEvents)");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- The memory process");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("Memory = ");
      CharSequence _compileMeasureMemory_1 = this.compileMeasureMemory(measures);
      _builder_1.append(_compileMeasureMemory_1, "\t\t");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- Ordered reading");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("MemoryInOrder = ");
      {
        int _size_1 = measures.size();
        boolean _greaterThan_1 = (_size_1 > 0);
        if (_greaterThan_1) {
          {
            boolean _hasElements_7 = false;
            for(final Measure m_6 : measures) {
              if (!_hasElements_7) {
                _hasElements_7 = true;
              } else {
                _builder_1.appendImmediate(" -> ", "\t\t");
              }
              String _name_19 = m_6.getName();
              _builder_1.append(_name_19, "\t\t");
              _builder_1.append("?x__");
            }
            if (_hasElements_7) {
              _builder_1.append(" -> MemoryInOrder", "\t\t");
            }
          }
        } else {
          _builder_1.append("SKIP");
        }
      }
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- Mapped events");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("MappedRCEvents = {|");
      {
        HashSet<String> _mappedEvents_1 = this.mappedEvents(((Rule)rule), a.getElement());
        boolean _hasElements_8 = false;
        for(final String e_1 : _mappedEvents_1) {
          if (!_hasElements_8) {
            _hasElements_8 = true;
          } else {
            _builder_1.appendImmediate(",", "\t\t");
          }
          _builder_1.append(e_1, "\t\t");
        }
      }
      _builder_1.append("|}");
      _builder_1.newLineIfNotEmpty();
      _builder_1.append("\t\t");
      _builder_1.append("-- SUV renamed");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("SUV = (");
      CharSequence _renameSUV = this.renameSUV(a.getElement(), ((Rule)rule), suvSemantics);
      _builder_1.append(_renameSUV, "\t\t");
      _builder_1.append(")");
      _builder_1.newLineIfNotEmpty();
      {
        boolean _hasElements_9 = false;
        for(final Measure m_7 : measures) {
          if (!_hasElements_9) {
            _hasElements_9 = true;
            _builder_1.append("[[", "\t\t\t\t");
          } else {
            _builder_1.appendImmediate(",", "\t\t\t\t");
          }
          _builder_1.append("\t\t\t\t");
          String _name_20 = m_7.getName();
          _builder_1.append(_name_20, "\t\t\t\t");
          _builder_1.append(" <- i_");
          String _name_21 = m_7.getName();
          _builder_1.append(_name_21, "\t\t\t\t");
          _builder_1.newLineIfNotEmpty();
        }
        if (_hasElements_9) {
          _builder_1.append("]]", "\t\t\t\t");
        }
      }
      _builder_1.append("\t");
      _builder_1.append("within");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append("timed_priority(");
      _builder_1.newLine();
      _builder_1.append("\t\t\t");
      _builder_1.append("(");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append("(SUV ; STOP)");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append("[| union(CommonProvideEvents,MemoryInternalEvents) |]");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append("(");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t\t");
      _builder_1.append("Memory");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t\t");
      _builder_1.append("[| MemoryExternalEvents |]");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t\t");
      _builder_1.append("MemoryInOrder");
      _builder_1.newLine();
      _builder_1.append("\t\t\t\t");
      _builder_1.append(")");
      _builder_1.newLine();
      _builder_1.append("\t\t\t");
      _builder_1.append(") \\ MemoryInternalEvents");
      _builder_1.newLine();
      _builder_1.append("\t\t");
      _builder_1.append(")");
      _builder_1.newLine();
      _builder_1.newLine();
      _builder_1.append("}");
      _builder_1.newLine();
      _builder_1.newLine();
      _builder_1.append("assert ");
      {
        boolean _isNegated = a.isNegated();
        if (_isNegated) {
          _builder_1.append("not ");
        }
      }
      String _name_22 = a.getName();
      _builder_1.append(_name_22);
      _builder_1.append("_spec [T= ");
      String _name_23 = a.getName();
      _builder_1.append(_name_23);
      _builder_1.append("_suv");
      _builder_1.newLineIfNotEmpty();
      return _builder_1.toString();
    }
    return null;
  }
  
  protected CharSequence _renameNamedElement(final EObject obj, final Event e, final String t) {
    try {
      CharSequence _xifexpression = null;
      Type _type = e.getType();
      boolean _tripleEquals = (_type == null);
      if (_tripleEquals) {
        StringConcatenation _builder = new StringConcatenation();
        String _processId = this.gu().processId(obj);
        _builder.append(_processId);
        _builder.append("::");
        String _eventId = this.gu().eventId(e);
        _builder.append(_eventId);
        _builder.append(".in <- ");
        _builder.append(t);
        _builder.append(",");
        String _processId_1 = this.gu().processId(obj);
        _builder.append(_processId_1);
        _builder.append("::");
        String _eventId_1 = this.gu().eventId(e);
        _builder.append(_eventId_1);
        _builder.append(".out <- ");
        _builder.append(t);
        _xifexpression = _builder;
      } else {
        CharSequence _xblockexpression = null;
        {
          final Type bool = this.tp().getBooleanType(e);
          final Type eventType = e.getType();
          EObject _xifexpression_1 = null;
          if ((eventType instanceof TypeRef)) {
            _xifexpression_1 = ((TypeRef)eventType).getRef();
          } else {
            _xifexpression_1 = eventType;
          }
          final EObject type = _xifexpression_1;
          CharSequence _xifexpression_2 = null;
          if ((this.tp().isNumeric(eventType) || (this.tp().typeCompatible(eventType, bool)).booleanValue())) {
            StringConcatenation _builder_1 = new StringConcatenation();
            String _processId_2 = this.gu().processId(obj);
            _builder_1.append(_processId_2);
            _builder_1.append("::");
            String _eventId_2 = this.gu().eventId(e);
            _builder_1.append(_eventId_2);
            _builder_1.append(".in <- ");
            _builder_1.append(t);
            _builder_1.append(",");
            String _processId_3 = this.gu().processId(obj);
            _builder_1.append(_processId_3);
            _builder_1.append("::");
            String _eventId_3 = this.gu().eventId(e);
            _builder_1.append(_eventId_3);
            _builder_1.append(".out <- ");
            _builder_1.append(t);
            _xifexpression_2 = _builder_1;
          } else {
            CharSequence _xifexpression_3 = null;
            if ((type instanceof Enumeration)) {
              StringConcatenation _builder_2 = new StringConcatenation();
              {
                EList<Literal> _literals = ((Enumeration)type).getLiterals();
                boolean _hasElements = false;
                for(final Literal l : _literals) {
                  if (!_hasElements) {
                    _hasElements = true;
                  } else {
                    _builder_2.appendImmediate(",", "");
                  }
                  String _processId_4 = this.gu().processId(obj);
                  _builder_2.append(_processId_4);
                  _builder_2.append("::");
                  String _eventId_4 = this.gu().eventId(e);
                  _builder_2.append(_eventId_4);
                  _builder_2.append(".in.");
                  String _id = this.gu().id(l);
                  _builder_2.append(_id);
                  _builder_2.append(" <- ");
                  _builder_2.append(t);
                  _builder_2.append(".");
                  String _name = l.getName();
                  _builder_2.append(_name);
                  _builder_2.append(",");
                  String _processId_5 = this.gu().processId(obj);
                  _builder_2.append(_processId_5);
                  _builder_2.append("::");
                  String _eventId_5 = this.gu().eventId(e);
                  _builder_2.append(_eventId_5);
                  _builder_2.append(".out.");
                  String _id_1 = this.gu().id(l);
                  _builder_2.append(_id_1);
                  _builder_2.append(" <- ");
                  _builder_2.append(t);
                  _builder_2.append(".");
                  String _name_1 = l.getName();
                  _builder_2.append(_name_1);
                  _builder_2.newLineIfNotEmpty();
                }
              }
              _xifexpression_3 = _builder_2;
            } else {
              String _name_2 = e.getName();
              String _plus = ("Unsupported type for event \'" + _name_2);
              String _plus_1 = (_plus + "\' while compiling SLEECAssertion.");
              throw new Exception(_plus_1);
            }
            _xifexpression_2 = _xifexpression_3;
          }
          _xblockexpression = _xifexpression_2;
        }
        _xifexpression = _xblockexpression;
      }
      return _xifexpression;
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  protected CharSequence _renameNamedElement(final EObject obj, final OperationSig op, final String t) {
    StringConcatenation _builder = new StringConcatenation();
    String _processId = this.gu().processId(obj);
    _builder.append(_processId);
    _builder.append("::");
    String _name = op.getName();
    _builder.append(_name);
    _builder.append("Call <- ");
    _builder.append(t);
    return _builder;
  }
  
  protected CharSequence _renameNamedElement(final EObject obj, final EObject e, final String t) {
    try {
      throw new Exception("renameNamedElement: unhandled case");
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  protected CharSequence _renameSUV(final StateMachine stm, final Rule rule, final String string) {
    CharSequence _xblockexpression = null;
    {
      final HashMap<NamedElement, String> map = this.su().getNamedElementMap(stm, rule);
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("(");
      _builder.append(string);
      _builder.append("\\{|");
      String _processId = this.gu().processId(stm);
      _builder.append(_processId);
      _builder.append("::terminate|})");
      {
        Set<NamedElement> _keySet = map.keySet();
        boolean _hasElements = false;
        for(final NamedElement p : _keySet) {
          if (!_hasElements) {
            _hasElements = true;
            _builder.append("[[");
          } else {
            _builder.appendImmediate(",", "");
          }
          _builder.newLineIfNotEmpty();
          CharSequence _renameNamedElement = this.renameNamedElement(stm, p, map.get(p));
          _builder.append(_renameNamedElement);
          _builder.newLineIfNotEmpty();
        }
        if (_hasElements) {
          _builder.append("]]");
        }
      }
      _xblockexpression = _builder;
    }
    return _xblockexpression;
  }
  
  protected CharSequence _renameSUV(final Controller c, final Rule rule, final String string) {
    CharSequence _xblockexpression = null;
    {
      final HashMap<NamedElement, String> map = this.su().getNamedElementMap(c, rule);
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("(");
      _builder.append(string);
      _builder.append("\\{|");
      String _processId = this.gu().processId(c);
      _builder.append(_processId);
      _builder.append("::terminate|})");
      {
        Set<NamedElement> _keySet = map.keySet();
        boolean _hasElements = false;
        for(final NamedElement p : _keySet) {
          if (!_hasElements) {
            _hasElements = true;
            _builder.append("[[");
          } else {
            _builder.appendImmediate(",", "");
          }
          _builder.newLineIfNotEmpty();
          CharSequence _renameNamedElement = this.renameNamedElement(c, p, map.get(p));
          _builder.append(_renameNamedElement);
          _builder.newLineIfNotEmpty();
        }
        if (_hasElements) {
          _builder.append("]]");
        }
      }
      _xblockexpression = _builder;
    }
    return _xblockexpression;
  }
  
  protected CharSequence _renameSUV(final RCModule m, final Rule rule, final String string) {
    CharSequence _xblockexpression = null;
    {
      final HashMap<NamedElement, String> map = this.su().getNamedElementMap(m, rule);
      StringConcatenation _builder = new StringConcatenation();
      _builder.append(string);
      {
        Set<NamedElement> _keySet = map.keySet();
        boolean _hasElements = false;
        for(final NamedElement p : _keySet) {
          if (!_hasElements) {
            _hasElements = true;
            _builder.append("[[");
          } else {
            _builder.appendImmediate(",", "");
          }
          _builder.newLineIfNotEmpty();
          CharSequence _renameNamedElement = this.renameNamedElement(m, p, map.get(p));
          _builder.append(_renameNamedElement);
          _builder.newLineIfNotEmpty();
        }
        if (_hasElements) {
          _builder.append("]]");
        }
      }
      _xblockexpression = _builder;
    }
    return _xblockexpression;
  }
  
  protected CharSequence _renameSUV(final NamedElement element, final Rule rule, final String string) {
    try {
      throw new Exception("Unhandled NamedElement when compiling SLEECAssertion.");
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  protected HashSet<String> _mappedEvents(final Rule rule, final StateMachine stm) {
    StateMachineDef _xifexpression = null;
    if ((stm instanceof StateMachineRef)) {
      _xifexpression = ((StateMachineRef)stm).getRef();
    } else {
      _xifexpression = ((StateMachineDef) stm);
    }
    final StateMachineDef stmDef = _xifexpression;
    Set<OperationSig> requiredOps = this.gu().requiredOperations(stmDef);
    HashSet<String> mapped = new HashSet<String>();
    final HashSet<String> alphaRule = this.su().getAlphabet(rule);
    final LinkedList<Event> events = this.gu().getEvents(stm);
    for (final Event e : events) {
      boolean _contains = alphaRule.contains(e.getName());
      if (_contains) {
        StringConcatenation _builder = new StringConcatenation();
        String _processId = this.gu().processId(stm);
        _builder.append(_processId);
        _builder.append("::");
        String _eventId = this.gu().eventId(e);
        _builder.append(_eventId);
        mapped.add(_builder.toString());
      }
    }
    for (final OperationSig o : requiredOps) {
      boolean _contains_1 = alphaRule.contains(o.getName());
      if (_contains_1) {
        StringConcatenation _builder_1 = new StringConcatenation();
        String _processId_1 = this.gu().processId(stm);
        _builder_1.append(_processId_1);
        _builder_1.append("::");
        String _name = o.getName();
        _builder_1.append(_name);
        _builder_1.append("Call");
        mapped.add(_builder_1.toString());
      }
    }
    return mapped;
  }
  
  protected HashSet<String> _mappedEvents(final Rule rule, final Controller c) {
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
    HashSet<String> mapped = new HashSet<String>();
    for (final Event e : events) {
      boolean _contains = alphaRule.contains(e.getName());
      if (_contains) {
        StringConcatenation _builder = new StringConcatenation();
        String _processId = this.gu().processId(c);
        _builder.append(_processId);
        _builder.append("::");
        String _eventId = this.gu().eventId(e);
        _builder.append(_eventId);
        mapped.add(_builder.toString());
      }
    }
    for (final OperationSig o : requiredOps) {
      boolean _contains_1 = alphaRule.contains(o.getName());
      if (_contains_1) {
        StringConcatenation _builder_1 = new StringConcatenation();
        String _processId_1 = this.gu().processId(c);
        _builder_1.append(_processId_1);
        _builder_1.append("::");
        String _name = o.getName();
        _builder_1.append(_name);
        _builder_1.append("Call");
        mapped.add(_builder_1.toString());
      }
    }
    return mapped;
  }
  
  protected HashSet<String> _mappedEvents(final Rule rule, final RCModule m) {
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
    HashSet<String> mapped = new HashSet<String>();
    for (final Event e : events) {
      boolean _contains = alphaRule.contains(e.getName());
      if (_contains) {
        StringConcatenation _builder = new StringConcatenation();
        String _processId = this.gu().processId(m);
        _builder.append(_processId);
        _builder.append("::");
        String _eventId = this.gu().eventId(e);
        _builder.append(_eventId);
        mapped.add(_builder.toString());
      }
    }
    for (final OperationSig o : allOps) {
      boolean _contains_1 = alphaRule.contains(o.getName());
      if (_contains_1) {
        StringConcatenation _builder_1 = new StringConcatenation();
        String _processId_1 = this.gu().processId(m);
        _builder_1.append(_processId_1);
        _builder_1.append("::");
        String _name = o.getName();
        _builder_1.append(_name);
        _builder_1.append("Call");
        mapped.add(_builder_1.toString());
      }
    }
    return mapped;
  }
  
  protected HashSet<String> _mappedEvents(final Rule rule, final NamedElement element) {
    return new HashSet<String>();
  }
  
  public CharSequence compileMeasureMemory(final Iterable<Measure> m) {
    CharSequence _xifexpression = null;
    int _size = IterableExtensions.size(m);
    boolean _greaterThan = (_size > 1);
    if (_greaterThan) {
      CharSequence _xblockexpression = null;
      {
        final Measure element = IterableExtensions.<Measure>head(m);
        StringConcatenation _builder = new StringConcatenation();
        _builder.append("(");
        _builder.newLine();
        _builder.append("\t");
        _builder.append("Mem_");
        String _name = element.getName();
        _builder.append(_name, "\t");
        _builder.append("(CommonProvideEvents)");
        _builder.newLineIfNotEmpty();
        _builder.append("\t");
        _builder.append("[| CommonProvideEvents |] ");
        _builder.newLine();
        _builder.append("\t");
        CharSequence _compileMeasureMemory = this.compileMeasureMemory(IterableExtensions.<Measure>tail(m));
        _builder.append(_compileMeasureMemory, "\t");
        _builder.newLineIfNotEmpty();
        _builder.append(")");
        _builder.newLine();
        _xblockexpression = _builder;
      }
      _xifexpression = _xblockexpression;
    } else {
      CharSequence _xifexpression_1 = null;
      int _size_1 = IterableExtensions.size(m);
      boolean _equals = (_size_1 == 1);
      if (_equals) {
        CharSequence _xblockexpression_1 = null;
        {
          final Measure element = IterableExtensions.<Measure>head(m);
          StringConcatenation _builder = new StringConcatenation();
          _builder.append("Mem_");
          String _name = element.getName();
          _builder.append(_name);
          _builder.append("(CommonProvideEvents)");
          _xblockexpression_1 = _builder;
        }
        _xifexpression_1 = _xblockexpression_1;
      } else {
        CharSequence _xifexpression_2 = null;
        int _size_2 = IterableExtensions.size(m);
        boolean _equals_1 = (_size_2 == 0);
        if (_equals_1) {
          StringConcatenation _builder = new StringConcatenation();
          _builder.append("TRUN(CommonProvideEvents)");
          _xifexpression_2 = _builder;
        }
        _xifexpression_1 = _xifexpression_2;
      }
      _xifexpression = _xifexpression_1;
    }
    return _xifexpression;
  }
  
  @Override
  public String printAssertion(final SLEECAssertion assertion, final String suvID) {
    final EObject rule = assertion.getRule();
    String ruleName = "unknown";
    if ((rule instanceof Rule)) {
      ruleName = ((Rule)rule).getName();
    }
    StringConcatenation _builder = new StringConcatenation();
    _builder.append(suvID);
    _builder.append(" ");
    {
      boolean _isNegated = assertion.isNegated();
      if (_isNegated) {
        _builder.append("does not conform");
      } else {
        _builder.append("conforms");
      }
    }
    _builder.append(" to ");
    _builder.append(ruleName);
    _builder.append(" [traces]");
    return _builder.toString();
  }
  
  @Override
  public String calculateImports(final EObject rule) {
    if ((rule instanceof Rule)) {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("../../src-gen/");
      String _lastSegment = ((Rule)rule).eResource().getURI().trimFileExtension().lastSegment();
      String _plus = (_lastSegment + ".csp");
      _builder.append(_plus);
      return _builder.toString();
    }
    return null;
  }
  
  public CharSequence renameNamedElement(final EObject obj, final EObject e, final String t) {
    if (e instanceof Event) {
      return _renameNamedElement(obj, (Event)e, t);
    } else if (e instanceof OperationSig) {
      return _renameNamedElement(obj, (OperationSig)e, t);
    } else if (e != null) {
      return _renameNamedElement(obj, e, t);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(obj, e, t).toString());
    }
  }
  
  public CharSequence renameSUV(final NamedElement c, final Rule rule, final String string) {
    if (c instanceof Controller) {
      return _renameSUV((Controller)c, rule, string);
    } else if (c instanceof RCModule) {
      return _renameSUV((RCModule)c, rule, string);
    } else if (c instanceof StateMachine) {
      return _renameSUV((StateMachine)c, rule, string);
    } else if (c != null) {
      return _renameSUV(c, rule, string);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(c, rule, string).toString());
    }
  }
  
  public HashSet<String> mappedEvents(final Rule rule, final NamedElement c) {
    if (c instanceof Controller) {
      return _mappedEvents(rule, (Controller)c);
    } else if (c instanceof RCModule) {
      return _mappedEvents(rule, (RCModule)c);
    } else if (c instanceof StateMachine) {
      return _mappedEvents(rule, (StateMachine)c);
    } else if (c != null) {
      return _mappedEvents(rule, c);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(rule, c).toString());
    }
  }
}
