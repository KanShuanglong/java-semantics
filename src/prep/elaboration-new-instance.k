module ELABORATION-NEW-INSTANCE
    imports CORE-SORTS
    imports CORE-CLASSES
    imports PROCESS-TYPE-NAMES     //for toPackage()
    imports SUBTYPING
    imports ELABORATION-CORE
    imports ELABORATION-METHOD-INVOKE   // for lookupMethod, methodLookupResult
    imports PROCESS-LOCAL-CLASSES //for localClassGetExtraArgs

/*@ \subsubsection{Elaboration of 'NewInstance and 'QNewInstance} */

/*@ elab('NewInstance()) is strict in arguments 2 and 3 - class name and constrctor arguments.
    Constrctor arguments have to be heated if this class is anonymous.
*/
//rule customElabHeating('NewInstance, [Ks:KList]) => length([Ks]) in (SetItem(2) SetItem(3))

rule ( . => Arg2 ) ~> elab('NewInstance(_,,(Arg2 => CHOLE),,_,,_))
when notBool isElabKResult(Arg2) ==K true

rule ( . => elab(Arg3) ) ~> elab('NewInstance(_,,_:ElabKResult,,(Arg3 => CHOLE),,_))
when notBool isElabKResult(Arg3) ==K true

rule elab('NewInstance(_,,_:ElabKResult,,(.Exps => elabRes(.Exps)),,_))

rule [elab-NewInstance]:
    <k>
      elab(
        'NewInstance(Arg1:K,, Class:ClassType,, ActualArgsList:K /* Either [_] or elabRes() */,, 'None(.KList))
        =>  'QNewInstance(
              #if CT ==K staticCT
                #then noValue
                #else findQualifierOfType(CrntClass, EnclosingClass)
              #fi,,
              Arg1,, Class,, 'None(.KList),, ActualArgsList,, 'None(.KList)
            )
      )
      ...
    </k>
    <crntClass> CrntClass:ClassType </crntClass>
    <classType> Class </classType>
    <enclosingClass> EnclosingClass:ClassType </enclosingClass>
    <classContextType> CT:ContextType </classContextType>

/*@ elab('QNewInstance()) is strict in all its arguments except the class name (3) and anonymous body(6).
  - Argument (3) is heated if it is not a simple name but a precusros to a type
  - Argument (6) is heated if it is 'None() - an empty body.
*/

//rule customElabHeating('QNewInstance, [Ks:KList,,KHole:K])
//     => length([Ks,,KHole]) in (SetItem(1) SetItem(2) SetItem(4) SetItem(5))
//        orBool (length([Ks,,KHole]) ==K 3 andBool notBool isId(KHole) ==K true) //isId(KHole) => class not resolved yet
//        orBool (length([Ks,,KHole]) ==K 6 andBool KHole ==K 'None(.KList))      // KHole =/= 'None(_) => anon. class

rule (. => elab(Arg1)) ~> elab('QNewInstance((Arg1:K => CHOLE),,_,,_,,_,,_,,_))
when (notBool isElabKResult(Arg1)) andBool (notBool isElabNaked(Arg1))

rule (. => Arg1) ~> elab('QNewInstance((Arg1:K => CHOLE),,_,,_,,_,,_,,_))
when (notBool isElabKResult(Arg1)) andBool isElabNaked(Arg1)

rule (. => elab(Arg2)) ~> elab('QNewInstance(_,,(Arg2:K => CHOLE),,_,,_,,_,,_))
when notBool isElabKResult(Arg2)

rule (. => elab(Arg3)) ~> elab('QNewInstance(_,,_,,(Arg3:K => CHOLE),,_,,_,,_))
when (notBool isId(Arg3)) andBool (notBool isElabKResult(Arg3)) andBool (notBool isElabNaked(Arg3))

rule (. => Arg3) ~> elab('QNewInstance(_,,_,,(Arg3:K => CHOLE),,_,,_,,_))
when (notBool isId(Arg3)) andBool (notBool isElabKResult(Arg3)) andBool isElabNaked(Arg3)

rule (. => elab(Arg4)) ~> elab('QNewInstance(_,,_,,_,,(Arg4:K => CHOLE),,_,,_))
when notBool isElabKResult(Arg4)

rule (. => elab(Arg5)) ~> elab('QNewInstance(_,,_,,_,,_,,(Arg5:K => CHOLE),,_))
when notBool isElabKResult(Arg5)

rule elab('QNewInstance(_,,_,,_,,_,,(.Exps => elabRes(.Exps)),,_))

rule (. => elab('None(.KList))) ~> elab('QNewInstance(_,,_,,_,,_,,_,,('None(.KList) => CHOLE)))

//Resolve the class name with the help of qualifier type
rule [elab-QNewInstance-resolve-class]:
    elab('QNewInstance(elabRes(cast(QualClass:ClassType, _)),, _:K,,
      (Name:Id => resolveInnerClass(QualClass, Name)),,
    _))

/*@ Resolve the simple name of an inner class to a fully qualified class name in
    a qualified new like: o.new A(...);
*/
syntax KItem ::=  resolveInnerClass (
                ClassType,  //QualClass - the type of the qualifier
                Id          //Name - instantiated class simple name
              )

rule isElabNaked(resolveInnerClass(_,_)) => true

rule [resolveInnerClass]:
    <k>
      resolveInnerClass(QualClass:ClassType, Name:Id)
      => getClassIfExists(toPackage(QualClass), Name) ?? resolveInnerClass(BaseQualClass, Name)
      ...
    </k>
    <classType> QualClass </classType>
    <extends> BaseQualClass:ClassType </extends>

//@ If with the fiven package and name exists, return this class. Otherwise return noValue
syntax KItem ::= getClassIfExists ( PackageId, Id )

rule [getClassIfExists]:
    <k>
      getClassIfExists(Pack:PackageId, Name:Id)
      =>  #if Name in keys(NamesToClasses)
            #then getClassType(Pack:PackageId, Name:Id)
            #else noValue
          #fi
      ...
    </k>
    <namesToClasses>... Pack:PackageId |-> mapWrap(NamesToClasses:Map) ...</namesToClasses>

rule [elab-QNewInstance-local-augment-arguments]:
    (. => localClassGetExtraArgs(Class))
    ~> elabEnd('QNewInstance(Qual:K,, Arg2:K,, Class:ClassType,, Arg4:K,, Args,, 'None(.KList) ))

/*@ QNewInstance lookup is always qualified (e.g. not this), because the object we are creating
    is different from the current object.
*/
rule [elabEnd-QNewInstance-to-lookupMethod]:
    ( elabRes(ExtraArgs:Exps)
      => lookupMethod(Class, false, getConsName(Class), appendExps(Args, ExtraArgs))
    )
    ~> elabEnd('QNewInstance(Qual:K,, Arg2:K,, Class:ClassType,, Arg4:K,, Args:Exps,, 'None(.KList)))

/*@ All new instance creation expressions are converted into qualified ones - 'QNewInstance, during elaboration phase.
  For instance inner classes, the qualifier will be a valid expression for the qualifier. For other classes qualifier
  will be noValue. At this stage 'QNewInstance is wrapped in elabEnd.
*/
rule [elabEnd-QNewInstance-methodLookupResult-qualified-end]:
    <k>
      methodLookupResult(_, ExpectedArgExps:Exps, instanceCT)
      ~> elabEnd('QNewInstance( cast(_, QualExp:K),, Arg2:K,, Class:ClassType,, Arg4:K,, _,, 'None(.KList)))
      => elabRes(cast(Class, 'QNewInstance( cast(EnclosingClass, QualExp:K),, Arg2,, getSimpleName(Class),,
                                            Arg4,, ExpectedArgExps,, 'None(.KList))))
      ...
    </k>
    <classType> Class </classType>
    <enclosingClass> EnclosingClass:ClassType </enclosingClass>

/*@ A 'QNewInstance with target noValue should be packed back into a NewInstance, for compatibility with Java.
    It will be desugared again into 'NewInstance at execution phase.
*/
rule [elabEnd-QNewInstance-methodLookupResult-to-NewInstance]:
    methodLookupResult(_, ExpectedArgExps:Exps, instanceCT)
    ~> elabEnd('QNewInstance(noValue,, Arg2:K,, Class:ClassType,, Arg4:K,, _,, 'None(.KList)))
    => elabRes(cast(Class, 'NewInstance(Arg2,, Class,, ExpectedArgExps,, 'None(.KList))))

endmodule
