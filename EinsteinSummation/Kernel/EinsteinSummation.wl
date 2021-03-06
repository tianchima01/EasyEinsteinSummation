(* ::Package:: *)

(* ::Section:: *)
(*Easy Einstein Summation*)


(* ::Subsection:: *)
(*Package Headers*)


(* ::Code::Initialization::Plain:: *)
BeginPackage["EinsteinSummation`"];


(**)
$tensorSymb
ConvertTeXExpression
ParseTensor
ParseTensorExpression


(*Global Variables*)
{t,x,y,z}
$TensorDefinitions
$vars
$constants
SetVars
SetMetric
AddTensorToDataset

(*Single Tensor Processing*)
AdjustIndex
ConvertTensorIndex

(*Multiple *)
FreeIndexes
FreeParentheses
TensorOperate
EvaluateEinsteinSummation


Begin["`Private`"];


(* ::Subsection:: *)
(*Process Strings into Tensor Expressions*)


(* ::Subsubsection:: *)
(*$TensorSymb*)


(* ::Input::Initialization::Plain:: *)
(*Unprotect[$tensorSymb];*)
(*ClearAll@$tensorSymb;*)
$tensorSymb[s_Association]/;(s["Dimensions"]==0):=s["Value"];
$tensorSymb[s_Association][query_]:=s[query];


(* ::Text:: *)
(*Render Function*)


