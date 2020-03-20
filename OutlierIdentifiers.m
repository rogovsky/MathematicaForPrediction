(*
    Implementation of one dimensional outlier identifying algorithms in Mathematica
    Copyright (C) 2013  Anton Antonov

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Written by Anton Antonov,
    antononcube @ gmail . com,
    Windermere, Florida, USA.
*)

(*
    Mathematica is (C) Copyright 1988-2019 Wolfram Research, Inc.

    Protected by copyright law and international treaties.

    Unauthorized reproduction or distribution subject to severe civil
    and criminal penalties.

    Mathematica is a registered trademark of Wolfram Research, Inc.
*)

(* Version 1.0 *)
(*
   # In brief

   This package contains definitions for detection and visualization of outliers in a list of numbers.

   The purpose of the outlier detection algorithms is to find those elements in a list of numbers
   that have values significantly higher or lower than the rest of the values.

   Taking a certain number of elements with the highest values is not the same as an outlier detection,
   but it can be used as a replacement.

   # Usage

   Let us consider the following set of 50 numbers:

      SeedRandom[343]
      pnts = RandomVariate[GammaDistribution[5, 1], 50]

   Here we find the outliers using the HampelIdentifierParameters function:

      OutlierIdentify[pnts, HampelIdentifierParameters]

   Here we find the top outliers only:

      OutlierIdentify[pnts, TopOutliers @* HampelIdentifierParameters]

      (* {7.68192, 8.47235, <<9>>, 6.57855, 6.96975} *)

   Here we find the top outliers positions:

      OutlierPosition[pnts, TopOutliers @* HampelIdentifierParameters]

      (* {3, 4, 6, 8, 13, 26, 34, 37, 38, 41, 42, 47, 48} *)

   Here is the application of all outlier parameter finding functions in this package:

      Through[ {HampelIdentifierParameters, SPLUSQuartileIdentifierParameters, QuartileIdentifierParameters}[pnts] ]

      (* {{2.17496, 6.54877}, {-2.09104, 11.7803}, {0.572922, 7.50859}} *)

   # References

   [1] Ronald K. Pearson, “Mining Imperfect Data: Dealing with Contamination and Incomplete Records”, 2005, SIAM.

*)


BeginPackage["OutlierIdentifiers`"];

HampelIdentifierParameters::usage = "Returns Hampel outlier identifier parameters {L,U} for a list of numbers.";

QuartileIdentifierParameters::usage = "Returns quartile outlier identifier parameters {L,U} for a list of numbers.";

SPLUSQuartileIdentifierParameters::usage = "Returns SPLUS quartile outlier identifier parameters {L,U} for a list of numbers.";

OutlierIdentify::usage = "OutlierIdentify[data : {_?NumberQ...} | Association[ (_ -> _?NumberQ) ..], pars] \
applies outlier identifier parameters pars to a list of numbers dataArg.";

OutlierIdentifier::usage = "Synonym of OutlierIdentify.";

OutlierIdentifyLess::usage = "OutlierIdentifyLess[ data : {_?NumberQ...} | Association[ (_ -> _?NumberQ) ..], pars] \
applies outlier identifier parameters pars to a list of numbers data and takes the outliers with smallest values.";

TopOutliers::usage = "Changes the parameters {L,U} of an outlier identifier to {-Infinity,U}.";

BottomOutliers::usage = "Changes the parameters {L,U} of an outlier identifier to {L,Infinity}.";

HampelIdentifier::usage = "Shortcut for OutlierIdentify[#, HampelIdentifierParameters]& .";

OutlierPosition::usage = "OutlierPosition[ data : {_?NumberQ...}, pars] gives the positions of the outliers \
in data using the outlier identifier parameters pars. Top and bottom outliers can be found with
TopOutliers @* pars and BottomOutliers @* pars respectively.";

ListPlotOutliers::usage = "Plots a list of numbers and its outliers using ListPlot.";

ColorPlotOutliers::usage = "ColorPlotOutliers[oid___] makes a function for coloring the outliers in list point plots.";

Begin["`Private`"];

Clear[HampelIdentifierParameters];
HampelIdentifierParameters[data : {_?NumberQ...}] :=
    Block[{x0 = Median[data], md},
      md = 1.4826 * Median[Abs[data - x0]];
      {x0 - md, x0 + md}
    ];


