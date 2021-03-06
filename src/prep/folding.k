module FOLDING
    imports CORE-SORTS
    imports CORE-CLASSES

rule [FoldingPhase-start]:
    <k> . => foldingPhase </k>
    <globalPhase> ElaborationPhase => FoldingPhase </globalPhase>
    (.Bag => <program> [.KList] </program>)

/*@ The sole content of <k> cell during FoldingPhase
*/
syntax KItem ::= "foldingPhase"

/*So far top-level classes only.*/
rule [folding-start]:
    <k> foldingPhase </k>
    <classType> Class:ClassType </classType>
    ( <classMetaType> MetaType:ClassMetaType </classMetaType> => .Bag)
    ( <classAccessMode> AccessMode:AccessMode </classAccessMode> => .Bag)
    ( <extends> BaseClass:ClassType </extends> => .Bag)
    ( <instanceFields> InstanceFields:ClassBodyDecList </instanceFields> => .Bag)
    ( <staticFields> StaticFields:ClassBodyDecList </staticFields> => .Bag)
    ( <staticInit> StaticInit:BlockStmList </staticInit> => .Bag)
    <folded>
      .K => getClassDecLabel(MetaType)
            (
              //JDK comp: #if MetaType ==K classCMT #then 'ClassDecHead #else 'InterfaceDecHead #fi
              'ClassDecHead(
                //JDK comp: #if AccessMode ==K package #then [.KList] #else [AccessMode] #fi
                AccessMode,,
                Class,,
                'None(.KList),,
                //JDK comp: #if BaseClass ==K noClass #then 'None(_) #else 'Some('SuperDec( BaseClass )) #fi
                'Some('SuperDec( BaseClass )),,
                'Some('ImplementsDec( .HeatedInterfaceTypeList )) //processed by [fold-implements-dec]
              ),,
              'ClassBody(
                  appendClassBodyDecList(
                  addElementToClassBodyDecListEnd(StaticFields, 'StaticInit('Block(StaticInit))),
                  InstanceFields //instanceInit was converted into method, is not needed here.
                  )
              )
            )
    </folded>

syntax KLabel ::= getClassDecLabel ( ClassMetaType ) [function]
rule getClassDecLabel ( classCMT ) => 'ClassDec
rule getClassDecLabel ( interfaceCMT ) => 'InterfaceDec

rule [folding-ImplementsDec]:
    <k> foldingPhase </k>
    <classType> Class:ClassType </classType>
    <implTrans>... SetItem(BaseInterface:ClassType) => .Set ...</implTrans>
    <folded>
      _:KLabel(
        'ClassDecHead(
          _:K,, _:K,, _:K,, _:K,,
          'Some('ImplementsDec(IL:HeatedInterfaceTypeList => (BaseInterface, IL):HeatedInterfaceTypeList))
        ),,
        _
      )
    </folded>

rule [folding-MethodDec]:
    <k> foldingPhase </k>
    <classType> Class:ClassType </classType>
    ( <methodDec>
        <methodSignature> sig(Name:Id, _) </methodSignature>
        <methodReturnType> ReturnType:Type </methodReturnType>
        <methodParams> Params </methodParams>
        <methodBody> MethodBody:K </methodBody>
        <methodAccessMode> Acc:AccessMode </methodAccessMode>
        <methodContextType> CT:ContextType </methodContextType>
        ...
      </methodDec>
      => .Bag
    )
    <folded>
      _:KLabel(
        'ClassDecHead(_),,
        'ClassBody(
          C:K => addElementToClassBodyDecListEnd(C, 'MethodDec(
                      'MethodDecHead(
                        accCT(Acc, CT),,
                        'None(.KList),,//don't know what should be here
                        ReturnType,,
                        Name,,
                        Params,,
                        'None(.KList) //don't know what should be here
                      ),,
                      MethodBody
                    ))
        )
      )
    </folded>

rule [folding-class-end]:
    <k> foldingPhase </k>
    <classType> Class:ClassType </classType>
    ( <implTrans> .Set </implTrans> => .Bag)
    ( <methodDecs> .Bag </methodDecs> => .Bag)
    <folded> _:KLabel(_) </folded>
    <classPhase> MembersProcessedCPhase => FoldedCPhase </classPhase>

rule [folding-class-fold-top-level]:
    <k> foldingPhase </k>
    <namesToClasses>
      packageId(Class) |-> mapWrap(.Map)
      ...
    </namesToClasses>
    ( <class>
        <classType> class Class:Id </classType>
        <enclosingClass> noClass </enclosingClass>
        <folded> ClassDec:K </folded>
        <classPhase> FoldedCPhase </classPhase>
        ...
      </class> => .Bag
    )
    <program> [_,, (.KList => ClassDec)] </program>

rule [folding-class-fold-inner]:
    <k> foldingPhase </k>
    <namesToClasses>
      packageId(Class) |-> mapWrap(.Map)
      packageId(EnclosingClass) |-> mapWrap(M:Map => removeMapItemsByValue(M, class Class))
      ...
    </namesToClasses>
    ( <class>
        <classType> class Class:Id </classType>
        <enclosingClass> class EnclosingClass:Id </enclosingClass>
        <folded> ClassDec:K </folded>
        <classPhase> FoldedCPhase </classPhase>
        ...
      </class> => .Bag
    )
    <class>
      <classType> class EnclosingClass </classType>
      <folded>
        _:KLabel(
          'ClassDecHead(_),,
          'ClassBody( C:K => addElementToClassBodyDecListEnd(C, ClassDec) )
        )
      </folded>
      <classPhase> FoldedCPhase </classPhase>
      ...
    </class>

rule [FoldingPhase-end]:
    <k> foldingPhase => . </k>
    <globalPhase> FoldingPhase </globalPhase>
    <classes> .Bag </classes>

endmodule