$tensorSymb/:MakeBoxes[obj:$tensorSymb[asso_Association],form:(StandardForm|TraditionalForm)]/;ContainsAll[Keys[asso],{"IndexPosition","Symbol"}]:=
Module[{above,below,icon,pl=.4,
cf=(If[#===Inherited,2*CurrentValue["FontXHeight"],#]&@CurrentValue["FontSize"]),
indname=If[KeyExistsQ[asso,"IndexName"],asso["IndexName"],ConstantArray["\[Square]",Length@asso["IndexPosition"]]],
parent=If[KeyExistsQ[asso,"SymmetryMarker"],asso["SymmetryMarker"],<|-1->{},1->{}|>]},
(*Icon*)
Module[{temp=ConstantArray["",{Length@asso["IndexPosition"]+1,2}],nindmax=10},
KeyValueMap[Function[{key,val},With[{h=(3-key)/2},(temp[[#1,h]]=StringJoin[temp[[#1,h]],#2])&@@@val]],parent];
temp=DeleteCases[Riffle[temp,MapThread[If[#1==1,{#2,""},{"",#2}]&,{asso["IndexPosition"],indname}]],{"",""}];
temp=If[Length@temp>nindmax,temp[[;;nindmax-1]],temp];

icon=Style[Pane[Row[{Row[{Style[asso["Symbol"],Bold,2*cf]},BaselinePosition->Center],Grid[Transpose@temp,Spacings->{0,{0,{.15 CurrentValue["FontCapHeight"]},0}},Frame->None,Alignment->Baseline,BaselinePosition->Center],If[Length@temp>nindmax,Row[{"\[CenterEllipsis]"},BaselinePosition->Center],Nothing]},Alignment->Center],{UpTo[Round[15*CurrentValue["FontMWidth"]]],5*CurrentValue["FontCapHeight"]},ImageSize->{UpTo[Round[12*CurrentValue["FontMWidth"]]],5*CurrentValue["FontCapHeight"]},ImageSizeAction->"ResizeToFit",Alignment->{Center,Top}],LinebreakAdjustments->{1000, 2, 12, 1, 1}]
];

above={{BoxForm`SummaryItem[{"Symbol: ",asso["Symbol"]}],SpanFromLeft},
{BoxForm`SummaryItem[{"Dimensions: ",Length@asso["IndexPosition"]}],SpanFromLeft}};
below={{BoxForm`SummaryItem[{"Index Name: ",Short[indname,pl]}],SpanFromLeft},
{BoxForm`SummaryItem[{"Index Position: ",Short[asso["IndexPosition"],pl]}],SpanFromLeft},
{BoxForm`SummaryItem[{"Symmetry Marker: ",Short[parent,pl]}],SpanFromLeft},
If[KeyExistsQ[asso,"Value"],{BoxForm`SummaryItem[{"Value: ",""}],SpanFromLeft},Nothing],
If[KeyExistsQ[asso,"Value"],{BoxForm`SummaryItem[{Short[asso["Value"],.8]}],SpanFromLeft},Nothing]
};
BoxForm`ArrangeSummaryBox[$tensorSymb,obj,icon,above,below,form,"Interpretable"->Automatic]];


(*Protect[$tensorSymb];*)


(* ::Subsubsection:: *)
(*Parse String*)


(* ::Subsubsubsection::Plain:: *)
(*Convert TEX string into parse-able form*)


(* ::Input::Initialization::Plain:: *)
ConvertTeXExpression[Tstr_String]:=StringReplace[Convert`TeX`TeXToBoxes[Tstr]//.{FormBox[a_,b_]:>a,StyleBox[a_,b_]:>a,RowBox[{str__String}]:>StringJoin[str],SubscriptBox[symb_String,sub_String]:>"\!\(\*SubscriptBox[\("<>symb<>"\),\("<>sub<>"\)]\)",SuperscriptBox[symb_String,super_String]:>"\!\(\*SuperscriptBox[\("<>symb<>"\),\("<>super<>"\)]\)",SubsuperscriptBox[symb_String,sub_String,super_String]:>"\!\(\*SubsuperscriptBox[\("<>symb<>"\),\("<>sub<>"\),\("<>super<>"\)]\)"},{" "->"\\ ",","->", "}]


(* ::Subsubsubsection::Plain:: *)
(*Determine symbols' order*)


(* ::Input::Initialization::Plain:: *)
SymbolOrder[str_String,position___]:=Module[{cl=Characters[StringReplace[StringDelete[str,"\\("|"\\)"],{"\\\\ \\\\ "->"\[Wolf]","\[NonBreakingSpace]\[NonBreakingSpace]"->"\[Wolf]"," "->"","\[NonBreakingSpace]"->""}]]},{MapIndexed[If[#=!="\[Wolf]",#2[[1]]->{#,position},Nothing]&,DeleteCases[cl,"("|")"|"["|"]"]],Thread[(#-Range[0,Length@#-1])->Thread@{cl[[#]],position}]&@Position[cl,"("|")"|"["|"]"][[;;,1]]}]


(* ::Subsubsubsection::Plain:: *)
(*Construct tensor Association*)


(* ::Input::Initialization::Plain:: *)
ProcTensor::usage="ProcTensor[{symb_,sub_,super_}] process the input string and convert it to properties of a tensor.";
ProcTensor::index="Improper index found when processing matrix `1`.";


(* ::Input::Initialization::Plain:: *)
ProcTensor[{symb_,sub_,super_}]:=Module[{all={SymbolOrder[sub,-1],SymbolOrder[super,1]},index},
index=SortBy[Catenate@all[[;;,1]],First];
If[index[[;;,1]]=!=Range@Length@index,Message[ProcTensor::index,ToString@symb];Abort[]];
<|"Symbol"->symb,"IndexName"->index[[;;,2,1]],"Dimensions"->Length@index,"IndexPosition"->index[[;;,2,2]],"SymmetryMarker"-><|-1->#1,1->#2|>&@@(Map[{#[[1]],#[[2,1]]}&,all[[;;,2]],{2}])|>]


(* ::Subsubsubsection::Plain:: *)
(*String patterns for parsing tensors*)


(* ::Input::Initialization::Plain:: *)
SetAttributes[TensorStringReplaceRule,HoldAll];


(* ::Input::Initialization::Plain:: *)
TensorStringReplaceRule[operation_]:=
Module[{pattlist={"\\*SubsuperscriptBox[\\("~~Shortest[symb__]~~"\\), \\("~~Shortest[sub__]~~"\\), \\("~~Shortest[super__]~~"\\)]",
"\\*SubscriptBox[\\("~~Shortest[symb__]~~"\\), \\("~~Shortest[sub__]~~"\\)]",
"\\*SuperscriptBox[\\("~~Shortest[symb__]~~"\\), \\("~~Shortest[super__]~~"\\)]"
}},
{"\\!\\("~~pattlist[[1]]~~"\\)":>operation[{symb,sub,super}],
pattlist[[1]]:>operation[{symb,sub,super}],
"\\!\\("~~pattlist[[2]]~~"\\)":>operation[{symb,sub,""}],
pattlist[[2]]:>operation[{symb,sub,""}],
"\\!\\("~~pattlist[[3]]~~"\\)":>operation[{symb,"",super}],
pattlist[[3]]:>operation[{symb,"",super}]
}]


(* ::Subsubsubsection::Plain:: *)
(*Parse tensor string*)


(* ::Text:: *)
(*You can write like \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(A\), \(\(\[Nu]\)\(]\)\)]\), but you should never write like \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]\(( *)
(*\*SubscriptBox[\(A\), \(\(\[Nu]\)\(]\)\)] + *)
(*\*SubscriptBox[\(B\), \(\(\[Nu]\)\(]\)\)])\)\) or \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]\(( *)
(*\*SubscriptBox[\(A\), \(\[Nu]\)] + *)
(*\*SubscriptBox[\(B\), \(\[Nu]\)])\)\) Subscript[C, \[Lambda]]] because this might cause confusion and can be detrimental to performance.*)
(*Please manually expand these expressions to \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(A\), \(\(\[Nu]\)\(]\)\)]\)+\!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(B\), \(\(\[Nu]\)\(]\)\)]\) and \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(A\), \(\[Nu]\)]\) Subscript[C, \[Lambda]]]+\!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(B\), \(\[Nu]\)]\) Subscript[C, \[Lambda]]] or evaluate Subscript[A, \[Nu]]+Subscript[B, \[Nu]] first using my code and then do \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(Q\), \(\(\[Nu]\)\(]\)\)]\) or \!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SubscriptBox[\(Q\), \(\[Nu]\)]\) Subscript[C, \[Lambda]]].*)
(*\!\( *)
(*\*SubscriptBox[\(\[PartialD]\), \(\([\)\(\[Mu]\)\)]*)
(*\*SuperscriptBox[\(T\), \(\(\[Nu]\)\(]\)\)]\) is not allowed as well, and \!\( *)
(*\*SubsuperscriptBox[\(T\), \(\(\ \ \)\((\[Sigma]\)\), \((\[Rho]\)] *)
(*\*SubsuperscriptBox[\(T\), \(\(\ \ \)\(\[Nu]\)\()\)\), \(\(\[Mu]\)\()\)\)]\) will make \[Rho],\[Mu] symmetric and \[Sigma],\[Nu] symmetric.*)
(**)
(*Please always wrap a parentheses around Subscript[\[PartialD], \[Mu]] or Subscript[\[Del], \[Mu]] for safety, because Mathematica assumes that \!\( *)
(*\*SubscriptBox[\(\[Del]\), \(\[Mu]\)]\(+*)
(*\*SubscriptBox[\(A\), \(\[Nu]\)]\)\) means \!\( *)
(*\*SubscriptBox[\(\[Del]\), \(\[Mu]\)]\((\(+*)
(*\*SubscriptBox[\(A\), \(\[Nu]\)]\))\)\) when processing Boxes...*)