Clear[QuartileIdentifierParameters];
QuartileIdentifierParameters[data : {_?NumberQ...}] :=
    Block[{xL, xU, x0},
      {xL, x0, xU} = Quantile[data, {1 / 4, 1 / 2, 3 / 4}];
      {x0 - (xU - xL), x0 + (xU - xL)}
    ];


Clear[SPLUSQuartileIdentifierParameters];
SPLUSQuartileIdentifierParameters[data : {_?NumberQ...}] :=
    Block[{xL, xU},
      If[Length[data] <= 4, Return[{Min[data], Max[data]}]];
      {xL, xU} = Quantile[data, {1 / 4, 3 / 4}];
      {xL - 1.5(xU - xL), xU + 1.5(xU - xL)}
    ];


Clear[TopOutliers, BottomOutliers];
TopOutliers[{xL_, xU_}] := {-Infinity, xU};
BottomOutliers[{xL_, xU_}] := {xL, Infinity};


(***********::Section:: ***********)
(* Identifiers                    *)


Clear[OutlierIdentify, OutlierIdentifyLess];
OutlierIdentify[data : {_?NumberQ...}, outlierIdentifierParameters_ : HampelIdentifierParameters ] :=
    Block[{xL, xU},
      {xL, xU} = outlierIdentifierParameters[data];
      Select[data, # < xL || xU < #&]
    ];

OutlierIdentify[ data : Association[ (_ -> _?NumberQ) ..], outlierIdentifierParameters_ : HampelIdentifierParameters ] :=
    KeyTake[ data, OutlierPosition[data, outlierIdentifierParameters] ];

OutlierIdentifyLess[data : {_?NumberQ...} | Association[ (_ -> _?NumberQ) ..], outlierIdentifierParameters_ : HampelIdentifierParameters ] :=
    OutlierIdentify[ data, BottomOutliers @* outlierIdentifierParameters ];


Clear[OutlierIdentifier];
OutlierIdentifier = OutlierIdentify;


Clear[HampelIdentifier];
HampelIdentifier[data__] := OutlierIdentify[data, HampelIdentifierParameters];


Clear[OutlierPosition];
OutlierPosition[data : {_?NumberQ...}, outlierIdentifier_ : HampelIdentifierParameters] :=
    Block[{cls, t},
      cls = OutlierIdentify[data, outlierIdentifier];
      t = Select[Transpose[{data, Range[Length[data]]}], MemberQ[cls, #[[1]]]&];
      If[t === {}, {}, t[[All, 2]]]
    ];

OutlierPosition[data : Association[ (_ -> _?NumberQ) ... ], outlierIdentifier_ : HampelIdentifierParameters ] :=
    Block[{pos},
      pos = OutlierPosition[ Values[data], outlierIdentifier];
      If[ pos === {}, {}, Keys[data][[pos]] ]
    ];


(*********** ::Section:: ***********)
(*Plot definitions*)

Clear[ListPlotOutliers];
Options[ListPlotOutliers] = {PlotStyle -> {PointSize[0.015]}, PlotRange -> All, ImageSize -> 300};
ListPlotOutliers[ds_, outlierParameters_, optsArg___] :=
    Block[{outliers, opts = optsArg, positionedOutliers},
      If[!OptionQ[{opts}], opts = Options[ListPlotOutliers]];
      outliers = OutlierIdentify[ds, outlierParameters];
      If[outliers === {},
        ListPlot[Transpose[{Range[Length[ds]], ds}], opts],
        positionedOutliers = Select[Transpose[{Range[Length[ds]], ds}], MemberQ[outliers, #[[2]]]&];
        ListPlot[{Transpose[{Range[Length[ds]], ds}], positionedOutliers}, opts]
      ]
    ];

ClearAll[ColorPlotOutliers]
ColorPlotOutliers[] := # /. {Point[ps_] :> {Point[ps], Red, Point[ps[[OutlierPosition[ps[[All, 2]]]]]]}} &;
ColorPlotOutliers[oid_] := # /. {Point[ps_] :> {Point[ps], Red, Point[ps[[OutlierPosition[ps[[All, 2]], oid]]]]}} &;


End[];

EndPackage[];