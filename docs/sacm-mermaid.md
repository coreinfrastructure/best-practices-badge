# SACM in mermaid

This document explains our approach to implementing the
[Structured Assurance Case Metamodel (SACM)](https://www.omg.org/spec/SACM)
graphical notation in mermaid (as best we can on GitHub).

## Introduction

The Object Management Group (OMG) has defined
[Structured Assurance Case Metamodel (SACM)](https://www.omg.org/spec/SACM),
version 2.3 at time of writing.
SACM "defines a metamodel for representing structured assurance cases. An
Assurance Case is a set of auditable claims, arguments, and evidence
created to support the claim that a defined system/service will satisfy
the particular requirements [and] facilitates information exchange
between various system stakeholder[s]...".

However, sometimes you don't need a metamodel for an assurance case;
you simply need to provide a simple editable assurance case for others
to read and edit. In our case, we also don't need to exchange between tools.
It's more important that the information be easily edited and
displayed with open source software tools.

Thankfully, newer versions of SACM also include a recommended graphical
notation defined in Annex C
("Concrete Syntax (Graphical Notations) for the Argumentation Metamodel").

In the best practices badge project we have traditionally used diagrams
edited with LibreOffice, connected together and provided detail in
markdown format. However, while this is flexible and LibreOffice is
quite capable, this approach creates significant effort
when editing the graphics, and it doesn't integrate well with version control.

More recent markdown implementations, including GitHub's, include
support for mermaid diagrams (such as mermaid flowcharts).
Mermaid, especially its older subset,
cannot exactly implement the SACM graphical notation.
Indeed, Mermaid is *much* less capable, graphically, than what LibreOffice
can generate, and it doesn't let you "place" symbols.

Nevertheless, the ability to *easily* integrate diagrams into the
markdown format is alluring, and SACM's graphical notation is on the
whole nice and well-designed.
A mermaid representation
doesn't need to be *exactly* like the spec - it simply needs to be adequate
to be clear to readers.

## Mermaid

Mermaid's syntax is described in
[its reference](https://mermaid.ai/open-source/intro/syntax-reference.html).

GitHub's markdown implementation is even more limited.
For example, through testing
we've determined that it currently doesn't
support expanded node shapes in Mermaid flowcharts (available in v11.3.0+).
For our purposes we must stick to what GitHub supports.

## Mapping

For each graphical element identified in annex C, here's how we
intend to represent them in mermaid:

## Justification for mapping

The SACM Annex C graphical constructs are:                                    

* Node types (shapes): ArgumentPackage, ArgumentPackageInterface,               
  ArgumentPackageBinding, ArtifactReference (dog-eared document), and Claim with
  7 variants (asserted=plain rect, assumed=bracket feet, needsSupport=dots
  below, axiomatic=double bottom line, defeated=crossed-out, asCited=corner
  notches, abstract=dashed rect), plus ArgumentReasoning (open-left bracket
  shape).
* Edge types: AssertedInference, AssertedEvidence, AssertedContext,
  AssertedArtifactSupport, AssertedArtifactContext — each with the same 7
  assertion-state variants. The key visual distinction: these are reified
  relationships — a dot in the middle with a plain line to source and a
  decorated arrow to target. The decoration on the target end encodes assertion
  state (filled arrowhead=asserted, open arrowhead=counter, filled
  square=context, X=defeated, three dots=needsSupport, etc.).

Among the mermaid diagram types, "flowchart TD" is the only viable choice.
It supports many shapes, edge styles, edge labels, and subgraphs.

Among the alternatives:

* classDiagram - its only shapes are UML class boxes, its only edges
  are UML relation types
* mindmap - only a few fixed shapes, parent-child edges only
* stateDiagram-v2 - only state box shapes, only edge transitions
* erDiagram - only entity box shapes, with ER relation styles

The three decisive reasons flowchart wins are:

1. Shape variety: It has the most node shapes GitHub supports — rectangle [],
parallelogram [//], circle (()), rounded rectangle (), asymmetric >] — enough
to meaningfully distinguish Claim, ArgumentReasoning, and ArtifactReference
from each other.
2. Edge variety: --> (solid), -.-> (dashed), ==> (thick), --o (circle
endpoint), --x (X endpoint), plus labeled edges — enough to encode assertion
states and distinguish inference from context from counter relationships.
3. Subgraphs: subgraph blocks naturally represent ArgumentPackage grouping.

One challenge is that SACM's relationships are reified, in particular,
the dot in the middle is a first-class element.
Mermaid can't express that directly.
The practical workaround is to represent the relationship instance
as a tiny node (e.g., a circle) with two edges or to drop the
reification and use a direct labeled edge. The latter loses fidelity but stays
readable.

There is an exception: classDiagram is worth considering only for
package-structure diagrams. Its built-in lollipop interface notation happens
to visually echo the ArgumentPackageInterface lollipop symbol (C.2), and its
compartmented class boxes vaguely resemble the ArgumentPackage shape. But for
actual argument diagrams with Claims, reasoning, and evidence, classDiagram is
a poor fit.

## Source documents

* OMG, [Structured Assurance Case Metamodel (SACM)](https://www.omg.org/spec/SACM) version 2.3.
* [Mermaid Flowchart syntax](https://mermaid.ai/open-source/syntax/flowchart.html)
* GitHub, [Creating Diagrams (Creating Mermaid Diagrams)](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#creating-mermaid-diagrams)