(* ::Input::Initialization::Plain:: *)
ParseTensor[str_String]:=With[{strn=If[StringFreeQ[str,"scriptBox"],ConvertTeXExpression[str],str]},StringCases[ToString@InputForm@Identity@strn,TensorStringReplaceRule[ProcTensor]]]


(* ::Subsubsubsection::Plain:: *)
(*Parse tensor expression*)


(* ::Input::Initialization::Plain:: *)
ParseTensorExpression[str_String]:=Module[{strn=If[StringFreeQ[str,"scriptBox"],ConvertTeXExpression[str],str],us="$tensorSymb",i=1,temp,symbs},Internal`InheritedBlock[{Times,CircleDot},
Unprotect@Times;
ClearAttributes[Times,Orderless];

temp=Reap[ToExpression@ToExpression@StringReplace[StringReplace[ToString@InputForm@Identity@strn,TensorStringReplaceRule[(Sow[#];us<>"["<>ToString[i++]<>"]")&]],"\\!\\(TraditionalForm\\`"~~Shortest[cont__]~~"\\)":>cont]/.Times->CircleDot];

symbs=ProcTensor/@Flatten[temp[[2]],1];
((temp[[1]]/.$tensorSymb[i_]:>$tensorSymb[symbs[[i]]])/.Times->CircleDot)/.CircleDot[s_]:>s
]]


(* ::Subsection:: *)
(*Global Variables*)


(* ::Text:: *)
(*My gradient which consider everything other than $vars as variables.*)


