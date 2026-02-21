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

## Source documents

* OMG, [Structured Assurance Case Metamodel (SACM)](https://www.omg.org/spec/SACM) version 2.3.
* [Mermaid Flowchart syntax](https://mermaid.ai/open-source/syntax/flowchart.html)
* GitHub, [Creating Diagrams (Creating Mermaid Diagrams)](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#creating-mermaid-diagrams)
