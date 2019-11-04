// RUN: %target-typecheck-verify-swift -typecheck %s -verify -swift-version 4

// Make sure Self: ... is correctly diagnosed in classes

class SelfInGenericClass<T> {
  // expected-error@+1 {{type 'Self' in conformance requirement does not refer to a generic parameter or associated type}}
  func foo() where Self: Equatable { }
  // expected-error@+1 {{generic signature requires types 'Self' and 'Bool' to be the same}}
  func bar() where Self == Bool { }
}

protocol Whereable {
  associatedtype Assoc
  associatedtype Bssoc

  // expected-error@+1 {{instance method requirement 'requirement1()' cannot add constraint 'Self.Assoc: Sequence' on 'Self'}}
  func requirement1() where Assoc: Sequence
  // expected-error@+1 {{instance method requirement 'requirement2()' cannot add constraint 'Self.Bssoc == Never' on 'Self'}}
  func requirement2() where Bssoc == Never
}

extension Whereable {
  // expected-note@+1 {{where 'Self' = 'T1'}}
  static func staticExtensionFunc(arg: Self.Element) -> Self.Element
    where Self: Sequence {
      return arg
  }

  // expected-note@+1 {{where 'Self.Assoc' = 'T1.Assoc', 'Self.Bssoc' = 'T1.Bssoc'}}
  func extensionFunc() where Assoc == Bssoc { }


  // expected-note@+1 {{where 'Self.Assoc' = 'T1.Assoc'}}
  subscript() -> Assoc where Assoc: Whereable {
    fatalError()
  }
}

func testProtocolExtensions<T1, T2, T3, T4>(t1: T1, t2: T2, t3: T3, t4: T4)
  where T1: Whereable,
        T2: Whereable & Sequence,
        T3: Whereable, T3.Assoc == T3.Bssoc,
        T4: Whereable, T4.Assoc: Whereable {
  _ = T1.staticExtensionFunc // expected-error {{static method 'staticExtensionFunc(arg:)' requires that 'T1' conform to 'Sequence'}}
  _ = T2.staticExtensionFunc

  t1.extensionFunc() // expected-error {{instance method 'extensionFunc()' requires the types 'T1.Assoc' and 'T1.Bssoc' be equivalent}}
  t3.extensionFunc()

  _ = t1[] // expected-error {{subscript 'subscript()' requires that 'T1.Assoc' conform to 'Whereable'}}
  _ = t4[]
}

class Class<T> {
  // expected-note@+1 {{where 'T' = 'T}} // expected-note@+1 {{where 'T.Assoc' = 'T.Assoc'}}
  static func staticFunc() where T: Whereable, T.Assoc == Int { }

  // expected-note@+1 {{candidate requires that the types 'T' and 'Bool' be equivalent}}
  func func1() where T == Bool { }
  // FIXME: The rhs type at the end of the error message is not persistent across compilations.
  // expected-note@+1 {{candidate requires that the types 'T' and 'Int' be equivalent (requirement specified as 'T' == }}
  func func1() where T == Int { }

  func func2() where T == Int { } // expected-note {{where 'T' = 'T'}}

  subscript() -> T.Element where T: Sequence { // expected-note {{where 'T' = 'T'}}
    fatalError()
  }
}

extension Class {
  static func staticExtensionFunc() where T: Class<Int> { } // expected-note {{where 'T' = 'T'}}

  subscript(arg: T.Element) -> T.Element where T == Array<Int> {
    fatalError()
  }
}

extension Class where T: Equatable {
  func extensionFunc() where T: Comparable { } // expected-note {{where 'T' = 'T'}}

  // expected-error@+1 {{same-type constraint type 'Class<Int>' does not conform to required protocol 'Equatable'}}
  func badRequirement1() where T == Class<Int> { }
}

extension Class where T == Bool {
  // expected-error@+1 {{generic parameter 'T' cannot be equal to both 'Int' and 'Bool'}}
  func badRequirement2() where T == Int { }
}

func testMemberDeclarations<T, U: Comparable>(arg1: Class<T>, arg2: Class<U>) {
  // expected-error@+2 {{static method 'staticFunc()' requires the types 'T.Assoc' and 'Int' be equivalent}}
  // expected-error@+1 {{static method 'staticFunc()' requires that 'T' conform to 'Whereable'}}
  Class<T>.staticFunc()
  Class<T>.staticExtensionFunc() // expected-error {{static method 'staticExtensionFunc()' requires that 'T' inherit from 'Class<Int>'}}
  Class<Class<Int>>.staticExtensionFunc()

  arg1.func1() // expected-error {{no exact matches in call to instance method 'func1'}}
  arg1.func2() // expected-error {{instance method 'func2()' requires the types 'T' and 'Int' be equivalent}}
  arg1.extensionFunc() // expected-error {{instance method 'extensionFunc()' requires that 'T' conform to 'Comparable'}}
  arg2.extensionFunc()
  Class<Int>().func1()
  Class<Int>().func2()

  arg1[] // expected-error {{subscript 'subscript()' requires that 'T' conform to 'Sequence'}}
  _ = Class<Array<Int>>()[Int.zero]
}