(* ::Input::Initialization::Plain:: *)
myGrad[symb_,vars_.]/;(Head[symb]=!=Symbol||Head[TensorDimensions[symb]]===TensorDimensions||TensorDimensions[symb]=={}):=Dt[symb,#,Constants->Join[DeleteCases[$vars,#],$constants]]&/@$vars
myGrad[symb_]:=myGrad[symb,$vars]


(* ::Text:: *)
(*Tensor dataset (actually a multi-layer association would be better for performance, but that's just ugly...).*)
(**)
(*data should be in the form of:*)
(*<|"Symbol"->"g","Dimension"->2,"IndexPosition"->{-1,-1},"Value"->$gd|>*)


(* ::Input::Initialization::Plain:: *)
$TensorDefinitions=Dataset[{<|"Symbol"->"g","Dimensions"->2,"IndexPosition"->{-1,-1},"Value"->DiagonalMatrix@{1,1,1,1}|>}];


(* ::Input::Initialization::Plain:: *)
AddTensorToDataset[ten_Association]:=(If[!ContainsAll[Keys[ten],{"IndexPosition","Symbol","Value"}],Message[AddTensorToDataset::keys];Abort[]];
If[Length@$vars!=Length@ten["Value"],Message[AddTensorToDataset::nmatchdim,Length@ten["Value"],Length@$vars];Abort[]];
If[(Length[Dimensions@ten["Value"]]<Length@ten["IndexPosition"])||(!(Equal@@(Dimensions[ten["Value"]][[;;Length@ten["IndexPosition"]]]))),Message[AddTensorToDataset::nmatchind,Length@ten["Value"],Length@ten["IndexPosition"]];Abort[]];
$TensorDefinitions=DeleteCases[$TensorDefinitions,_?(#Symbol===ten["Symbol"]&&Length[#IndexPosition]===Length[ten["IndexPosition"]]&)];AppendTo[$TensorDefinitions,Insert[ten[[{"Symbol","IndexPosition","Value"}]],"Dimensions"->Length@ten["IndexPosition"],2]];)


AddTensorToDataset[ten_Association,val_?ArrayQ]:=Block[{ten1=ten},AddTensorToDataset[ten1["Value"]=val;ten1]];


AddTensorToDataset[ten_String,val_?ArrayQ]:=AddTensorToDataset[ParseTensor[ten][[1]],val];


AddTensorToDataset[ten_$tensorSymb,others___]:=AddTensorToDataset[ten[[1]],others];


AddTensorToDataset[ten_String,ten2_Association]:=AddTensorToDataset[ReplacePart[ten2,"Symbol"->ten]];


AddTensorToDataset[ten_String,ten2_$tensorSymb]:=AddTensorToDataset[ReplacePart[ten2[[1]],"Symbol"->ten]]


(* ::Text:: *)
(*Directly add to Dataset without overriding other relevant terms.*)


(* ::Input::Initialization::Plain:: *)
DirectAddTensorToDataset[ten_Association]:=If[!ContainsAll[Keys[ten],{"IndexPosition","Symbol","Value"}],Message[AddTensorToDataset::keys],
$TensorDefinitions=DeleteCases[$TensorDefinitions,_?(#Symbol===ten["Symbol"]&&#IndexPosition===ten["IndexPosition"]&)];AppendTo[$TensorDefinitions,Insert[ten[[{"Symbol","IndexPosition","Value"}]],"Dimensions"->Length@ten["IndexPosition"],2]];]


(* ::Text:: *)
(*gd is Subscript[g, \[Mu]\[Nu]], gu is g^\[Mu]\[Nu].*)


(* ::Input::Initialization::Plain:: *)
$constants={};


(* ::Input::Initialization::Plain:: *)
SetVars[vars_]:=If[Length@vars!=Length@$vars,
$TensorDefinitions=Dataset[{<|"Symbol"->"g","Dimensions"->2,"IndexPosition"->{-1,-1},"Value"->DiagonalMatrix@ConstantArray[1,Length@vars]|>}];
$vars=vars;
SetMetric[DiagonalMatrix@ConstantArray[1,Length@vars]],
$vars=vars];

SetMetric[g_]:=(
If[(Length[#]!=2||#[[1]]!=#[[2]])&@TensorDimensions[g],Message[SetMetric::dim]];
$gd=g;
$gu=Inverse[$gd];
$\[CapitalGamma]=TensorContract[Inverse[$gd]\[TensorProduct]With[{p=myGrad[$gd]},-p+TensorTranspose[p,{3,1,2}]+TensorTranspose[p,{2,3,1}]],{{2,3}}]/2;
$dim=Length@$gd;

AddTensorToDataset[<|"Symbol"->"g","IndexPosition"->{-1,-1},"Value"->$gd|>];
DirectAddTensorToDataset[<|"Symbol"->"g","IndexPosition"->{1,1},"Value"->$gu|>];
AddTensorToDataset[<|"Symbol"->"\[CapitalGamma]","IndexPosition"->{1,-1,-1},"Value"->$\[CapitalGamma]|>];
)


(* ::Input::Initialization::Plain:: *)
SetVars[{t,x,y,z}];
SetMetric[SparseArray@DiagonalMatrix[{-1,1,1,1}]];


(* ::Subsection:: *)
(*Process a single Tensor Expression*)


(* ::Subsubsection:: *)
(*Move Tensor Index*)


myTensorTranspose[ten_,a_<->b_]:=If[a==b,ten,TensorTranspose[ten,Cycles[{{a,b}}]]]


(* ::Input::Initialization::Plain:: *)
AdjustIndex[mat_,pos_List]:=Fold[myTensorTranspose[If[#2[[2]]==1,$gu,$gd].myTensorTranspose[#,1<->#2[[1]]],1<->#2[[1]]]&,mat,Select[pos,#[[2]]==1||#[[2]]==-1&]]


(* ::Text:: *)
(*Move indexes up and down.*)


(* ::Input::Initialization::Plain:: *)
ConvertTensorIndex[s_Association]:=Module[{stored=Normal[First@MinimalBy[Select[$TensorDefinitions,#Symbol==s["Symbol"]&&#Dimensions==s["Dimensions"]&],Abs[#IndexPosition-s["IndexPosition"]]&]],temps=s,temp,diff},
If[Head[stored]=!=Association,Message[ConvertTensorIndex::nstored,s["Symbol"]];Abort[]];

(*Raise and drop index*)
diff=(s["IndexPosition"]-stored["IndexPosition"])/2;
temp=stored["Value"];
temp=AdjustIndex[temp,Thread[{Range@Length@#,#}]&@diff];
AppendTo[temps,"Value"->temp];
(*DirectAddTensorToDataset[temps];*)
ConvertTensorIndex[temps]
]


(* ::Text:: *)
(*Summation first, symmetrize later. If you want to change the order, please use metric explicitly to calculate sum, e.g. \!\( *)
(*\*SubsuperscriptBox[\(g\), \(\(\ \ \)\(\[Lambda]\)\), \(\[Rho]\)] *)
(*\*SubsuperscriptBox[\(\[CapitalGamma]\), \(\(\ \ \)\((\[Alpha]\[Rho]\[Gamma])\)\), \(\[Lambda]\)]\).*)


(* ::Input::Initialization::Plain:: *)
ConvertTensorIndex[s_Association]/;KeyExistsQ[s,"Value"]:=
Module[{temps=s,odims=Length@s["IndexPosition"],contractpos,parentpos,stack,parents={},i,j,tempfunc},

(*Summation Rules*)
contractpos=Select[GatherBy[Thread[{#,Range@Length@#}],First],Length@#>1&][[;;,;;,2]]&@s["IndexName"];
If[Length@#!=2,Message[ConvertTensorIndex::invindex,s["Symbol"],#];Abort[],If[(Times@@(s["IndexPosition"][[#]]))!=-1,Message[ConvertTensorIndex::invindexpos,s["Symbol"],#];Abort[]]]&/@contractpos;
temps["Value"]=TensorContract[temps["Value"],contractpos];
temps["Dimensions"]-=2 Length@contractpos;
(temps[#]=Delete[temps[#],List/@Flatten@contractpos])&/@{"IndexName","IndexPosition"};
If[temps["Dimensions"]==0,Return[<|"Symbol"->temps["Symbol"],"IndexName"->{},"Dimensions"->0,"IndexPosition"->{},"SymmetryMarker"->{},"Value"->temps["Value"]|>]];

(*Symmetrize*)
parentpos=Accumulate@ReplacePart[ConstantArray[1,odims+1],(#+1)->0&/@Flatten@Sort[contractpos]];
temps["SymmetryMarker"]=Map[{parentpos[[#[[1]]]],#[[2]]}&,temps["SymmetryMarker"],{2}];
(*Use Stack to process parentheses*)

tempfunc=(temps["Value"]=SparseArray@Symmetrize[temps["Value"],#[Select[Position[temps["IndexPosition"],i][[;;,1]],stack[[-1,1]]<=#<j[[1]]&]]];stack=Most@stack)&;

Do[
stack={};
Do[
If[Length@stack>0,
Switch[{stack[[-1,2]],j[[2]]},
{"(",")"},tempfunc[Symmetric],
{"[","]"},tempfunc[Antisymmetric],
{"(","]"}|{"[",")"},Message[ConvertTensorIndex::invparent,s["Symbol"]];Abort[],
_,AppendTo[stack,j]
],AppendTo[stack,j]
],
{j,temps["SymmetryMarker"][i]}];
temps["SymmetryMarker"][i]=stack,
{i,{1,-1}}];

temps
]


(* ::Text:: *)
(*Process Derivatives.*)


(* ::Input::Initialization::Plain:: *)
ConvertTensorIndex[s_Association]/;(s["Symbol"]==="\[PartialD]"||s["Symbol"]=="\[Del]"):=If[s["Dimensions"]=!=1,Message[ConvertTensorIndex::dtindex,s];Abort[],s]


(* ::Subsection:: *)
(*Process Addition, Multiplication and Derivatives of Tensor Expressions*)


(* ::Input::Initialization::Plain:: *)
RandomT$:=ToString@Unique["T$"]


(* ::Text:: *)
(*Only * + -  can operate on Einstein tensors.*)


(* ::Subsubsection:: *)
(*Irrelevant expressions*)


(* ::Input::Initialization::Plain:: *)
EvaluateEinsteinSummation[expr:Except[_String]]/;FreeQ[expr,$tensorSymb]:=expr


(* ::Subsubsection:: *)
(*Simple tensor*)


(* ::Input::Initialization::Plain:: *)
EvaluateEinsteinSummation[expr_$tensorSymb]:=$tensorSymb@ConvertTensorIndex[expr[[1]]]


(* ::Subsubsection:: *)
(*Addition*)


(* ::Subsubsubsection::Plain:: *)
(*Calculate free indexes' combination*)


(* ::Input::Initialization::Plain:: *)
(*Others*)
FreeIndexes[expr_]/;FreeQ[expr,$tensorSymb]:={}
(*Tensor*)
FreeIndexes[expr_$tensorSymb]:=Thread[{expr["IndexName"],expr["IndexPosition"]}]
(*Summation*)
FreeIndexes[expr_Plus]:=FreeIndexes[expr[[1]]];
(*Multiplication and Application*)
FreeIndexes[expr_CircleDot]:=Module[{comb=GatherBy[Catenate[FreeIndexes/@(List@@expr)],First]},
If[Count[comb,x_/;(Length[x]>2||(Length[x]==2&&Times@@x[[;;,2]]!=-1))]!=0,Message[FreeIndexes::invindex,expr];Abort[],Select[comb,Length[#]==1&][[;;,1]]]
]


(* ::Subsubsubsection::Plain:: *)
(*Calculate free parentheses*)


(* ::Input::Initialization::Plain:: *)
FreeParentheses[expr_CircleDot]:=Module[{stack={}},
Do[
If[Length@stack>0,
Switch[{stack[[-1]],j},
{"(",")"}|{"[","]"},stack=Most@stack,
{"(","]"}|{"[",")"},Message[FreeParentheses::invparent,expr];Abort[],
_,AppendTo[stack,j]
],AppendTo[stack,j]
],
{j,#}];
stack]&/@Merge[FreeParentheses/@(List@@expr),Catenate]

FreeParentheses[expr_$tensorSymb]:=expr[[1,"SymmetryMarker",;;,;;,2]]
FreeParentheses[expr___]:=<|-1->{},1->{}|>


(* ::Subsubsubsection::Plain:: *)
(*Main*)


(* ::Input::Initialization::Plain:: *)
EvaluateEinsteinSummation[expr_Plus]/;(!FreeQ[expr,$tensorSymb]):=
Module[{cont=EvaluateEinsteinSummation/@(List@@expr),cat,targetorder},

(*Check Validity*)
(*Same index and index's height, no need for same position*)
If[!(SameQ@@(Sort@*FreeIndexes/@cont)),Message[EvaluateEinsteinSummation::indexmismatch,expr];Abort[]];
(*No free parentheses*)
If[!(And@@(({{},{}}===Values@FreeParentheses@#)&/@cont)),Message[EvaluateEinsteinSummation::parentinsum,expr];Abort[]];

(*Categorize and Sum up*)
cat=Flatten[#,1]&/@Reap[
Do[Switch[i,
_CircleDot,Sow[i,1],
$tensorSymb[s_Association/;(s["Symbol"]==="\[PartialD]"||s["Symbol"]=="\[Del]")],Sow[i,1],
_$tensorSymb,Sow[i,2],
_,Sow[i,1]
],{i,cont}],
{1,2}][[2]];

Total[cat[[1]]]+Switch[Length@cat[[2]],
0,0,
1,cat[[2,1]],
_,targetorder=Ordering@cat[[2,1,1,"IndexName"]];
ReplacePart[cat[[2,1]],{{1,"Symbol"}->RandomT$,{1,"Value"}->Total[TensorTranspose[#["Value"],targetorder[[Ordering@Ordering@#["IndexName"]]]]&/@cat[[2,;;,1]]]}]
]
]


(* ::Subsubsection:: *)
(*Multiplication*)


(* ::Subsubsubsection::Plain:: *)
(*Tensor operation*)


(* ::Text:: *)
(*Something that do TensorC=TensorA TensorB where TensorB is a value tensor and return a value tensor Tensor C.*)


(* ::Text:: *)
(*Tensor.Tensor*)


(* ::Input::Initialization::Plain:: *)
TensorOperate[TenA_$tensorSymb,TenB_$tensorSymb]:=Module[{s=Merge[{TenA,TenB}[[;;,1]],Identity],dimA=TenA["Dimensions"]},$tensorSymb@ConvertTensorIndex[<|"Symbol"->RandomT$,"IndexName"->Catenate@s["IndexName"],"Dimensions"->Total@s["Dimensions"],"IndexPosition"->Catenate@s["IndexPosition"],"SymmetryMarker"->(Join[#[[1]],{#[[1]]+dimA,#[[2]]}&/@#[[2]]]&/@Merge[s["SymmetryMarker"],Identity]),"Value"->(TensorProduct@@s["Value"])|>]]


(* ::Text:: *)
(*\[PartialD] Tensor*)


(* ::Input::Initialization::Plain:: *)
TensorOperate[TenA_$tensorSymb,TenB_$tensorSymb]/;(TenA["Symbol"]==="\[PartialD]"):=Module[{s=Merge[{TenA,TenB}[[;;,1]],Identity],tempval},
(*value for \!\(
\*SubscriptBox[\(\[PartialD]\), \(\[Mu]\)]T\)*)
tempval=myGrad[TenB["Value"]];

(*contract/symmetrize etc.*)
$tensorSymb@ConvertTensorIndex[<|"Symbol"->RandomT$,"IndexName"->Catenate@s["IndexName"],"Dimensions"->Total@s["Dimensions"],"IndexPosition"->Catenate@s["IndexPosition"],"SymmetryMarker"->(Join[#[[1]],{#[[1]]+1,#[[2]]}&/@#[[2]]]&/@Merge[s["SymmetryMarker"],Identity]),"Value"->If[TenA[[1,"IndexPosition",1]]==1,$gu.tempval,tempval]|>]]


(* ::Text:: *)
(*\[Del] Tensor*)


(* ::Input::Initialization::Plain:: *)
TensorOperate[TenA_$tensorSymb,TenB_$tensorSymb]/;(TenA["Symbol"]==="\[Del]"):=
Module[{s=Merge[{TenA,TenB}[[;;,1]],Identity],tempindex1=ToString@Unique["Var$"],tempindex2=ToString@Unique["Var$"],tempsymark=<|-1->{},1->{}|>,indname,partialterm,gammaterm,res1},

indname=Catenate@s["IndexName"];

(*\[PartialD]T*)
partialterm=TensorOperate[$tensorSymb[<|"Symbol"->"\[PartialD]","IndexName"->{tempindex1},"Dimensions"->1,"IndexPosition"->{-1},"SymmetryMarker"->tempsymark|>],ReplacePart[TenB,{1,"SymmetryMarker"}->tempsymark]];

(*\[PlusMinus]\[CapitalGamma]T*)
gammaterm=With[{indpos=TenB[[1,"IndexPosition",#]]},
TensorOperate[$tensorSymb[<|"Symbol"->"\[CapitalGamma]","IndexName"->If[indpos==1,{TenB[[1,"IndexName",#]],tempindex1,tempindex2},{tempindex2,tempindex1,TenB[[1,"IndexName",#]]}],"Dimensions"->3,"IndexPosition"->{1,-1,-1},"SymmetryMarker"->tempsymark,"Value"->(indpos*$\[CapitalGamma])|>],ReplacePart[TenB,{{1,"SymmetryMarker"}->tempsymark,{1,"IndexName",#}->tempindex2}]]
]&/@Range[TenB["Dimensions"]];

(*Summation & change index order*)
res1=TensorTranspose[#["Value"],Ordering[ReplacePart[indname,1->tempindex1]][[Ordering@Ordering@#["IndexName"]]]]&@EvaluateEinsteinSummation[Total@Prepend[gammaterm,partialterm]][[1]];

(*contract/symmetrize etc.*)
$tensorSymb@ConvertTensorIndex[<|"Symbol"->RandomT$,"IndexName"->indname,"Dimensions"->Total@s["Dimensions"],"IndexPosition"->Catenate@s["IndexPosition"],"SymmetryMarker"->(Join[#[[1]],{#[[1]]+1,#[[2]]}&/@#[[2]]]&/@Merge[s["SymmetryMarker"],Identity]),"Value"->If[TenA[[1,"IndexPosition",1]]==1,$gu.res1,res1]|>]
]


(* ::Text:: *)
(*\[PartialD] or \[Del] Scalar*)


(* ::Input::Initialization::Plain:: *)
TensorOperate[TenA_$tensorSymb,TenB_]/;(TenA["Symbol"]==="\[PartialD]"||TenA["Symbol"]=="\[Del]"):=$tensorSymb@ReplacePart[Append[TenA[[1]],"Value"->myGrad[TenB,$vars]],"Symbol"->RandomT$]


(* ::Text:: *)
(*Tensor.Scalar or Scalar.Tensor*)


(* ::Input::Initialization::Plain:: *)
TensorOperate[TenA_$tensorSymb,TenB_]:=ReplacePart[TenA,{{1,"Symbol"}->RandomT$,{1,"Value"}->(TenA["Value"]*TenB)}]
TensorOperate[TenA_,TenB_$tensorSymb]:=ReplacePart[TenB,{{1,"Symbol"}->RandomT$,{1,"Value"}->(TenA*TenB["Value"])}]


(* ::Text:: *)
(*Scalar.Scalar*)


(* ::Input::Initialization::Plain:: *)
TensorOperate[TenA_,TenB_]:=(Echo[{TenA,TenB}];TenA*TenB)


(* ::Subsubsubsection::Plain:: *)
(*Main*)


(* ::Input::Initialization::Plain:: *)
EvaluateEinsteinSummation[expr_CircleDot]/;(!FreeQ[expr,$tensorSymb]):=
Module[{terms,mosterms,lasterms,termres},
(*Check Validity*)
FreeIndexes@expr;
FreeParentheses@expr;

(*Divide expression into terms which will calculate to a value matrix*)
terms=MapAt[Most,Split[Append[EvaluateEinsteinSummation/@(List@@expr),$tensorSymb[<|"Symbol"->"\[PartialD]"|>]],!(FreeQ[#1,$tensorSymb[s_Association/;(s["Symbol"]==="\[PartialD]"||s["Symbol"]=="\[Del]")]])&],-1];
If[Length@terms==1,Return[1]];
(*those which can be calculated*)
mosterms=Most@terms;
(*those left at the tail of the expression, which cannot be calculated*)
lasterms=Last@terms;

(*Calculate each term's result, which must be a value tensor*)
termres=
If[Length[#]==1,#[[1]],
Module[{expanded=Distribute[CircleDot@@#]},
If[Head@expanded===Plus,
EvaluateEinsteinSummation[
$tensorSymb@Fold[TensorOperate[#2,#1]&,
Reverse@Internal`InheritedBlock[{CircleDot},SetAttributes[CircleDot,Flat];#]
]&/@expanded],
Fold[TensorOperate[#2,#1]&,
Reverse@Internal`InheritedBlock[{CircleDot},SetAttributes[CircleDot,Flat];expanded]]
]]
]&/@mosterms;

(*merge each term's result. Note that all of them are value tensors*)
If[Length@lasterms==0,#,CircleDot@@Prepend[lasterms,#]]&@Fold[TensorOperate[#2,#1]&,Reverse@termres]
]


(* ::Subsection:: *)
(*Complete Evaluation From String*)


(* ::Input::Initialization::Plain:: *)
EvaluateEinsteinSummation[s_String]/;True:=EvaluateEinsteinSummation@ParseTensorExpression@s


(* ::Subsection:: *)
(*End of Package*)


End[];
EndPackage[];


Print@Column[{Button["Einstein Summation Package Guide \[RightSkeleton]", Inherited, Appearance -> Automatic,BaseStyle -> "Link", 
   ButtonData -> "paclet:EinsteinSummation/ReferencePages/Guides/TensorExpressionswithEinsteinSummation", Evaluator -> Automatic, 
   Method -> "Preemptive"], Button["Einstein Summation Tutorial \[RightSkeleton]", Inherited, Appearance -> Automatic, 
   BaseStyle -> "Link", ButtonData -> 
    "paclet:EinsteinSummation/ReferencePages/Tutorials/EinsteinSummation", Evaluator -> Automatic, 
   Method -> "Preemptive"]}, ItemSize -> {Automatic, Automatic}, Spacings -> {Automatic, 0}]
